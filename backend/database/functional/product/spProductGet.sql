/**
 * @summary
 * Retrieves detailed information for a specific product including
 * gallery images, description, ingredients, nutritional info, pricing,
 * available flavors and sizes, reviews, and confectioner details.
 *
 * @procedure spProductGet
 * @schema functional
 * @type stored-procedure
 *
 * @endpoints
 * - GET /api/v1/internal/product/:id
 *
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy
 *
 * @param {INT} idProduct
 *   - Required: Yes
 *   - Description: Product identifier
 *
 * @testScenarios
 * - Get product details with valid ID
 * - Get product with promotional price
 * - Get product without promotional price
 * - Get product with multiple flavors and sizes
 * - Get product with reviews
 * - Get product without reviews
 * - Handle non-existent product ID
 * - Handle deleted product
 * - Handle inactive product
 */
CREATE OR ALTER PROCEDURE [functional].[spProductGet]
  @idAccount INT,
  @idProduct INT
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
   * @validation Product parameter validation
   * @throw {productRequired}
   */
  IF (@idProduct IS NULL)
  BEGIN
    ;THROW 51000, 'productRequired', 1;
  END;

  /**
   * @validation Product existence validation
   * @throw {productDoesntExist}
   */
  IF NOT EXISTS (
    SELECT 1
    FROM [functional].[product] [prd]
    WHERE [prd].[idProduct] = @idProduct
      AND [prd].[idAccount] = @idAccount
      AND [prd].[deleted] = 0
      AND [prd].[active] = 1
  )
  BEGIN
    ;THROW 51000, 'productDoesntExist', 1;
  END;

  /**
   * @output {ProductDetails, 1, n}
   * @column {INT} idProduct - Product identifier
   * @column {NVARCHAR} name - Product name
   * @column {NVARCHAR} description - Detailed description
   * @column {NVARCHAR} ingredients - Product ingredients (JSON array)
   * @column {NVARCHAR} nutritionalInfo - Nutritional information (JSON object)
   * @column {NUMERIC} basePrice - Base price
   * @column {NUMERIC} promotionalPrice - Promotional price (if applicable)
   * @column {NUMERIC} currentPrice - Current effective price
   * @column {BIT} hasPromotion - Indicates if product is on promotion
   * @column {NVARCHAR} mainImage - Main product image URL
   * @column {NVARCHAR} imageGallery - Image gallery URLs (JSON array)
   * @column {NUMERIC} averageRating - Average customer rating
   * @column {INT} totalReviews - Total number of reviews
   * @column {NVARCHAR} preparationTime - Estimated preparation time
   * @column {BIT} available - Product availability
   * @column {INT} idConfectioner - Confectioner identifier
   * @column {NVARCHAR} confectionerName - Confectioner name
   * @column {NVARCHAR} confectionerPhoto - Confectioner photo URL
   * @column {NUMERIC} confectionerRating - Confectioner average rating
   * @column {INT} confectionerProductsSold - Total products sold by confectioner
   */
  SELECT
    [prd].[idProduct],
    [prd].[name],
    [prd].[description],
    [prd].[ingredients],
    [prd].[nutritionalInfo],
    [prd].[basePrice],
    [prd].[promotionalPrice],
    ISNULL([prd].[promotionalPrice], [prd].[basePrice]) AS [currentPrice],
    CAST(CASE WHEN [prd].[promotionalPrice] IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS [hasPromotion],
    [prd].[mainImage],
    [prd].[imageGallery],
    [prd].[averageRating],
    [prd].[totalReviews],
    [prd].[preparationTime],
    [prd].[available],
    [cnf].[idConfectioner],
    [cnf].[name] AS [confectionerName],
    [cnf].[photo] AS [confectionerPhoto],
    [cnf].[averageRating] AS [confectionerRating],
    [cnf].[totalProductsSold] AS [confectionerProductsSold]
  FROM [functional].[product] [prd]
    JOIN [functional].[confectioner] [cnf] ON ([cnf].[idAccount] = [prd].[idAccount] AND [cnf].[idConfectioner] = [prd].[idConfectioner])
  WHERE [prd].[idProduct] = @idProduct
    AND [prd].[idAccount] = @idAccount
    AND [prd].[deleted] = 0
    AND [cnf].[deleted] = 0;

  /**
   * @output {AvailableFlavors, n, n}
   * @column {INT} idFlavor - Flavor identifier
   * @column {NVARCHAR} name - Flavor name
   * @column {NVARCHAR} description - Flavor description
   */
  SELECT
    [flv].[idFlavor],
    [flv].[name],
    [flv].[description]
  FROM [functional].[productFlavor] [prdFlv]
    JOIN [functional].[flavor] [flv] ON ([flv].[idAccount] = [prdFlv].[idAccount] AND [flv].[idFlavor] = [prdFlv].[idFlavor])
  WHERE [prdFlv].[idProduct] = @idProduct
    AND [prdFlv].[idAccount] = @idAccount
    AND [flv].[deleted] = 0
  ORDER BY [flv].[name];

  /**
   * @output {AvailableSizes, n, n}
   * @column {INT} idSize - Size identifier
   * @column {NVARCHAR} name - Size name
   * @column {NVARCHAR} description - Size description (e.g., '15cm - serves 10 people')
   * @column {NUMERIC} priceModifier - Additional price for this size
   */
  SELECT
    [siz].[idSize],
    [siz].[name],
    [siz].[description],
    [siz].[priceModifier]
  FROM [functional].[productSize] [prdSiz]
    JOIN [functional].[size] [siz] ON ([siz].[idAccount] = [prdSiz].[idAccount] AND [siz].[idSize] = [prdSiz].[idSize])
  WHERE [prdSiz].[idProduct] = @idProduct
    AND [prdSiz].[idAccount] = @idAccount
    AND [siz].[deleted] = 0
  ORDER BY [siz].[priceModifier];

  /**
   * @output {ProductReviews, n, n}
   * @column {INT} idReview - Review identifier
   * @column {NVARCHAR} customerName - Customer name
   * @column {INT} rating - Rating (1-5)
   * @column {NVARCHAR} comment - Review comment
   * @column {DATETIME2} dateCreated - Review date
   */
  SELECT
    [rev].[idReview],
    [rev].[customerName],
    [rev].[rating],
    [rev].[comment],
    [rev].[dateCreated]
  FROM [functional].[review] [rev]
  WHERE [rev].[idProduct] = @idProduct
    AND [rev].[idAccount] = @idAccount
    AND [rev].[deleted] = 0
  ORDER BY [rev].[dateCreated] DESC;
END;
GO