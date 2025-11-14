/**
 * @summary
 * Lists products with pagination, filtering, and sorting capabilities.
 * Supports filtering by category, flavor, size, price range, confectioner,
 * availability, and search term. Returns only active products.
 *
 * @procedure spProductList
 * @schema functional
 * @type stored-procedure
 *
 * @endpoints
 * - GET /api/v1/internal/product
 *
 * @parameters
 * @param {INT} idAccount
 *   - Required: Yes
 *   - Description: Account identifier for multi-tenancy
 *
 * @param {INT} page
 *   - Required: No
 *   - Description: Page number for pagination (default: 1)
 *
 * @param {INT} pageSize
 *   - Required: No
 *   - Description: Number of items per page (default: 12)
 *
 * @param {NVARCHAR(20)} sortBy
 *   - Required: No
 *   - Description: Sort criteria (relevancia, preco_menor, preco_maior, mais_vendidos, melhor_avaliados, mais_recentes)
 *
 * @param {NVARCHAR(MAX)} categories
 *   - Required: No
 *   - Description: Comma-separated category IDs
 *
 * @param {NVARCHAR(MAX)} flavors
 *   - Required: No
 *   - Description: Comma-separated flavor IDs
 *
 * @param {NVARCHAR(MAX)} sizes
 *   - Required: No
 *   - Description: Comma-separated size IDs
 *
 * @param {NUMERIC(18,6)} minPrice
 *   - Required: No
 *   - Description: Minimum price filter
 *
 * @param {NUMERIC(18,6)} maxPrice
 *   - Required: No
 *   - Description: Maximum price filter
 *
 * @param {NVARCHAR(MAX)} confectioners
 *   - Required: No
 *   - Description: Comma-separated confectioner IDs
 *
 * @param {NVARCHAR(20)} availability
 *   - Required: No
 *   - Description: Filter by availability (disponivel, indisponivel, todos)
 *
 * @param {NVARCHAR(100)} searchTerm
 *   - Required: No
 *   - Description: Search term for name, description, or ingredients
 *
 * @testScenarios
 * - List all products with default pagination
 * - Filter by single category
 * - Filter by multiple categories, flavors, and sizes
 * - Filter by price range
 * - Filter by confectioner
 * - Search by product name
 * - Search by ingredients
 * - Sort by price ascending/descending
 * - Sort by rating
 * - Sort by most recent
 * - Combine multiple filters
 * - Handle empty results
 */
CREATE OR ALTER PROCEDURE [functional].[spProductList]
  @idAccount INT,
  @page INT = 1,
  @pageSize INT = 12,
  @sortBy NVARCHAR(20) = 'relevancia',
  @categories NVARCHAR(MAX) = NULL,
  @flavors NVARCHAR(MAX) = NULL,
  @sizes NVARCHAR(MAX) = NULL,
  @minPrice NUMERIC(18, 6) = NULL,
  @maxPrice NUMERIC(18, 6) = NULL,
  @confectioners NVARCHAR(MAX) = NULL,
  @availability NVARCHAR(20) = 'disponivel',
  @searchTerm NVARCHAR(100) = NULL
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
   * @validation Page parameter validation
   * @throw {pageMinimumValue}
   */
  IF (@page < 1)
  BEGIN
    ;THROW 51000, 'pageMinimumValue', 1;
  END;

  /**
   * @validation Page size parameter validation
   * @throw {pageSizeInvalidValue}
   */
  IF (@pageSize NOT IN (12, 24, 36))
  BEGIN
    ;THROW 51000, 'pageSizeInvalidValue', 1;
  END;

  /**
   * @validation Sort parameter validation
   * @throw {sortByInvalidValue}
   */
  IF (@sortBy NOT IN ('relevancia', 'preco_menor', 'preco_maior', 'mais_vendidos', 'melhor_avaliados', 'mais_recentes'))
  BEGIN
    ;THROW 51000, 'sortByInvalidValue', 1;
  END;

  /**
   * @validation Availability parameter validation
   * @throw {availabilityInvalidValue}
   */
  IF (@availability NOT IN ('disponivel', 'indisponivel', 'todos'))
  BEGIN
    ;THROW 51000, 'availabilityInvalidValue', 1;
  END;

  /**
   * @validation Price range validation
   * @throw {priceRangeInvalid}
   */
  IF (@minPrice IS NOT NULL AND @maxPrice IS NOT NULL AND @minPrice > @maxPrice)
  BEGIN
    ;THROW 51000, 'priceRangeInvalid', 1;
  END;

  DECLARE @offset INT = (@page - 1) * @pageSize;

  /**
   * @rule {db-multi-tenancy-pattern} Apply account-based filtering
   * @rule {db-soft-delete-pattern} Filter deleted records
   */
  WITH [FilteredProducts] AS (
    SELECT
      [prd].[idProduct],
      [prd].[name],
      [prd].[description],
      [prd].[ingredients],
      [prd].[basePrice],
      [prd].[promotionalPrice],
      [prd].[mainImage],
      [prd].[averageRating],
      [prd].[totalReviews],
      [prd].[preparationTime],
      [prd].[available],
      [prd].[dateCreated],
      [cat].[name] AS [categoryName],
      [cnf].[name] AS [confectionerName],
      [cnf].[averageRating] AS [confectionerRating]
    FROM [functional].[product] [prd]
      JOIN [functional].[category] [cat] ON ([cat].[idAccount] = [prd].[idAccount] AND [cat].[idCategory] = [prd].[idCategory])
      JOIN [functional].[confectioner] [cnf] ON ([cnf].[idAccount] = [prd].[idAccount] AND [cnf].[idConfectioner] = [prd].[idConfectioner])
    WHERE [prd].[idAccount] = @idAccount
      AND [prd].[deleted] = 0
      AND [prd].[active] = 1
      AND [cat].[deleted] = 0
      AND [cnf].[deleted] = 0
      /**
       * @rule {br-001} Filter only active products
       */
      AND (
        (@availability = 'disponivel' AND [prd].[available] = 1)
        OR (@availability = 'indisponivel' AND [prd].[available] = 0)
        OR (@availability = 'todos')
      )
      /**
       * @rule {br-006} Search by name, description, or ingredients
       */
      AND (
        (@searchTerm IS NULL)
        OR ([prd].[name] LIKE '%' + @searchTerm + '%')
        OR ([prd].[description] LIKE '%' + @searchTerm + '%')
        OR ([prd].[ingredients] LIKE '%' + @searchTerm + '%')
      )
      /**
       * @rule {br-005} Apply category filter with AND logic
       */
      AND (
        (@categories IS NULL)
        OR ([prd].[idCategory] IN (SELECT CAST([value] AS INT) FROM STRING_SPLIT(@categories, ',')))
      )
      /**
       * @rule {br-005} Apply confectioner filter with AND logic
       */
      AND (
        (@confectioners IS NULL)
        OR ([prd].[idConfectioner] IN (SELECT CAST([value] AS INT) FROM STRING_SPLIT(@confectioners, ',')))
      )
      /**
       * @rule {br-005} Apply price range filter with AND logic
       */
      AND (
        (@minPrice IS NULL OR ISNULL([prd].[promotionalPrice], [prd].[basePrice]) >= @minPrice)
        AND (@maxPrice IS NULL OR ISNULL([prd].[promotionalPrice], [prd].[basePrice]) <= @maxPrice)
      )
      /**
       * @rule {br-005} Apply flavor filter with AND logic
       */
      AND (
        (@flavors IS NULL)
        OR EXISTS (
          SELECT 1
          FROM [functional].[productFlavor] [prdFlv]
          WHERE [prdFlv].[idAccount] = [prd].[idAccount]
            AND [prdFlv].[idProduct] = [prd].[idProduct]
            AND [prdFlv].[idFlavor] IN (SELECT CAST([value] AS INT) FROM STRING_SPLIT(@flavors, ','))
        )
      )
      /**
       * @rule {br-005} Apply size filter with AND logic
       */
      AND (
        (@sizes IS NULL)
        OR EXISTS (
          SELECT 1
          FROM [functional].[productSize] [prdSiz]
          WHERE [prdSiz].[idAccount] = [prd].[idAccount]
            AND [prdSiz].[idProduct] = [prd].[idProduct]
            AND [prdSiz].[idSize] IN (SELECT CAST([value] AS INT) FROM STRING_SPLIT(@sizes, ','))
        )
      )
  )
  /**
   * @output {ProductList, n, n}
   * @column {INT} idProduct - Product identifier
   * @column {NVARCHAR} name - Product name
   * @column {NVARCHAR} mainImage - Main product image URL
   * @column {NUMERIC} basePrice - Base price
   * @column {NUMERIC} promotionalPrice - Promotional price (if applicable)
   * @column {NUMERIC} currentPrice - Current effective price
   * @column {BIT} hasPromotion - Indicates if product is on promotion
   * @column {NUMERIC} averageRating - Average customer rating
   * @column {INT} totalReviews - Total number of reviews
   * @column {NVARCHAR} confectionerName - Confectioner name
   * @column {BIT} available - Product availability
   * @column {NVARCHAR} preparationTime - Estimated preparation time
   * @column {NVARCHAR} categoryName - Category name
   */
  SELECT
    [fltPrd].[idProduct],
    [fltPrd].[name],
    [fltPrd].[mainImage],
    [fltPrd].[basePrice],
    [fltPrd].[promotionalPrice],
    ISNULL([fltPrd].[promotionalPrice], [fltPrd].[basePrice]) AS [currentPrice],
    CAST(CASE WHEN [fltPrd].[promotionalPrice] IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS [hasPromotion],
    [fltPrd].[averageRating],
    [fltPrd].[totalReviews],
    [fltPrd].[confectionerName],
    [fltPrd].[available],
    [fltPrd].[preparationTime],
    [fltPrd].[categoryName]
  FROM [FilteredProducts] [fltPrd]
  ORDER BY
    CASE WHEN @sortBy = 'preco_menor' THEN ISNULL([fltPrd].[promotionalPrice], [fltPrd].[basePrice]) END ASC,
    CASE WHEN @sortBy = 'preco_maior' THEN ISNULL([fltPrd].[promotionalPrice], [fltPrd].[basePrice]) END DESC,
    CASE WHEN @sortBy = 'melhor_avaliados' THEN [fltPrd].[averageRating] END DESC,
    CASE WHEN @sortBy = 'mais_recentes' THEN [fltPrd].[dateCreated] END DESC,
    [fltPrd].[idProduct]
  OFFSET @offset ROWS
  FETCH NEXT @pageSize ROWS ONLY;

  /**
   * @output {Pagination, 1, n}
   * @column {INT} totalItems - Total number of products matching filters
   * @column {INT} totalPages - Total number of pages
   * @column {INT} currentPage - Current page number
   * @column {INT} pageSize - Items per page
   */
  SELECT
    COUNT(*) AS [totalItems],
    CEILING(CAST(COUNT(*) AS FLOAT) / @pageSize) AS [totalPages],
    @page AS [currentPage],
    @pageSize AS [pageSize]
  FROM [FilteredProducts];
END;
GO