-- Supabase で実行してください
-- Dashboard > SQL Editor に貼り付けて Run

-- ── Orders (Stripe Checkout 完了後に webhook が INSERT) ──────────
create table if not exists orders (
  id                uuid        default gen_random_uuid() primary key,
  order_num         text        not null unique,
  name              text,
  email             text        not null,
  tel               text,
  address           text,
  total_jpy         integer,
  ref               text,
  stripe_session_id text        unique,
  status            text        not null default 'paid',
  created_at        timestamptz default now()
);

-- 既存テーブルに紹介コード列を追加（再実行しても安全）
alter table orders add column if not exists ref text;

create index if not exists orders_email_idx     on orders (email);
create index if not exists orders_order_num_idx on orders (order_num);
create index if not exists orders_ref_idx       on orders (ref);

alter table orders enable row level security;

-- ── Referrers (友達紹介プログラムの紹介リンク所有者) ──────────────────
-- 紹介リンク発行時に /api/referral が code→email を登録。
-- webhook は注文の ref からこの表を引いて紹介者を特定する。
create table if not exists referrers (
  id         uuid        default gen_random_uuid() primary key,
  code       text        not null unique,
  name       text,
  email      text        not null,
  created_at timestamptz default now()
);

create index if not exists referrers_code_idx on referrers (code);

alter table referrers enable row level security;

-- ── Crypto orders (BTCPay webhook upserts on invoice events) ───────
-- Idempotent: the unique btcpay_invoice_id lets the webhook upsert
-- safely on duplicate / redelivered events.
create table if not exists crypto_orders (
  id                uuid        default gen_random_uuid() primary key,
  btcpay_invoice_id text        not null unique,
  order_num         text,
  name              text,
  email             text,
  tel               text,
  address           text,
  total_jpy         integer,
  status            text        not null default 'pending',  -- pending | paid | failed
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

create index if not exists crypto_orders_order_num_idx on crypto_orders (order_num);
create index if not exists crypto_orders_email_idx     on crypto_orders (email);

alter table crypto_orders enable row level security;
-- service key bypasses RLS; the webhook writes via the service role only.

-- ── Chat leads ────────────────────────────────────────────────────
create table if not exists chat_leads (
  id         uuid        default gen_random_uuid() primary key,
  name       text        not null,
  email      text        not null,
  message    text,
  page_url   text,
  created_at timestamptz default now()
);

-- email にインデックス（重複顧客の確認に使用）
create index if not exists chat_leads_email_idx on chat_leads (email);

-- 管理画面から読める (RLS は無効のままでもOK、service key 経由のみ書き込む)
alter table chat_leads enable row level security;

-- service key は RLS をバイパスするので INSERT は常に通る
-- 管理者だけが SELECT できるポリシー（任意）
-- create policy "admin only" on chat_leads for select using (false);
