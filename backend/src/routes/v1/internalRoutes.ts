import { Router } from 'express';
import * as productController from '@/api/v1/internal/product/controller';

const router = Router();

/**
 * @summary Internal API routes configuration
 * @description Authenticated endpoints for business operations
 */

/**
 * @api Product routes - /api/v1/internal/product
 */
router.get('/product', productController.listHandler);
router.get('/product/:id', productController.getHandler);
router.get('/product/:id/related', productController.relatedHandler);

/**
 * @api Cart routes - /api/v1/internal/cart
 */
router.post('/cart/item', productController.addToCartHandler);

export default router;
