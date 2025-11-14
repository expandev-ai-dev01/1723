/**
 * @summary
 * Adds a product to the shopping cart or updates quantity if the same
 * product with same options already exists. Creates cart if it doesn't exist.
 * Validates product availability, flavor and size selection, and quantity limits.
 *
 * @procedure spCartItemAdd
 * @schema functional
 * @type stored-procedure
 *
 * @endpoints
 * - POST /api/v1/internal/cart/item
 *
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy
 *
 * @param {INT} idUser
 *   - Required: Yes
 *   - Description: User identifier
 *
 * @param {INT} idProduct
 *   - Required: Yes
 *   - Description: Product identifier
 *
 * @param {INT} idFlavor
 *   - Required: Yes
 *   - Description: Selected flavor identifier
 *
 * @param {INT} idSize
 *   - Required: Yes
 *   - Description: Selected size identifier
 *
 * @param {INT} quantity
 *   - Required: Yes
 *   - Description: Quantity to add (1-10)
 *
 * @param {NVARCHAR(200)} observations
 *   - Required: No
 *   - Description: Additional observations
 *
 * @testScenarios
 * - Add new item to empty cart
 * - Add new item to existing cart
 * - Add item that already exists (should update quantity)
 * - Add item with quantity that exceeds limit
 * - Add unavailable product
 * - Add with invalid flavor
 * - Add with invalid size
 * - Add with quantity below minimum
 * - Add with quantity above maximum
 */
CREATE OR ALTER PROCEDURE [functional].[spCartItemAdd]
  @idAccount INT,
  @idUser INT,
  @idProduct INT,
  @idFlavor INT,
  @idSize INT,
  @quantity INT,
  @observations NVARCHAR(200) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  /**
   * @validation Account parameter validation
   * @throw {accountRequired}
   */
  IF (@idAccount IS NULL)
  BEGIN
    ;THROW 51000, 'accountRequired', 1;
  END;

  /**
   * @validation User parameter validation
   * @throw {userRequired}
   */
  IF (@idUser IS NULL)
  BEGIN
    ;THROW 51000, 'userRequired', 1;
  END;

  /**
   * @validation Product parameter validation
   * @throw {productRequired}
   */
  IF (@idProduct IS NULL)
  BEGIN
    ;THROW 51000, 'productRequired', 1;
  END;

  /**
   * @validation Flavor parameter validation
   * @throw {flavorRequired}
   */
  IF (@idFlavor IS NULL)
  BEGIN
    ;THROW 51000, 'flavorRequired', 1;
  END;

  /**
   * @validation Size parameter validation
   * @throw {sizeRequired}
   */
  IF (@idSize IS NULL)
  BEGIN
    ;THROW 51000, 'sizeRequired', 1;
  END;

  /**
   * @validation Quantity parameter validation
   * @throw {quantityRequired}
   */
  IF (@quantity IS NULL OR @quantity < 1)
  BEGIN
    ;THROW 51000, 'quantityRequired', 1;
  END;

  /**
   * @validation Quantity maximum validation
   * @throw {quantityExceedsMaximum}
   */
  IF (@quantity > 10)
  BEGIN
    ;THROW 51000, 'quantityExceedsMaximum', 1;
  END;

  /**
   * @validation Product existence and availability
   * @throw {productNotAvailable}
   */
  IF NOT EXISTS (
    SELECT 1
    FROM [functional].[product] [prd]
    WHERE [prd].[idProduct] = @idProduct
      AND [prd].[idAccount] = @idAccount
      AND [prd].[deleted] = 0
      AND [prd].[active] = 1
      AND [prd].[available] = 1
  )
  BEGIN
    ;THROW 51000, 'productNotAvailable', 1;
  END;

  /**
   * @validation Flavor availability for product
   * @throw {flavorNotAvailable}
   */
  IF NOT EXISTS (
    SELECT 1
    FROM [functional].[productFlavor] [prdFlv]
    WHERE [prdFlv].[idProduct] = @idProduct
      AND [prdFlv].[idAccount] = @idAccount
      AND [prdFlv].[idFlavor] = @idFlavor
  )
  BEGIN
    ;THROW 51000, 'flavorNotAvailable', 1;
  END;

  /**
   * @validation Size availability for product
   * @throw {sizeNotAvailable}
   */
  IF NOT EXISTS (
    SELECT 1
    FROM [functional].[productSize] [prdSiz]
    WHERE [prdSiz].[idProduct] = @idProduct
      AND [prdSiz].[idAccount] = @idAccount
      AND [prdSiz].[idSize] = @idSize
  )
  BEGIN
    ;THROW 51000, 'sizeNotAvailable', 1;
  END;

  BEGIN TRY
    BEGIN TRAN;

    DECLARE @idCart INT;
    DECLARE @unitPrice NUMERIC(18, 6);
    DECLARE @totalPrice NUMERIC(18, 6);
    DECLARE @existingQuantity INT = 0;
    DECLARE @idCartItem INT;

    /**
     * @rule {db-transaction-control-pattern} Ensure cart exists or create new one
     */
    SELECT @idCart = [crt].[idCart]
    FROM [functional].[cart] [crt]
    WHERE [crt].[idAccount] = @idAccount
      AND [crt].[idUser] = @idUser;

    IF (@idCart IS NULL)
    BEGIN
      INSERT INTO [functional].[cart] ([idAccount], [idUser])
      VALUES (@idAccount, @idUser);

      SET @idCart = SCOPE_IDENTITY();
    END;

    /**
     * @rule {br-013} Calculate unit price (base price + size modifier)
     */
    SELECT
      @unitPrice = ISNULL([prd].[promotionalPrice], [prd].[basePrice]) + [siz].[priceModifier]
    FROM [functional].[product] [prd]
      JOIN [functional].[size] [siz] ON ([siz].[idSize] = @idSize)
    WHERE [prd].[idProduct] = @idProduct
      AND [prd].[idAccount] = @idAccount;

    SET @totalPrice = @unitPrice * @quantity;

    /**
     * @rule {br-020} Check if item already exists in cart
     */
    SELECT
      @idCartItem = [crtItm].[idCartItem],
      @existingQuantity = [crtItm].[quantity]
    FROM [functional].[cartItem] [crtItm]
    WHERE [crtItm].[idCart] = @idCart
      AND [crtItm].[idAccount] = @idAccount
      AND [crtItm].[idProduct] = @idProduct
      AND [crtItm].[idFlavor] = @idFlavor
      AND [crtItm].[idSize] = @idSize;

    IF (@idCartItem IS NOT NULL)
    BEGIN
      /**
       * @rule {br-020} Update existing item quantity
       * @rule {br-021} Validate total quantity doesn't exceed maximum
       */
      DECLARE @newQuantity INT = @existingQuantity + @quantity;

      IF (@newQuantity > 10)
      BEGIN
        ;THROW 51000, 'quantityExceedsMaximum', 1;
      END;

      UPDATE [functional].[cartItem]
      SET
        [quantity] = @newQuantity,
        [totalPrice] = @unitPrice * @newQuantity,
        [observations] = ISNULL(@observations, [observations])
      WHERE [idCartItem] = @idCartItem;
    END
    ELSE
    BEGIN
      /**
       * @rule {br-018} Add new item to cart
       */
      INSERT INTO [functional].[cartItem] (
        [idAccount],
        [idCart],
        [idProduct],
        [idFlavor],
        [idSize],
        [quantity],
        [unitPrice],
        [totalPrice],
        [observations]
      )
      VALUES (
        @idAccount,
        @idCart,
        @idProduct,
        @idFlavor,
        @idSize,
        @quantity,
        @unitPrice,
        @totalPrice,
        @observations
      );

      SET @idCartItem = SCOPE_IDENTITY();
    END;

    /**
     * @rule {db-transaction-control-pattern} Update cart modification date
     */
    UPDATE [functional].[cart]
    SET [dateModified] = GETUTCDATE()
    WHERE [idCart] = @idCart;

    COMMIT TRAN;

    /**
     * @output {CartItemAdded, 1, n}
     * @column {INT} idCartItem - Cart item identifier
     * @column {INT} idCart - Cart identifier
     * @column {INT} quantity - Item quantity
     * @column {NUMERIC} unitPrice - Unit price
     * @column {NUMERIC} totalPrice - Total price
     * @column {BIT} success - Operation success indicator
     */
    SELECT
      @idCartItem AS [idCartItem],
      @idCart AS [idCart],
      @quantity AS [quantity],
      @unitPrice AS [unitPrice],
      @totalPrice AS [totalPrice],
      CAST(1 AS BIT) AS [success];
  END TRY
  BEGIN CATCH
    ROLLBACK TRAN;
    THROW;
  END CATCH;
END;
GO