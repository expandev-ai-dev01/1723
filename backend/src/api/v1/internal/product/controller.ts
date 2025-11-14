import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import {
  CrudController,
  errorResponse,
  StatusGeneralError,
  successResponse,
} from '@/middleware/crud';
import { productList, productGet, cartItemAdd, productRelated } from '@/services/product';
import { zFK, zPositiveNumber, zString, zNullableString } from '@/utils/zodValidation';

const securable = 'PRODUCT';

/**
 * @api {get} /api/v1/internal/product List Products
 * @apiName ListProducts
 * @apiGroup Product
 * @apiVersion 1.0.0
 *
 * @apiDescription Lists products with pagination, filtering, and sorting
 *
 * @apiParam {Number} [page=1] Page number
 * @apiParam {Number} [pageSize=12] Items per page (12, 24, or 36)
 * @apiParam {String} [sortBy=relevancia] Sort criteria
 * @apiParam {String} [categories] Comma-separated category IDs
 * @apiParam {String} [flavors] Comma-separated flavor IDs
 * @apiParam {String} [sizes] Comma-separated size IDs
 * @apiParam {Number} [minPrice] Minimum price
 * @apiParam {Number} [maxPrice] Maximum price
 * @apiParam {String} [confectioners] Comma-separated confectioner IDs
 * @apiParam {String} [availability=disponivel] Availability filter
 * @apiParam {String} [searchTerm] Search term
 *
 * @apiSuccess {Object[]} products Product list
 * @apiSuccess {Object} pagination Pagination metadata
 *
 * @apiError {String} ValidationError Invalid parameters
 * @apiError {String} ServerError Internal server error
 */
export async function listHandler(req: Request, res: Response, next: NextFunction): Promise<void> {
  const operation = new CrudController([{ securable, permission: 'READ' }]);

  const querySchema = z.object({
    page: z.coerce.number().int().positive().optional(),
    pageSize: z.coerce.number().int().optional(),
    sortBy: z.string().optional(),
    categories: z.string().optional(),
    flavors: z.string().optional(),
    sizes: z.string().optional(),
    minPrice: z.coerce.number().optional(),
    maxPrice: z.coerce.number().optional(),
    confectioners: z.string().optional(),
    availability: z.string().optional(),
    searchTerm: z.string().max(100).optional(),
  });

  const [validated, error] = await operation.read(req, querySchema);

  if (!validated) {
    return next(error);
  }

  try {
    const data = await productList({
      ...validated.credential,
      ...validated.params,
    });

    res.json(successResponse(data));
  } catch (error: any) {
    if (error.number === 51000) {
      res.status(400).json(errorResponse(error.message));
    } else {
      next(StatusGeneralError);
    }
  }
}

/**
 * @api {get} /api/v1/internal/product/:id Get Product Details
 * @apiName GetProduct
 * @apiGroup Product
 * @apiVersion 1.0.0
 *
 * @apiDescription Gets detailed product information
 *
 * @apiParam {Number} id Product identifier
 *
 * @apiSuccess {Object} product Product details
 * @apiSuccess {Object[]} flavors Available flavors
 * @apiSuccess {Object[]} sizes Available sizes
 * @apiSuccess {Object[]} reviews Product reviews
 *
 * @apiError {String} ValidationError Invalid product ID
 * @apiError {String} NotFoundError Product not found
 * @apiError {String} ServerError Internal server error
 */
export async function getHandler(req: Request, res: Response, next: NextFunction): Promise<void> {
  const operation = new CrudController([{ securable, permission: 'READ' }]);

  const paramsSchema = z.object({
    id: zFK,
  });

  const [validated, error] = await operation.read(req, paramsSchema);

  if (!validated) {
    return next(error);
  }

  try {
    const data = await productGet({
      ...validated.credential,
      idProduct: validated.params.id,
    });

    res.json(successResponse(data));
  } catch (error: any) {
    if (error.number === 51000) {
      res.status(400).json(errorResponse(error.message));
    } else {
      next(StatusGeneralError);
    }
  }
}

/**
 * @api {get} /api/v1/internal/product/:id/related Get Related Products
 * @apiName GetRelatedProducts
 * @apiGroup Product
 * @apiVersion 1.0.0
 *
 * @apiDescription Gets related products based on criteria
 *
 * @apiParam {Number} id Product identifier
 * @apiParam {Number} [limit=4] Maximum number of results
 * @apiParam {String} [criteria=categoria] Relation criteria
 *
 * @apiSuccess {Object[]} products Related products
 *
 * @apiError {String} ValidationError Invalid parameters
 * @apiError {String} ServerError Internal server error
 */
export async function relatedHandler(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const operation = new CrudController([{ securable, permission: 'READ' }]);

  const paramsSchema = z.object({
    id: zFK,
  });

  const querySchema = z.object({
    limit: z.coerce.number().int().positive().optional(),
    criteria: z.string().optional(),
  });

  const [validated, error] = await operation.read(req, paramsSchema);

  if (!validated) {
    return next(error);
  }

  try {
    const query = querySchema.parse(req.query);

    const data = await productRelated({
      ...validated.credential,
      idProduct: validated.params.id,
      ...query,
    });

    res.json(successResponse(data));
  } catch (error: any) {
    if (error.number === 51000) {
      res.status(400).json(errorResponse(error.message));
    } else {
      next(StatusGeneralError);
    }
  }
}

/**
 * @api {post} /api/v1/internal/cart/item Add to Cart
 * @apiName AddToCart
 * @apiGroup Product
 * @apiVersion 1.0.0
 *
 * @apiDescription Adds product to shopping cart
 *
 * @apiParam {Number} idProduct Product identifier
 * @apiParam {Number} idFlavor Flavor identifier
 * @apiParam {Number} idSize Size identifier
 * @apiParam {Number} quantity Quantity (1-10)
 * @apiParam {String} [observations] Additional observations
 *
 * @apiSuccess {Object} cartItem Cart item details
 *
 * @apiError {String} ValidationError Invalid parameters
 * @apiError {String} ServerError Internal server error
 */
export async function addToCartHandler(
  req: Request,
  res: Response,
  next: NextFunction
): Promise<void> {
  const operation = new CrudController([{ securable, permission: 'CREATE' }]);

  const bodySchema = z.object({
    idProduct: zFK,
    idFlavor: zFK,
    idSize: zFK,
    quantity: z.number().int().min(1).max(10),
    observations: zNullableString(200),
  });

  const [validated, error] = await operation.create(req, bodySchema);

  if (!validated) {
    return next(error);
  }

  try {
    const data = await cartItemAdd({
      ...validated.credential,
      ...validated.body,
    });

    res.json(successResponse(data));
  } catch (error: any) {
    if (error.number === 51000) {
      res.status(400).json(errorResponse(error.message));
    } else {
      next(StatusGeneralError);
    }
  }
}
