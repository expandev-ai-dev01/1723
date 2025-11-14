import { getPool } from '@/instances/database';
import sql from 'mssql';

/**
 * @interface ProductListParams
 * @description Parameters for listing products with filters
 */
export interface ProductListParams {
  idAccount: number;
  page?: number;
  pageSize?: number;
  sortBy?: string;
  categories?: string;
  flavors?: string;
  sizes?: string;
  minPrice?: number;
  maxPrice?: number;
  confectioners?: string;
  availability?: string;
  searchTerm?: string;
}

/**
 * @interface ProductGetParams
 * @description Parameters for getting product details
 */
export interface ProductGetParams {
  idAccount: number;
  idProduct: number;
}

/**
 * @interface CartItemAddParams
 * @description Parameters for adding item to cart
 */
export interface CartItemAddParams {
  idAccount: number;
  idUser: number;
  idProduct: number;
  idFlavor: number;
  idSize: number;
  quantity: number;
  observations?: string;
}

/**
 * @interface ProductRelatedParams
 * @description Parameters for getting related products
 */
export interface ProductRelatedParams {
  idAccount: number;
  idProduct: number;
  limit?: number;
  criteria?: string;
}

/**
 * @summary
 * Lists products with pagination, filtering, and sorting
 *
 * @function productList
 * @module product
 *
 * @param {ProductListParams} params - Product list parameters
 *
 * @returns {Promise<any>} Product list with pagination metadata
 *
 * @throws {ValidationError} When parameters fail validation
 * @throws {DatabaseError} When database operation fails
 */
export async function productList(params: ProductListParams): Promise<any> {
  const pool = await getPool();

  const result = await pool
    .request()
    .input('idAccount', sql.Int, params.idAccount)
    .input('page', sql.Int, params.page || 1)
    .input('pageSize', sql.Int, params.pageSize || 12)
    .input('sortBy', sql.NVarChar(20), params.sortBy || 'relevancia')
    .input('categories', sql.NVarChar(sql.MAX), params.categories || null)
    .input('flavors', sql.NVarChar(sql.MAX), params.flavors || null)
    .input('sizes', sql.NVarChar(sql.MAX), params.sizes || null)
    .input('minPrice', sql.Numeric(18, 6), params.minPrice || null)
    .input('maxPrice', sql.Numeric(18, 6), params.maxPrice || null)
    .input('confectioners', sql.NVarChar(sql.MAX), params.confectioners || null)
    .input('availability', sql.NVarChar(20), params.availability || 'disponivel')
    .input('searchTerm', sql.NVarChar(100), params.searchTerm || null)
    .execute('[functional].[spProductList]');

  return {
    products: result.recordsets[0],
    pagination: result.recordsets[1][0],
  };
}

/**
 * @summary
 * Gets detailed product information
 *
 * @function productGet
 * @module product
 *
 * @param {ProductGetParams} params - Product get parameters
 *
 * @returns {Promise<any>} Product details with flavors, sizes, and reviews
 *
 * @throws {ValidationError} When parameters fail validation
 * @throws {DatabaseError} When database operation fails
 */
export async function productGet(params: ProductGetParams): Promise<any> {
  const pool = await getPool();

  const result = await pool
    .request()
    .input('idAccount', sql.Int, params.idAccount)
    .input('idProduct', sql.Int, params.idProduct)
    .execute('[functional].[spProductGet]');

  return {
    product: result.recordsets[0][0],
    flavors: result.recordsets[1],
    sizes: result.recordsets[2],
    reviews: result.recordsets[3],
  };
}

/**
 * @summary
 * Adds product to shopping cart
 *
 * @function cartItemAdd
 * @module product
 *
 * @param {CartItemAddParams} params - Cart item add parameters
 *
 * @returns {Promise<any>} Cart item details
 *
 * @throws {ValidationError} When parameters fail validation
 * @throws {DatabaseError} When database operation fails
 */
export async function cartItemAdd(params: CartItemAddParams): Promise<any> {
  const pool = await getPool();

  const result = await pool
    .request()
    .input('idAccount', sql.Int, params.idAccount)
    .input('idUser', sql.Int, params.idUser)
    .input('idProduct', sql.Int, params.idProduct)
    .input('idFlavor', sql.Int, params.idFlavor)
    .input('idSize', sql.Int, params.idSize)
    .input('quantity', sql.Int, params.quantity)
    .input('observations', sql.NVarChar(200), params.observations || null)
    .execute('[functional].[spCartItemAdd]');

  return result.recordset[0];
}

/**
 * @summary
 * Gets related products based on criteria
 *
 * @function productRelated
 * @module product
 *
 * @param {ProductRelatedParams} params - Product related parameters
 *
 * @returns {Promise<any>} Related products list
 *
 * @throws {ValidationError} When parameters fail validation
 * @throws {DatabaseError} When database operation fails
 */
export async function productRelated(params: ProductRelatedParams): Promise<any> {
  const pool = await getPool();

  const result = await pool
    .request()
    .input('idAccount', sql.Int, params.idAccount)
    .input('idProduct', sql.Int, params.idProduct)
    .input('limit', sql.Int, params.limit || 4)
    .input('criteria', sql.NVarChar(20), params.criteria || 'categoria')
    .execute('[functional].[spProductRelated]');

  return result.recordset;
}
