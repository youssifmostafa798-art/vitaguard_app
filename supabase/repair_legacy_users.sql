-- ==========================================
-- REPAIR SCRIPT: Backfill Legacy Role Data
-- ==========================================
-- Run this script in the Supabase SQL Editor to fix users created 
-- before the auto-registration triggers were fully functional.

-- 1. Backfill missing Patients
insert into public.patients (id, gender, age, companion_code)
select 
  p.id, 
  'male' as gender, 
  20 as age, 
  null as companion_code
from public.profiles p
left join public.patients pat on p.id = pat.id
where p.role = 'patient' and pat.id is null;

-- 2. Backfill missing Doctors
insert into public.doctors (id, gender, age, verification_status)
select 
  p.id, 
  'male' as gender, 
  30 as age, 
  'pending' as verification_status
from public.profiles p
left join public.doctors d on p.id = d.id
where p.role = 'doctor' and d.id is null;

-- 3. Backfill missing Companions
-- Note: These will be unlinked until a patient is assigned
insert into public.companions (id)
select 
  p.id
from public.profiles p
left join public.companions c on p.id = c.id
where p.role = 'companion' and c.id is null;

-- 4. Backfill missing Facilities
insert into public.facilities (id, verification_status)
select 
  p.id, 
  'pending' as verification_status
from public.profiles p
left join public.facilities f on p.id = f.id
where p.role = 'facility' and f.id is null;

do $$
begin
  raise notice 'Backfill complete. Legacy users have been synchronized.';
end $$;
