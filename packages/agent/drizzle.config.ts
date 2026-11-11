import { defineConfig } from 'drizzle-kit';

// `drizzle-kit generate` só compara o schema com os snapshots em `drizzle/` —
// não conecta no banco. A conexão (DATABASE_URL) entra quando as migrations forem aplicadas.
export default defineConfig({
  dialect: 'postgresql',
  schema: './src/db/schema.ts',
  out: './drizzle',
});
