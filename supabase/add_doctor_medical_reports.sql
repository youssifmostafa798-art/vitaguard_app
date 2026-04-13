-- Migration: Add doctor_medical_reports table
-- Run this in your Supabase SQL Editor (Database > SQL Editor > New Query)
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Create the table
CREATE TABLE IF NOT EXISTS doctor_medical_reports (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id     UUID        NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
  patient_phone TEXT,
  patient_name  TEXT,
  description   TEXT,
  image_path    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable Row Level Security
ALTER TABLE doctor_medical_reports ENABLE ROW LEVEL SECURITY;

-- 3. RLS policy — doctors can only manage their own reports
CREATE POLICY "Doctors manage own medical reports"
  ON doctor_medical_reports
  FOR ALL
  USING  (auth.uid() = doctor_id)
  WITH CHECK (auth.uid() = doctor_id);

-- 4. Index for fast lookup by doctor
CREATE INDEX IF NOT EXISTS idx_doctor_medical_reports_doctor
  ON doctor_medical_reports (doctor_id, created_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- Storage bucket policy (already confirmed bucket "medical records" exists)
-- If it does NOT yet allow authenticated doctors to upload, add:
-- ─────────────────────────────────────────────────────────────────────────────

-- Allow authenticated users (doctors) to upload into the "medical records" bucket.
-- Run ONLY if the policy does not already exist:
/*
CREATE POLICY "Authenticated users can upload medical records"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'medical records');

CREATE POLICY "Authenticated users can view own medical records"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'medical records' AND auth.uid()::text = (storage.foldername(name))[1]);
*/
