import { z } from 'zod';

/**
 * @summary Standard Zod validation schemas
 * @description Reusable validation schemas for common data types
 */

/**
 * @validation String validations
 */
export const zString = z.string().min(1);
export const zNullableString = (maxLength?: number) => {
  let schema = z.string();
  if (maxLength) {
    schema = schema.max(maxLength);
  }
  return schema.nullable();
};

/**
 * @validation Name validations
 */
export const zName = z.string().min(1).max(200);
export const zNullableName = z.string().max(200).nullable();

/**
 * @validation Description validations
 */
export const zDescription = z.string().min(1).max(500);
export const zNullableDescription = z.string().max(500).nullable();

/**
 * @validation Numeric validations
 */
export const zNumber = z.number();
export const zPositiveNumber = z.number().positive();
export const zNullableNumber = z.number().nullable();

/**
 * @validation Foreign key validations
 */
export const zFK = z.coerce.number().int().positive();
export const zNullableFK = z.coerce.number().int().positive().nullable();

/**
 * @validation Boolean validations
 */
export const zBit = z.coerce.number().int().min(0).max(1);
export const zBoolean = z.boolean();

/**
 * @validation Date validations
 */
export const zDate = z.coerce.date();
export const zDateString = z.string().datetime();
export const zNullableDate = z.coerce.date().nullable();

/**
 * @validation Email validation
 */
export const zEmail = z.string().email().max(255);

/**
 * @validation Price validation
 */
export const zPrice = z.number().min(0);
export const zNullablePrice = z.number().min(0).nullable();
