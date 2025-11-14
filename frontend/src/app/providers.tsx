import { ReactNode } from 'react';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from '@/core/lib/queryClient';

/**
 * @component AppProviders
 * @summary Global application providers wrapper
 * @domain core
 * @type provider-component
 * @category application
 *
 * @description
 * Wraps the application with all necessary context providers
 * including React Query for server state management.
 */
export const AppProviders = ({ children }: { children: ReactNode }) => {
  return <QueryClientProvider client={queryClient}>{children}</QueryClientProvider>;
};
