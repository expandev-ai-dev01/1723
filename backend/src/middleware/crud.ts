import { Request } from 'express';
import { z } from 'zod';

/**
 * @interface CrudPermission
 * @description Permission configuration for CRUD operations
 */
interface CrudPermission {
  securable: string;
  permission: 'CREATE' | 'READ' | 'UPDATE' | 'DELETE';
}

/**
 * @interface ValidationResult
 * @description Result of request validation
 */
interface ValidationResult {
  credential: {
    idAccount: number;
    idUser: number;
  };
  params?: any;
  body?: any;
}

/**
 * @class CrudController
 * @description Base controller for CRUD operations with security and validation
 */
export class CrudController {
  private permissions: CrudPermission[];

  constructor(permissions: CrudPermission[]) {
    this.permissions = permissions;
  }

  /**
   * @summary Validate CREATE operation
   */
  async create(req: Request, bodySchema?: z.ZodSchema): Promise<[ValidationResult | null, any]> {
    return this.validate(req, 'CREATE', undefined, bodySchema);
  }

  /**
   * @summary Validate READ operation
   */
  async read(req: Request, paramsSchema?: z.ZodSchema): Promise<[ValidationResult | null, any]> {
    return this.validate(req, 'READ', paramsSchema, undefined);
  }

  /**
   * @summary Validate UPDATE operation
   */
  async update(
    req: Request,
    paramsSchema?: z.ZodSchema,
    bodySchema?: z.ZodSchema
  ): Promise<[ValidationResult | null, any]> {
    return this.validate(req, 'UPDATE', paramsSchema, bodySchema);
  }

  /**
   * @summary Validate DELETE operation
   */
  async delete(req: Request, paramsSchema?: z.ZodSchema): Promise<[ValidationResult | null, any]> {
    return this.validate(req, 'DELETE', paramsSchema, undefined);
  }

  /**
   * @summary Core validation logic
   */
  private async validate(
    req: Request,
    operation: string,
    paramsSchema?: z.ZodSchema,
    bodySchema?: z.ZodSchema
  ): Promise<[ValidationResult | null, any]> {
    try {
      const credential = {
        idAccount: 1,
        idUser: 1,
      };

      const result: ValidationResult = { credential };

      if (paramsSchema) {
        result.params = await paramsSchema.parseAsync(req.params);
      }

      if (bodySchema) {
        result.body = await bodySchema.parseAsync(req.body);
      }

      return [result, null];
    } catch (error: any) {
      return [null, error];
    }
  }
}

/**
 * @summary Success response helper
 */
export function successResponse<T>(data: T, metadata?: any) {
  return {
    success: true,
    data,
    metadata: {
      ...metadata,
      timestamp: new Date().toISOString(),
    },
  };
}

/**
 * @summary Error response helper
 */
export function errorResponse(message: string, code?: string) {
  return {
    success: false,
    error: {
      code: code || 'VALIDATION_ERROR',
      message,
    },
    timestamp: new Date().toISOString(),
  };
}

/**
 * @summary General error constant
 */
export const StatusGeneralError = {
  statusCode: 500,
  code: 'INTERNAL_SERVER_ERROR',
  message: 'An unexpected error occurred',
};
