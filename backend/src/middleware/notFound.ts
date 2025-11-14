import { Request, Response } from 'express';

/**
 * @summary 404 Not Found middleware
 * @description Handles requests to non-existent routes
 *
 * @param req Express request object
 * @param res Express response object
 */
export function notFoundMiddleware(req: Request, res: Response): void {
  res.status(404).json({
    success: false,
    error: {
      code: 'NOT_FOUND',
      message: `Route ${req.method} ${req.path} not found`,
    },
    timestamp: new Date().toISOString(),
  });
}
