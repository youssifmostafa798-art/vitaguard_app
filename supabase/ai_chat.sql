create table if not exists ai_conversations (
  id uuid primary key default gen_random_uuid(),
  owner_user_id uuid not null references profiles(id),
  role text not null check (role in ('patient', 'companion', 'doctor')),
  context_patient_id uuid references patients(id),
  title text,
  last_message text,
  last_message_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (owner_user_id)
);

create table if not exists ai_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references ai_conversations(id) on delete cascade,
  owner_user_id uuid not null references profiles(id),
  role text not null check (role in ('user', 'assistant', 'system')),
  content text not null,
  status text not null default 'complete' check (status in ('streaming', 'complete', 'error')),
  provider text,
  model text,
  error_message text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_ai_messages_conversation_created_at
  on ai_messages (conversation_id, created_at);

create index if not exists idx_ai_messages_owner_created_at_desc
  on ai_messages (owner_user_id, created_at desc);

create index if not exists idx_ai_conversations_context_patient_id
  on ai_conversations (context_patient_id);

alter table ai_conversations enable row level security;
alter table ai_messages enable row level security;

drop policy if exists "ai conversations read own" on ai_conversations;
create policy "ai conversations read own"
  on ai_conversations for select
  using ((select auth.uid()) = owner_user_id);

drop policy if exists "ai conversations insert own" on ai_conversations;
create policy "ai conversations insert own"
  on ai_conversations for insert
  with check ((select auth.uid()) = owner_user_id);

drop policy if exists "ai conversations update own" on ai_conversations;
create policy "ai conversations update own"
  on ai_conversations for update
  using ((select auth.uid()) = owner_user_id)
  with check ((select auth.uid()) = owner_user_id);

drop policy if exists "ai messages read own" on ai_messages;
create policy "ai messages read own"
  on ai_messages for select
  using ((select auth.uid()) = owner_user_id);

drop policy if exists "ai messages insert own" on ai_messages;
create policy "ai messages insert own"
  on ai_messages for insert
  with check ((select auth.uid()) = owner_user_id);

drop policy if exists "ai messages update own" on ai_messages;
create policy "ai messages update own"
  on ai_messages for update
  using ((select auth.uid()) = owner_user_id)
  with check ((select auth.uid()) = owner_user_id);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'ai_messages'
  ) then
    alter publication supabase_realtime add table ai_messages;
  end if;
exception
  when undefined_object then null;
end $$;
