import {
  bigint,
  date,
  index,
  integer,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
  vector,
} from 'drizzle-orm/pg-core';

/**
 * Um documento do corpus = um parágrafo de uma empresa em um trimestre.
 *
 * As colunas espelham `DocumentoFinal` de `packages/corpus` (os JSONs em
 * `packages/corpus/data/documentos/`), mais o embedding do parágrafo.
 * `receitaMesmoTrimestreAnoAnterior` fica de fora: só serve para montar o texto
 * do parágrafo, que já chega pronto.
 */
export const documentos = pgTable(
  'documentos',
  {
    id: integer('id').primaryKey().generatedAlwaysAsIdentity(),

    // Metadados obrigatórios em todo documento (ver CLAUDE.md, "O corpus").
    ticker: text('ticker').notNull(),
    companyName: text('company_name').notNull(),
    setor: text('setor').notNull(),
    period: text('period').notNull(), // ex.: "3T25"
    periodEnd: date('period_end', { mode: 'string' }).notNull(), // ex.: "2025-09-30"
    sourceUrl: text('source_url').notNull(),
    fetchedAt: timestamp('fetched_at', { withTimezone: true, mode: 'string' }).notNull(),

    // Indicadores em reais (a conversão de milhares já aconteceu na normalização).
    // bigint porque receita e ativo de empresas grandes passam de 2^31.
    // mode 'number' é seguro: o maior valor do corpus está na casa de 10^12,
    // bem abaixo de Number.MAX_SAFE_INTEGER (~9 × 10^15).
    receitaLiquida: bigint('receita_liquida', { mode: 'number' }).notNull(),
    lucroBruto: bigint('lucro_bruto', { mode: 'number' }).notNull(),
    lucroLiquido: bigint('lucro_liquido', { mode: 'number' }).notNull(),
    ativoTotal: bigint('ativo_total', { mode: 'number' }).notNull(),
    patrimonioLiquido: bigint('patrimonio_liquido', { mode: 'number' }).notNull(),
    caixaOperacional: bigint('caixa_operacional', { mode: 'number' }).notNull(),

    // Texto que vira embedding e que o nó `answer` cita.
    paragraph: text('paragraph').notNull(),

    // gemini-embedding-001 com outputDimensionality = 768.
    // Trocar o modelo ou a dimensão invalida o índice inteiro: o seed roda de novo do zero.
    embedding: vector('embedding', { dimensions: 768 }).notNull(),
  },
  (table) => [
    // Uma empresa tem no máximo um documento por trimestre — é o que torna o seed idempotente.
    uniqueIndex('documentos_ticker_period_idx').on(table.ticker, table.period),

    // Busca por similaridade de cosseno. HNSW dispensa treino prévio (ao contrário do
    // IVFFlat), então o índice pode ser criado com a tabela ainda vazia.
    index('documentos_embedding_hnsw_idx').using('hnsw', table.embedding.op('vector_cosine_ops')),
  ],
);
