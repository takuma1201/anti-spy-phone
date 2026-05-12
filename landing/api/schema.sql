-- Supabase で実行してください
-- Dashboard > SQL Editor に貼り付けて Run

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
