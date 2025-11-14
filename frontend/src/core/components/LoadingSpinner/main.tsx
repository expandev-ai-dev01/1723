import { getLoadingSpinnerClassName } from './variants';
import type { LoadingSpinnerProps } from './types';

/**
 * @component LoadingSpinner
 * @summary Loading spinner component
 * @domain core
 * @type ui-component
 * @category feedback
 *
 * @props
 * @param {LoadingSpinnerProps} props
 * @param {'sm' | 'md' | 'lg'} [props.size='md'] - Spinner size
 * @param {string} [props.className] - Additional CSS classes
 */
export const LoadingSpinner = ({ size = 'md', className }: LoadingSpinnerProps) => {
  return (
    <div className="flex items-center justify-center p-8">
      <div className={getLoadingSpinnerClassName({ size, className })} />
    </div>
  );
};
