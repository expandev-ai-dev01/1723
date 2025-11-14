/**
 * @page HomePage
 * @summary Home page - welcome and product catalog entry
 * @domain core
 * @type landing-page
 * @category public
 *
 * @routing
 * - Path: /
 * - Params: none
 * - Query: none
 * - Guards: none
 */
export const HomePage = () => {
  return (
    <div className="flex flex-col items-center justify-center min-h-[60vh]">
      <h1 className="text-4xl font-bold text-gray-900 mb-4">Bem-vindo ao LoveCakes</h1>
      <p className="text-lg text-gray-600 text-center max-w-2xl">
        Bolos artesanais feitos com amor e ingredientes selecionados. Em breve, você poderá explorar
        nosso catálogo completo.
      </p>
    </div>
  );
};

export default HomePage;
