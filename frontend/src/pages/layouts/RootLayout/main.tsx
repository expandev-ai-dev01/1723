import { Outlet } from 'react-router-dom';

/**
 * @component RootLayout
 * @summary Root layout component for the application
 * @domain core
 * @type layout-component
 * @category layout
 *
 * @description
 * Base layout that wraps all pages with common structure.
 * Currently minimal, ready to receive header, footer, and navigation.
 */
export const RootLayout = () => {
  return (
    <div className="min-h-screen bg-gray-50">
      <main className="container mx-auto px-4 py-8">
        <Outlet />
      </main>
    </div>
  );
};

export default RootLayout;
