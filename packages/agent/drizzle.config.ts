import { defineConfig } from 'drizzle-kit';

// `drizzle-kit generate` só compara o schema com os snapshots em `drizzle/` — não conecta no banco.
// `drizzle-kit migrate` usa DATABASE_URL: o Postgres do docker-compose localmente, ou o
// Cloud SQL via Cloud SQL Auth Proxy (TCP em 127.0.0.1). A mesma migration roda nos dois;
// só muda a URL.
export default defineConfig({
  dialect: 'postgresql',
  schema: './src/db/schema.ts',
  out: './drizzle',
  dbCredentials: {
    url: process.env.DATABASE_URL ?? '',
  },
});
