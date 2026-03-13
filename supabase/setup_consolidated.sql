-- ==========================================
-- 1. Schema (Tables, Indexes, Extensions)
-- ==========================================
create extension if not exists "pgcrypto";

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role text not null,
  name text,
  email text,
  phone text,
  is_active boolean default true,
  is_verified boolean default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists doctors (
  id uuid primary key references profiles(id) on delete cascade,
  gender text,
  age int,
  professional_id text,
  verification_status text default 'pending',
  id_card_path text,
  reviewed_by uuid references profiles(id),
  reviewed_at timestamptz
);

create table if not exists patients (
  id uuid primary key references profiles(id) on delete cascade,
  gender text,
  age int,
  companion_code text unique,
  assigned_doctor_id uuid references doctors(id)
);

create table if not exists companions (
  id uuid primary key references profiles(id) on delete cascade,
  linked_patient_id uuid references patients(id)
);

create table if not exists facilities (
  id uuid primary key references profiles(id) on delete cascade,
  address text,
  facility_type text,
  verification_status text default 'pending',
  record_path text,
  reviewed_by uuid references profiles(id),
  reviewed_at timestamptz
);

create table if not exists patient_medical_history (
  patient_id uuid primary key references patients(id) on delete cascade,
  allergies text,
  medications text,
  chronic_diseases text,
  surgeries text,
  notes text,
  updated_at timestamptz default now()
);

create table if not exists patient_daily_reports (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id) on delete cascade,
  report_date timestamptz,
  heart_rate numeric,
  oxygen_level numeric,
  temperature numeric,
  blood_pressure text,
  tasks_activities text,
  notes text,
  created_at timestamptz default now()
);

create table if not exists patient_xray_results (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id) on delete cascade,
  is_valid boolean,
  prediction text,
  confidence numeric,
  report_text text,
  image_path text,
  created_at timestamptz default now()
);

create table if not exists patient_documents (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id) on delete cascade,
  file_path text,
  document_type text,
  original_filename text,
  uploaded_at timestamptz default now()
);

create table if not exists medical_feedback (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id) on delete cascade,
  doctor_id uuid references doctors(id) on delete cascade,
  xray_result_id uuid references patient_xray_results(id),
  feedback_text text,
  created_at timestamptz default now()
);

create table if not exists facility_tests (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid references facilities(id) on delete cascade,
  patient_id uuid references patients(id),
  test_type text,
  file_path text,
  notes text,
  created_at timestamptz default now()
);

create table if not exists facility_offers (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid references facilities(id) on delete cascade,
  title text,
  description text,
  image_path text,
  is_active boolean default true,
  created_at timestamptz default now()
);

create table if not exists facility_appointments (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid references facilities(id) on delete cascade,
  patient_id uuid references patients(id),
  scheduled_at timestamptz,
  created_at timestamptz default now()
);

create table if not exists conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  last_message text,
  last_message_at timestamptz
);

create table if not exists conversation_participants (
  conversation_id uuid references conversations(id) on delete cascade,
  user_id uuid references profiles(id) on delete cascade,
  primary key (conversation_id, user_id)
);

create table if not exists messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid references conversations(id) on delete cascade,
  sender_id uuid references profiles(id) on delete cascade,
  content text,
  is_read boolean default false,
  created_at timestamptz default now()
);

create index if not exists idx_patients_assigned_doctor on patients (assigned_doctor_id);
create unique index if not exists idx_patients_companion_code on patients (companion_code);
create index if not exists idx_messages_conversation on messages (conversation_id, created_at);
create index if not exists idx_conversation_participants_user on conversation_participants (user_id);
create index if not exists idx_facility_offers_facility on facility_offers (facility_id, created_at);

-- ==========================================
-- 2. Storage Buckets Setup
-- ==========================================
insert into storage.buckets (id, name, public)
values 
  ('doctor-verifications', 'doctor-verifications', false),
  ('facility-records', 'facility-records', false),
  ('medical-records', 'medical-records', false),
  ('xray-results', 'xray-results', false),
  ('lab-reports', 'lab-reports', false),
  ('lab-offers', 'lab-offers', true)
on conflict (id) do nothing;

-- ==========================================
-- 3. Row Level Security (RLS) Policies
-- ==========================================
alter table profiles enable row level security;
alter table patients enable row level security;
alter table doctors enable row level security;
alter table companions enable row level security;
alter table facilities enable row level security;
alter table patient_medical_history enable row level security;
alter table patient_daily_reports enable row level security;
alter table patient_xray_results enable row level security;
alter table patient_documents enable row level security;
alter table medical_feedback enable row level security;
alter table facility_tests enable row level security;
alter table facility_offers enable row level security;
alter table facility_appointments enable row level security;
alter table conversations enable row level security;
alter table conversation_participants enable row level security;
alter table messages enable row level security;

-- NOTE: RLS on storage.objects is usually managed by Supabase. 
-- If the line below fails, it can be skipped as Supabase often enables it by default.
-- alter table storage.objects enable row level security;

-- Helper Functions
create or replace function public.is_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from profiles
    where id = auth.uid()
      and role = 'admin'
  );
$$;

create or replace function public.is_owner(target_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select auth.uid() = target_id;
$$;

create or replace function public.assigned_doctor(patient_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from patients
    where id = patient_id
      and assigned_doctor_id = auth.uid()
  );
$$;

create or replace function public.linked_companion(patient_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from companions
    where id = auth.uid()
      and linked_patient_id = patient_id
  );
$$;

-- Table Policies
create policy "profiles read own or admin" on profiles for select using (public.is_owner(id) or public.is_admin());
create policy "profiles insert self" on profiles for insert with check (public.is_owner(id));
create policy "profiles update self" on profiles for update using (public.is_owner(id) or public.is_admin());

create policy "patients read" on patients for select using (public.is_owner(id) or public.assigned_doctor(id) or public.linked_companion(id) or public.is_admin());
create policy "patients write" on patients for insert with check (public.is_owner(id));
create policy "patients update" on patients for update using (public.is_owner(id) or public.is_admin());

create policy "doctors read" on doctors for select using (public.is_owner(id) or public.is_admin());
create policy "doctors write" on doctors for insert with check (public.is_owner(id));
create policy "doctors update" on doctors for update using (public.is_admin() or public.is_owner(id));

create policy "companions read" on companions for select using (public.is_owner(id) or public.is_admin());
create policy "companions write" on companions for insert with check (public.is_owner(id));
create policy "companions update" on companions for update using (public.is_owner(id) or public.is_admin());

create policy "facilities read" on facilities for select using (public.is_owner(id) or public.is_admin());
create policy "facilities write" on facilities for insert with check (public.is_owner(id));
create policy "facilities update" on facilities for update using (public.is_admin() or public.is_owner(id));

create policy "patient medical history read" on patient_medical_history for select using (public.is_owner(patient_id) or public.assigned_doctor(patient_id) or public.linked_companion(patient_id) or public.is_admin());
create policy "patient medical history write" on patient_medical_history for insert with check (public.is_owner(patient_id) or public.is_admin());
create policy "patient medical history update" on patient_medical_history for update using (public.is_owner(patient_id) or public.is_admin());

create policy "patient daily reports read" on patient_daily_reports for select using (public.is_owner(patient_id) or public.assigned_doctor(patient_id) or public.linked_companion(patient_id) or public.is_admin());
create policy "patient daily reports write" on patient_daily_reports for insert with check (public.is_owner(patient_id) or public.is_admin());
create policy "patient daily reports update" on patient_daily_reports for update using (public.is_owner(patient_id) or public.is_admin());

create policy "patient xray read" on patient_xray_results for select using (public.is_owner(patient_id) or public.assigned_doctor(patient_id) or public.linked_companion(patient_id) or public.is_admin());
create policy "patient xray write" on patient_xray_results for insert with check (public.is_owner(patient_id) or public.is_admin());

create policy "patient documents read" on patient_documents for select using (public.is_owner(patient_id) or public.assigned_doctor(patient_id) or public.linked_companion(patient_id) or public.is_admin());
create policy "patient documents write" on patient_documents for insert with check (public.is_owner(patient_id) or public.is_admin());

create policy "medical feedback read" on medical_feedback for select using (public.is_owner(patient_id) or public.assigned_doctor(patient_id) or public.is_admin());
create policy "medical feedback create" on medical_feedback for insert with check (public.assigned_doctor(patient_id) or public.is_admin());

create policy "facility tests read" on facility_tests for select using (public.is_owner(facility_id) or public.is_admin());
create policy "facility tests write" on facility_tests for insert with check (public.is_owner(facility_id) or public.is_admin());

create policy "facility offers read" on facility_offers for select using (true);
create policy "facility offers write" on facility_offers for insert with check (public.is_owner(facility_id) or public.is_admin());
create policy "facility offers update" on facility_offers for update using (public.is_owner(facility_id) or public.is_admin());

create policy "facility appointments read" on facility_appointments for select using (public.is_owner(facility_id) or public.is_admin());
create policy "facility appointments write" on facility_appointments for insert with check (public.is_owner(facility_id) or public.is_admin());

create policy "conversation participants read" on conversation_participants for select using (public.is_owner(user_id) or public.is_admin());
create policy "conversation participants write" on conversation_participants for insert with check (public.is_owner(user_id) or public.is_admin());

create policy "conversations read" on conversations for select using (exists (select 1 from conversation_participants cp where cp.conversation_id = conversations.id and cp.user_id = auth.uid()));
create policy "conversations write" on conversations for insert with check (true);

create policy "messages read" on messages for select using (exists (select 1 from conversation_participants cp where cp.conversation_id = messages.conversation_id and cp.user_id = auth.uid()));
create policy "messages write" on messages for insert with check (exists (select 1 from conversation_participants cp where cp.conversation_id = messages.conversation_id and cp.user_id = auth.uid()));

-- Storage Policies
create policy "doctor verification read" on storage.objects for select using (bucket_id = 'doctor-verifications' and (public.is_admin() or public.is_owner(split_part(name, '/', 1)::uuid)));
create policy "doctor verification write" on storage.objects for insert with check (bucket_id = 'doctor-verifications' and public.is_owner(split_part(name, '/', 1)::uuid));

create policy "facility records read" on storage.objects for select using (bucket_id = 'facility-records' and (public.is_admin() or public.is_owner(split_part(name, '/', 1)::uuid)));
create policy "facility records write" on storage.objects for insert with check (bucket_id = 'facility-records' and public.is_owner(split_part(name, '/', 1)::uuid));

create policy "medical records read" on storage.objects for select using (bucket_id = 'medical-records' and (public.is_owner(split_part(name, '/', 1)::uuid) or public.assigned_doctor(split_part(name, '/', 1)::uuid) or public.linked_companion(split_part(name, '/', 1)::uuid) or public.is_admin()));
create policy "medical records write" on storage.objects for insert with check (bucket_id = 'medical-records' and public.is_owner(split_part(name, '/', 1)::uuid));

create policy "xray results read" on storage.objects for select using (bucket_id = 'xray-results' and (public.is_owner(split_part(name, '/', 1)::uuid) or public.assigned_doctor(split_part(name, '/', 1)::uuid) or public.linked_companion(split_part(name, '/', 1)::uuid) or public.is_admin()));
create policy "xray results write" on storage.objects for insert with check (bucket_id = 'xray-results' and public.is_owner(split_part(name, '/', 1)::uuid));

create policy "lab reports read" on storage.objects for select using (bucket_id = 'lab-reports' and (public.is_owner(split_part(name, '/', 1)::uuid) or public.is_admin()));
create policy "lab reports write" on storage.objects for insert with check (bucket_id = 'lab-reports' and public.is_owner(split_part(name, '/', 1)::uuid));

create policy "lab offers read" on storage.objects for select using (bucket_id = 'lab-offers');
create policy "lab offers write" on storage.objects for insert with check (bucket_id = 'lab-offers' and public.is_owner(split_part(name, '/', 1)::uuid));
