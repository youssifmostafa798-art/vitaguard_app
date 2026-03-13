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

-- profiles
create policy "profiles read own or admin"
  on profiles for select
  using (public.is_owner(id) or public.is_admin());

create policy "profiles insert self"
  on profiles for insert
  with check (public.is_owner(id));

create policy "profiles update self"
  on profiles for update
  using (public.is_owner(id) or public.is_admin());

-- patients
create policy "patients read"
  on patients for select
  using (
    public.is_owner(id)
    or public.assigned_doctor(id)
    or public.linked_companion(id)
    or public.is_admin()
  );

create policy "patients write"
  on patients for insert
  with check (public.is_owner(id));

create policy "patients update"
  on patients for update
  using (public.is_owner(id) or public.is_admin());

-- doctors
create policy "doctors read"
  on doctors for select
  using (public.is_owner(id) or public.is_admin());

create policy "doctors write"
  on doctors for insert
  with check (public.is_owner(id));

create policy "doctors update"
  on doctors for update
  using (public.is_admin() or public.is_owner(id));

-- companions
create policy "companions read"
  on companions for select
  using (public.is_owner(id) or public.is_admin());

create policy "companions write"
  on companions for insert
  with check (public.is_owner(id));

create policy "companions update"
  on companions for update
  using (public.is_owner(id) or public.is_admin());

-- facilities
create policy "facilities read"
  on facilities for select
  using (public.is_owner(id) or public.is_admin());

create policy "facilities write"
  on facilities for insert
  with check (public.is_owner(id));

create policy "facilities update"
  on facilities for update
  using (public.is_admin() or public.is_owner(id));

-- patient sub tables
create policy "patient medical history read"
  on patient_medical_history for select
  using (
    public.is_owner(patient_id)
    or public.assigned_doctor(patient_id)
    or public.linked_companion(patient_id)
    or public.is_admin()
  );

create policy "patient medical history write"
  on patient_medical_history for insert
  with check (public.is_owner(patient_id) or public.is_admin());

create policy "patient medical history update"
  on patient_medical_history for update
  using (public.is_owner(patient_id) or public.is_admin());

create policy "patient daily reports read"
  on patient_daily_reports for select
  using (
    public.is_owner(patient_id)
    or public.assigned_doctor(patient_id)
    or public.linked_companion(patient_id)
    or public.is_admin()
  );

create policy "patient daily reports write"
  on patient_daily_reports for insert
  with check (public.is_owner(patient_id) or public.is_admin());

create policy "patient daily reports update"
  on patient_daily_reports for update
  using (public.is_owner(patient_id) or public.is_admin());

create policy "patient xray read"
  on patient_xray_results for select
  using (
    public.is_owner(patient_id)
    or public.assigned_doctor(patient_id)
    or public.linked_companion(patient_id)
    or public.is_admin()
  );

create policy "patient xray write"
  on patient_xray_results for insert
  with check (public.is_owner(patient_id) or public.is_admin());

create policy "patient documents read"
  on patient_documents for select
  using (
    public.is_owner(patient_id)
    or public.assigned_doctor(patient_id)
    or public.linked_companion(patient_id)
    or public.is_admin()
  );

create policy "patient documents write"
  on patient_documents for insert
  with check (public.is_owner(patient_id) or public.is_admin());

-- medical feedback
create policy "medical feedback read"
  on medical_feedback for select
  using (
    public.is_owner(patient_id)
    or public.assigned_doctor(patient_id)
    or public.is_admin()
  );

create policy "medical feedback create"
  on medical_feedback for insert
  with check (public.assigned_doctor(patient_id) or public.is_admin());

-- facility tables
create policy "facility tests read"
  on facility_tests for select
  using (public.is_owner(facility_id) or public.is_admin());

create policy "facility tests write"
  on facility_tests for insert
  with check (public.is_owner(facility_id) or public.is_admin());

create policy "facility offers read"
  on facility_offers for select
  using (true);

create policy "facility offers write"
  on facility_offers for insert
  with check (public.is_owner(facility_id) or public.is_admin());

create policy "facility offers update"
  on facility_offers for update
  using (public.is_owner(facility_id) or public.is_admin());

create policy "facility appointments read"
  on facility_appointments for select
  using (public.is_owner(facility_id) or public.is_admin());

create policy "facility appointments write"
  on facility_appointments for insert
  with check (public.is_owner(facility_id) or public.is_admin());

-- conversations
create policy "conversation participants read"
  on conversation_participants for select
  using (public.is_owner(user_id) or public.is_admin());

create policy "conversation participants write"
  on conversation_participants for insert
  with check (public.is_owner(user_id) or public.is_admin());

create policy "conversations read"
  on conversations for select
  using (
    exists (
      select 1 from conversation_participants cp
      where cp.conversation_id = conversations.id
        and cp.user_id = auth.uid()
    )
  );

create policy "conversations write"
  on conversations for insert
  with check (true);

create policy "messages read"
  on messages for select
  using (
    exists (
      select 1 from conversation_participants cp
      where cp.conversation_id = messages.conversation_id
        and cp.user_id = auth.uid()
    )
  );

create policy "messages write"
  on messages for insert
  with check (
    exists (
      select 1 from conversation_participants cp
      where cp.conversation_id = messages.conversation_id
        and cp.user_id = auth.uid()
    )
  );
