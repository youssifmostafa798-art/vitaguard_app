-- Enable RLS on storage
alter table storage.objects enable row level security;

create or replace function public.bucket_path_owner(bucket text, owner_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select (
    storage.objects.bucket_id = bucket
    and split_part(storage.objects.name, '/', 1) = owner_id::text
  );
$$;

-- Doctor verification uploads
create policy "doctor verification read"
  on storage.objects for select
  using (
    bucket_id = 'doctor-verifications'
    and (public.is_admin() or public.is_owner(split_part(name, '/', 1)::uuid))
  );

create policy "doctor verification write"
  on storage.objects for insert
  with check (
    bucket_id = 'doctor-verifications'
    and public.is_owner(split_part(name, '/', 1)::uuid)
  );

-- Facility records
create policy "facility records read"
  on storage.objects for select
  using (
    bucket_id = 'facility-records'
    and (public.is_admin() or public.is_owner(split_part(name, '/', 1)::uuid))
  );

create policy "facility records write"
  on storage.objects for insert
  with check (
    bucket_id = 'facility-records'
    and public.is_owner(split_part(name, '/', 1)::uuid)
  );

-- Medical records
create policy "medical records read"
  on storage.objects for select
  using (
    bucket_id = 'medical-records'
    and (
      public.is_owner(split_part(name, '/', 1)::uuid)
      or public.assigned_doctor(split_part(name, '/', 1)::uuid)
      or public.linked_companion(split_part(name, '/', 1)::uuid)
      or public.is_admin()
    )
  );

create policy "medical records write"
  on storage.objects for insert
  with check (
    bucket_id = 'medical-records'
    and public.is_owner(split_part(name, '/', 1)::uuid)
  );

-- X-ray results
create policy "xray results read"
  on storage.objects for select
  using (
    bucket_id = 'xray-results'
    and (
      public.is_owner(split_part(name, '/', 1)::uuid)
      or public.assigned_doctor(split_part(name, '/', 1)::uuid)
      or public.linked_companion(split_part(name, '/', 1)::uuid)
      or public.is_admin()
    )
  );

create policy "xray results write"
  on storage.objects for insert
  with check (
    bucket_id = 'xray-results'
    and public.is_owner(split_part(name, '/', 1)::uuid)
  );

-- Lab reports
create policy "lab reports read"
  on storage.objects for select
  using (
    bucket_id = 'lab-reports'
    and (public.is_owner(split_part(name, '/', 1)::uuid) or public.is_admin())
  );

create policy "lab reports write"
  on storage.objects for insert
  with check (
    bucket_id = 'lab-reports'
    and public.is_owner(split_part(name, '/', 1)::uuid)
  );

-- Lab offers (public read)
create policy "lab offers read"
  on storage.objects for select
  using (bucket_id = 'lab-offers');

create policy "lab offers write"
  on storage.objects for insert
  with check (
    bucket_id = 'lab-offers'
    and public.is_owner(split_part(name, '/', 1)::uuid)
  );
