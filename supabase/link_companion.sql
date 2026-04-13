-- Migration: Create Security Definer function to link companions by code
-- Run this in your Supabase SQL Editor (Database > SQL Editor > New Query)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.link_companion_to_patient(p_code text)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient_id uuid;
BEGIN
  -- 1. Find the patient with the matching code
  SELECT id INTO v_patient_id
  FROM patients
  WHERE companion_code = p_code
  LIMIT 1;

  -- 2. If no patient exists with this code, return false
  IF v_patient_id IS NULL THEN
    RETURN false;
  END IF;

  -- 3. Insert or update the link in the companions table for the calling user.
  -- The auth.uid() gives the currently authenticated companion ID.
  INSERT INTO companions (id, linked_patient_id)
  VALUES (auth.uid(), v_patient_id)
  ON CONFLICT (id) DO UPDATE 
  SET linked_patient_id = EXCLUDED.linked_patient_id;

  RETURN true;
END;
$$;

-- Grant execution permission to authenticated users
GRANT EXECUTE ON FUNCTION public.link_companion_to_patient(text) TO authenticated;
