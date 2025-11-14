import { AppProviders } from './providers';
import { AppRouter } from './router';

/**
 * @component App
 * @summary Root application component
 * @domain core
 * @type root-component
 * @category application
 *
 * @description
 * Main application component that wraps the entire app with providers
 * and routing configuration.
 */
export const App = () => {
  return (
    <AppProviders>
      <AppRouter />
    </AppProviders>
  );
};
