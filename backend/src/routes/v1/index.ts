import { Router } from 'express';
import externalRoutes from '@/routes/v1/externalRoutes';
import internalRoutes from '@/routes/v1/internalRoutes';

const router = Router();

/**
 * @summary V1 API router configuration
 * @description Routes for API version 1
 */

/**
 * @api External (public) routes - /api/v1/external/...
 */
router.use('/external', externalRoutes);

/**
 * @api Internal (authenticated) routes - /api/v1/internal/...
 */
router.use('/internal', internalRoutes);

export default router;
