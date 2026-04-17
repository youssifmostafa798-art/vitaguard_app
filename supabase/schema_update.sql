-- Update patient_xray_results table to include model metadata
ALTER TABLE patient_xray_results 
ADD COLUMN IF NOT EXISTS model_version TEXT DEFAULT 'v1.0.0',
ADD COLUMN IF NOT EXISTS inference_source TEXT DEFAULT 'supabase_edge';

-- Ensure storage buckets exist
-- Note: In a real Supabase environment, these are usually created via the Dashboard 
-- or a separate storage setup script. Using storage.buckets table insertion as a baseline.
INSERT INTO storage.buckets (id, name, public) 
VALUES ('xray-images', 'xray-images', false)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public) 
VALUES ('ai-models', 'ai-models', false)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies for xray-images (matching existing patterns)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'xray images read'
    ) THEN
        create policy "xray images read"
          on storage.objects for select
          using (
            bucket_id = 'xray-images'
            and (
              public.is_owner(split_part(name, '/', 1)::uuid)
              or public.assigned_doctor(split_part(name, '/', 1)::uuid)
              or public.linked_companion(split_part(name, '/', 1)::uuid)
              or public.is_admin()
            )
          );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'xray images write'
    ) THEN
        create policy "xray images write"
          on storage.objects for insert
          with check (
            bucket_id = 'xray-images'
            and public.is_owner(split_part(name, '/', 1)::uuid)
          );
    END IF;
END
$$;
