import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * @utility cn
 * @summary Merges Tailwind CSS classes safely
 * @domain core
 * @type utility-function
 * @category styling
 *
 * @description
 * Combines clsx and tailwind-merge to handle conditional classes
 * and resolve Tailwind class conflicts.
 *
 * @param {...ClassValue[]} inputs - Class values to merge
 * @returns {string} Merged class string
 */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
