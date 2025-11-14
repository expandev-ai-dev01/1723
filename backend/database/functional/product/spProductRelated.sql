/**
 * @summary
 * Retrieves related products based on specified criteria (category, flavor,
 * confectioner, or popularity). Excludes the reference product and returns
 * only available products. Falls back to popular products if insufficient
 * results are found.
 *
 * @procedure spProductRelated
 * @schema functional
 * @type stored-procedure
 *
 * @endpoints
 * - GET /api/v1/internal/product/:id/related
 *
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy
 *
 * @param {INT} idProduct
 *   - Required: Yes
 *   - Description: Reference product identifier
 *
 * @param {INT} limit
 *   - Required: No
 *   - Description: Maximum number of related products to return (default: 4)
 *
 * @param {NVARCHAR(20)} criteria
 *   - Required: No
 *   - Description: Relation criteria (categoria, sabor, confeiteiro, popularidade)
 *
 * @testScenarios
 * - Get related products by category
 * - Get related products by confectioner
 * - Get related products by popularity
 * - Handle insufficient results (fallback to popular)
 * - Exclude reference product from results
 * - Return only available products
 * - Handle non-existent reference product
 */
CREATE OR ALTER PROCEDURE [functional].[spProductRelated]
  @idAccount INT,
  @idProduct INT,
  @limit INT = 4,
  @criteria NVARCHAR(20) = 'categoria'
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
   * @validation Criteria parameter validation
   * @throw {criteriaInvalidValue}
   */
  IF (@criteria NOT IN ('categoria', 'sabor', 'confeiteiro', 'popularidade'))
  BEGIN
    ;THROW 51000, 'criteriaInvalidValue', 1;
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
  )
  BEGIN
    ;THROW 51000, 'productDoesntExist', 1;
  END;

  DECLARE @idCategory INT;
  DECLARE @idConfectioner INT;

  /**
   * @rule {br-025} Get reference product details for filtering
   */
  SELECT
    @idCategory = [prd].[idCategory],
    @idConfectioner = [prd].[idConfectioner]
  FROM [functional].[product] [prd]
  WHERE [prd].[idProduct] = @idProduct
    AND [prd].[idAccount] = @idAccount;

  /**
   * @rule {br-023} Exclude reference product from results
   * @rule {br-024} Return only available products
   * @rule {br-025} Prioritize by criteria
   * @rule {br-026} Fallback to popular products if insufficient results
   */
  WITH [RelatedProducts] AS (
    SELECT
      [prd].[idProduct],
      [prd].[name],
      [prd].[mainImage],
      [prd].[basePrice],
      [prd].[promotionalPrice],
      ISNULL([prd].[promotionalPrice], [prd].[basePrice]) AS [currentPrice],
      [prd].[averageRating],
      [prd].[totalReviews],
      [cnf].[name] AS [confectionerName],
      CASE
        WHEN @criteria = 'categoria' AND [prd].[idCategory] = @idCategory THEN 1
        WHEN @criteria = 'confeiteiro' AND [prd].[idConfectioner] = @idConfectioner THEN 1
        WHEN @criteria = 'sabor' AND EXISTS (
          SELECT 1
          FROM [functional].[productFlavor] [prdFlv1]
          WHERE [prdFlv1].[idProduct] = @idProduct
            AND [prdFlv1].[idAccount] = @idAccount
            AND EXISTS (
              SELECT 1
              FROM [functional].[productFlavor] [prdFlv2]
              WHERE [prdFlv2].[idProduct] = [prd].[idProduct]
                AND [prdFlv2].[idAccount] = [prd].[idAccount]
                AND [prdFlv2].[idFlavor] = [prdFlv1].[idFlavor]
            )
        ) THEN 1
        ELSE 0
      END AS [matchesCriteria],
      [prd].[totalReviews] AS [popularity]
    FROM [functional].[product] [prd]
      JOIN [functional].[confectioner] [cnf] ON ([cnf].[idAccount] = [prd].[idAccount] AND [cnf].[idConfectioner] = [prd].[idConfectioner])
    WHERE [prd].[idAccount] = @idAccount
      AND [prd].[idProduct] <> @idProduct
      AND [prd].[deleted] = 0
      AND [prd].[active] = 1
      AND [prd].[available] = 1
      AND [cnf].[deleted] = 0
  )
  /**
   * @output {RelatedProducts, n, n}
   * @column {INT} idProduct - Product identifier
   * @column {NVARCHAR} name - Product name
   * @column {NVARCHAR} mainImage - Main product image URL
   * @column {NUMERIC} basePrice - Base price
   * @column {NUMERIC} promotionalPrice - Promotional price (if applicable)
   * @column {NUMERIC} currentPrice - Current effective price
   * @column {NUMERIC} averageRating - Average customer rating
   * @column {INT} totalReviews - Total number of reviews
   * @column {NVARCHAR} confectionerName - Confectioner name
   */
  SELECT TOP (@limit)
    [relPrd].[idProduct],
    [relPrd].[name],
    [relPrd].[mainImage],
    [relPrd].[basePrice],
    [relPrd].[promotionalPrice],
    [relPrd].[currentPrice],
    [relPrd].[averageRating],
    [relPrd].[totalReviews],
    [relPrd].[confectionerName]
  FROM [RelatedProducts] [relPrd]
  ORDER BY
    [relPrd].[matchesCriteria] DESC,
    [relPrd].[popularity] DESC,
    [relPrd].[averageRating] DESC,
    [relPrd].[idProduct];
END;
GO