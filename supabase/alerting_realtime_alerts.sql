-- Alerting migration: Supabase-only realtime alert fan-out for VitaGuard

alter table public.patient_live_vitals
  add column if not exists source_event_id text;

create unique index if not exists idx_patient_live_vitals_patient_source_event
  on public.patient_live_vitals (patient_id, source_event_id)
  where source_event_id is not null;

alter table public.medical_alerts
  add column if not exists severity text,
  add column if not exists source text,
  add column if not exists metrics text[],
  add column if not exists message text,
  add column if not exists payload jsonb,
  add column if not exists dedupe_key text,
  add column if not exists occurred_at timestamptz,
  add column if not exists last_seen_at timestamptz,
  add column if not exists acknowledged_at timestamptz,
  add column if not exists resolved_at timestamptz,
  add column if not exists source_event_id text;

alter table public.medical_alerts
  alter column severity set default 'warning',
  alter column source set default 'hardware',
  alter column metrics set default '{}'::text[],
  alter column payload set default '{}'::jsonb,
  alter column occurred_at set default now(),
  alter column last_seen_at set default now();

update public.medical_alerts
set
  severity = coalesce(
    severity,
    case
      when coalesce(alert_type, '') in (
        'FALL_DETECTED',
        'EMERGENCY_BUTTON',
        'EMERGENCY_NO_PULSE',
        'LOW_OXYGEN_CRITICAL',
        'RESPIRATORY_CARDIAC_RISK',
        'HIGH_FEVER_CRITICAL'
      ) then 'critical'
      else 'warning'
    end
  ),
  source = coalesce(source, 'hardware'),
  metrics = coalesce(metrics, '{}'::text[]),
  message = coalesce(
    message,
    nullif(replace(initcap(replace(coalesce(alert_type, 'Alert'), '_', ' ')), '  ', ' '), '')
  ),
  payload = coalesce(payload, alert_data, '{}'::jsonb),
  occurred_at = coalesce(occurred_at, created_at, now()),
  last_seen_at = coalesce(last_seen_at, created_at, now()),
  resolved_at = case
    when is_resolved = true and resolved_at is null then created_at
    else resolved_at
  end
where true;

create index if not exists idx_medical_alerts_patient_timeline
  on public.medical_alerts (patient_id, is_resolved, occurred_at desc);

create index if not exists idx_medical_alerts_patient_dedupe
  on public.medical_alerts (patient_id, dedupe_key, is_resolved);

create table if not exists public.medical_alert_deliveries (
  id uuid primary key default gen_random_uuid(),
  alert_id uuid not null references public.medical_alerts(id) on delete cascade,
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  recipient_role text not null,
  delivery_status text not null default 'pending',
  delivered_at timestamptz,
  acknowledged_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint medical_alert_deliveries_unique_recipient unique (
    alert_id,
    recipient_user_id,
    recipient_role
  )
);

create index if not exists idx_medical_alert_deliveries_recipient
  on public.medical_alert_deliveries (recipient_user_id, created_at desc);

alter table public.medical_alert_deliveries enable row level security;

drop policy if exists "medical alert deliveries read" on public.medical_alert_deliveries;
create policy "medical alert deliveries read"
on public.medical_alert_deliveries
for select
using (
  recipient_user_id = auth.uid()
  or public.is_admin()
);

drop policy if exists "medical alert deliveries write" on public.medical_alert_deliveries;
create policy "medical alert deliveries write"
on public.medical_alert_deliveries
for insert
with check (
  auth.role() = 'service_role'
  or public.is_admin()
);

drop policy if exists "medical alert deliveries update" on public.medical_alert_deliveries;
create policy "medical alert deliveries update"
on public.medical_alert_deliveries
for update
using (
  recipient_user_id = auth.uid()
  or public.is_admin()
)
with check (
  recipient_user_id = auth.uid()
  or public.is_admin()
);

create or replace function public.alert_topic_patient_id(topic text)
returns uuid
language plpgsql
stable
as $$
declare
  candidate text;
begin
  candidate := split_part(topic, ':', 2);
  if candidate is null or btrim(candidate) = '' then
    return null;
  end if;
  return candidate::uuid;
exception
  when others then
    return null;
end;
$$;

create or replace function public.can_receive_medical_alert_broadcast()
returns boolean
language sql
stable
security definer
set search_path = public, realtime
as $$
  select case
    when realtime.topic() like 'patient:%:companion-alerts'
      then (
        public.linked_companion(public.alert_topic_patient_id(realtime.topic()))
        or public.is_admin()
      )
    when realtime.topic() like 'patient:%:doctor-critical-alerts'
      then (
        public.assigned_doctor(public.alert_topic_patient_id(realtime.topic()))
        or public.is_admin()
      )
    else false
  end;
$$;

drop policy if exists "medical alert broadcasts receive" on realtime.messages;
create policy "medical alert broadcasts receive"
on realtime.messages
for select
to authenticated
using (
  realtime.messages.extension = 'broadcast'
  and public.can_receive_medical_alert_broadcast()
);

create or replace function public.broadcast_medical_alert_changes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  patient_name text;
  base_payload jsonb;
  occurred_iso text;
begin
  select coalesce(pr.name, 'Unknown')
    into patient_name
  from public.patients pt
  join public.profiles pr
    on pr.id = pt.id
  where pt.id = new.patient_id;

  occurred_iso := to_jsonb(new.occurred_at)::text;

  base_payload := jsonb_build_object(
    'id', new.id,
    'patientId', new.patient_id,
    'patientName', coalesce(patient_name, 'Unknown'),
    'alertType', new.alert_type,
    'severity', new.severity,
    'metrics', to_jsonb(coalesce(new.metrics, '{}'::text[])),
    'message', coalesce(new.message, 'Alert'),
    'source', coalesce(new.source, 'hardware'),
    'occurredAt', trim(both '"' from occurred_iso),
    'lastSeenAt', trim(both '"' from to_jsonb(new.last_seen_at)::text),
    'payload', coalesce(new.payload, '{}'::jsonb),
    'dedupeKey', new.dedupe_key,
    'isAcknowledged', (new.acknowledged_at is not null),
    'isResolved', coalesce(new.is_resolved, false),
    'acknowledgedAt', case
      when new.acknowledged_at is null then null
      else trim(both '"' from to_jsonb(new.acknowledged_at)::text)
    end,
    'resolvedAt', case
      when new.resolved_at is null then null
      else trim(both '"' from to_jsonb(new.resolved_at)::text)
    end
  );

  perform realtime.send(
    base_payload || jsonb_build_object('recipientRole', 'companion'),
    'alert.changed',
    format('patient:%s:companion-alerts', new.patient_id),
    true
  );

  if new.severity = 'critical' then
    perform realtime.send(
      base_payload || jsonb_build_object('recipientRole', 'doctor'),
      'alert.changed',
      format('patient:%s:doctor-critical-alerts', new.patient_id),
      true
    );
  end if;

  return null;
end;
$$;

drop trigger if exists trg_broadcast_medical_alert_changes on public.medical_alerts;
create trigger trg_broadcast_medical_alert_changes
after insert or update of severity, metrics, message, payload, acknowledged_at, resolved_at, is_resolved
on public.medical_alerts
for each row
execute function public.broadcast_medical_alert_changes();

create or replace function public.acknowledge_medical_alert(p_alert_id uuid)
returns public.medical_alerts
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_alert public.medical_alerts;
begin
  if not exists (
    select 1
    from public.medical_alerts
    where id = p_alert_id
      and (
        public.linked_companion(patient_id)
        or public.assigned_doctor(patient_id)
        or public.is_admin()
      )
  ) then
    raise exception 'Alert not found or access denied.';
  end if;

  update public.medical_alerts
  set
    acknowledged_at = coalesce(acknowledged_at, now()),
    resolved_at = coalesce(resolved_at, now()),
    is_resolved = true
  where id = p_alert_id
  returning * into updated_alert;

  update public.medical_alert_deliveries
  set
    delivery_status = 'acknowledged',
    delivered_at = coalesce(delivered_at, now()),
    acknowledged_at = coalesce(acknowledged_at, now()),
    updated_at = now()
  where alert_id = p_alert_id
    and recipient_user_id = auth.uid();

  return updated_alert;
end;
$$;

grant execute on function public.acknowledge_medical_alert(uuid) to authenticated;
