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

create table if not exists patients (
  id uuid primary key references profiles(id) on delete cascade,
  gender text,
  age int,
  companion_code text unique,
  assigned_doctor_id uuid references doctors(id)
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

create table if not exists patient_live_vitals (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id) on delete cascade,
  device_id text not null,
  bpm numeric,
  temperature numeric,
  spo2 numeric,
  device_status text,
  recorded_at timestamptz default now()
);

create table if not exists medical_alerts (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references patients(id) on delete cascade,
  alert_type text,
  alert_data jsonb,
  is_resolved boolean default false,
  created_at timestamptz default now()
);

create index if not exists idx_patients_assigned_doctor on patients (assigned_doctor_id);
create unique index if not exists idx_patients_companion_code on patients (companion_code);
create index if not exists idx_messages_conversation on messages (conversation_id, created_at);
create index if not exists idx_conversation_participants_user on conversation_participants (user_id);
create index if not exists idx_facility_offers_facility on facility_offers (facility_id, created_at);
create index if not exists idx_patient_live_vitals_patient on patient_live_vitals (patient_id, recorded_at desc);
create index if not exists idx_medical_alerts_patient on medical_alerts (patient_id, created_at desc);
