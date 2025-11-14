# LoveCakes - Frontend

Interface de compra e venda de bolos artesanais.

## Tecnologias

- React 18.3.1
- TypeScript 5.6.3
- Vite 5.4.11
- TailwindCSS 3.4.14
- React Router DOM 6.26.2
- TanStack Query 5.59.20
- Axios 1.7.7
- Zustand 5.0.1
- React Hook Form 7.53.1
- Zod 3.23.8

## Estrutura do Projeto

```
src/
├── app/                    # Configuração da aplicação
│   ├── App.tsx            # Componente raiz
│   ├── providers.tsx      # Provedores globais
│   └── router.tsx         # Configuração de rotas
├── pages/                 # Páginas da aplicação
│   ├── layouts/          # Layouts compartilhados
│   ├── Home/             # Página inicial
│   └── NotFound/         # Página 404
├── domain/               # Domínios de negócio
├── core/                 # Componentes e utilitários globais
│   ├── components/       # Componentes reutilizáveis
│   ├── lib/             # Configurações de bibliotecas
│   └── utils/           # Funções utilitárias
└── assets/              # Recursos estáticos
    └── styles/          # Estilos globais
```

## Configuração

1. Instalar dependências:
```bash
npm install
```

2. Configurar variáveis de ambiente:
```bash
cp .env.example .env
```

3. Editar `.env` com as configurações do backend:
```
VITE_API_URL=http://localhost:3000
VITE_API_VERSION=v1
VITE_API_TIMEOUT=30000
```

## Desenvolvimento

```bash
npm run dev
```

Acesse: http://localhost:5173

## Build

```bash
npm run build
```

## Preview

```bash
npm run preview
```

## Lint

```bash
npm run lint
```

## Arquitetura

### API Client

O projeto utiliza dois clientes HTTP:

- `publicClient`: Para endpoints públicos (`/api/v1/external`)
- `authenticatedClient`: Para endpoints autenticados (`/api/v1/internal`)

### State Management

- **TanStack Query**: Gerenciamento de estado do servidor
- **Zustand**: Estado global da aplicação (quando necessário)
- **React Hook Form**: Estado de formulários

### Roteamento

- React Router DOM com lazy loading
- Layouts hierárquicos
- Proteção de rotas (a ser implementado)

## Próximos Passos

- [ ] Implementar domínio de produtos
- [ ] Implementar catálogo de bolos
- [ ] Implementar carrinho de compras
- [ ] Implementar autenticação
- [ ] Implementar checkout

## Convenções

- Componentes em PascalCase
- Arquivos de implementação: `main.tsx`
- Tipos: `types.ts`
- Variantes de estilo: `variants.ts`
- Exports centralizados: `index.ts`
- Hooks customizados: `use[Nome]`
- Serviços: `[nome]Service.ts`