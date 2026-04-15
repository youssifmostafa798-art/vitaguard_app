-- Migration: Create Security Definer function to link companions by code
-- Run this in your Supabase SQL Editor (Database > SQL Editor > New Query)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.link_companion_to_patient(p_code text, p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient_id uuid;
  v_target_id uuid;
  v_user_exists boolean;
BEGIN
  -- Determine target companion ID safely.
  IF auth.uid() IS NOT NULL THEN
    v_target_id := auth.uid();
  ELSE
    v_target_id := p_user_id;
  END IF;

  IF v_target_id IS NULL THEN
     RETURN false;
  END IF;

  -- PREVENT 23503 (Foreign Key Violation)
  -- 0. Check if the v_target_id actually exists in auth.users!
  SELECT EXISTS (
    SELECT 1 FROM auth.users WHERE id = v_target_id
  ) INTO v_user_exists;

  IF NOT v_user_exists THEN
    RETURN false;
  END IF;

  -- 1. Find the patient with the matching code (Case-insensitive & trimmed)
  SELECT id INTO v_patient_id
  FROM patients
  WHERE upper(trim(companion_code)) = upper(trim(p_code))
  LIMIT 1;

  IF v_patient_id IS NULL THEN
    RETURN false;
  END IF;

  -- 2. Auto-repair missing profile (if the trigger failed or during legacy sync)
  INSERT INTO profiles (id, role, name, is_active)
  VALUES (v_target_id, 'companion', 'Companion User', true)
  ON CONFLICT (id) DO NOTHING;

  -- 3. Insert or update the link in the companions table
  INSERT INTO companions (id, linked_patient_id)
  VALUES (v_target_id, v_patient_id)
  ON CONFLICT (id) DO UPDATE 
  SET linked_patient_id = EXCLUDED.linked_patient_id;

  RETURN true;
END;
$$;

GRANT EXECUTE ON FUNCTION public.link_companion_to_patient(text, uuid) TO authenticated, anon;
