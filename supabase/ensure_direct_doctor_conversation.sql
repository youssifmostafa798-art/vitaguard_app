create or replace function public.ensure_direct_doctor_conversation(doctor_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  existing_conversation_id uuid;
  new_conversation_id uuid;
begin
  if current_user_id is null then
    raise exception 'Authentication required.';
  end if;

  if doctor_id is null then
    raise exception 'doctor_id is required.';
  end if;

  if doctor_id = current_user_id then
    raise exception 'Cannot create a conversation with yourself.';
  end if;

  if not exists (
    select 1
    from profiles
    where id = doctor_id
      and role = 'doctor'
  ) then
    raise exception 'Doctor profile not found.';
  end if;

  select cp_patient.conversation_id
    into existing_conversation_id
  from conversation_participants cp_patient
  join conversation_participants cp_doctor
    on cp_doctor.conversation_id = cp_patient.conversation_id
  where cp_patient.user_id = current_user_id
    and cp_doctor.user_id = doctor_id
  limit 1;

  if existing_conversation_id is not null then
    return existing_conversation_id;
  end if;

  insert into conversations default values
  returning id into new_conversation_id;

  insert into conversation_participants (conversation_id, user_id)
  values
    (new_conversation_id, current_user_id),
    (new_conversation_id, doctor_id);

  return new_conversation_id;
end;
$$;
