-- ============================================================================
-- Schema do banco de dados do "Diário de Trade" (Supabase / PostgreSQL)
-- ----------------------------------------------------------------------------
-- Execute este script no SQL Editor do seu projeto Supabase:
--   Dashboard -> SQL Editor -> New query -> cole e clique em "Run".
-- ============================================================================

-- Tabela principal que armazena o resultado (ganho/prejuízo) de cada dia.
create table if not exists public.trades (
    -- Identificador único do registro.
    id uuid primary key default gen_random_uuid(),

    -- Dono do registro. Referencia o usuário autenticado (auth.users).
    -- ON DELETE CASCADE: se o usuário for removido, seus trades também são.
    user_id uuid not null references auth.users (id) on delete cascade,

    -- Data do resultado (somente a data, sem hora).
    trade_date date not null,

    -- Valor do dia: positivo = ganho, negativo = prejuízo.
    amount numeric(14, 2) not null,

    -- Anotação opcional sobre o dia.
    note text,

    -- Data de criação do registro (auditoria).
    created_at timestamptz not null default now(),

    -- Garante apenas um registro por usuário por dia (permite upsert).
    unique (user_id, trade_date)
);

-- Índice para acelerar as consultas por usuário e intervalo de datas,
-- usadas tanto no calendário quanto nos relatórios por período.
create index if not exists idx_trades_user_date
    on public.trades (user_id, trade_date);

-- ----------------------------------------------------------------------------
-- Row Level Security (RLS): garante que cada usuário só acesse seus dados.
-- ----------------------------------------------------------------------------
alter table public.trades enable row level security;

-- Política de SELECT: usuário lê apenas os próprios registros.
drop policy if exists "trades_select_own" on public.trades;
create policy "trades_select_own"
    on public.trades for select
    using (auth.uid() = user_id);

-- Política de INSERT: usuário só insere registros em seu próprio nome.
drop policy if exists "trades_insert_own" on public.trades;
create policy "trades_insert_own"
    on public.trades for insert
    with check (auth.uid() = user_id);

-- Política de UPDATE: usuário só atualiza seus próprios registros.
drop policy if exists "trades_update_own" on public.trades;
create policy "trades_update_own"
    on public.trades for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

-- Política de DELETE: usuário só apaga seus próprios registros.
drop policy if exists "trades_delete_own" on public.trades;
create policy "trades_delete_own"
    on public.trades for delete
    using (auth.uid() = user_id);
