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
BEGIN
  -- Determine target companion ID safely.
  -- If logged in (linking from dashboard), force using the authenticated ID.
  -- If not logged in (immediate post-signup), safely use the provided UUID.
  IF auth.uid() IS NOT NULL THEN
    v_target_id := auth.uid();
  ELSE
    v_target_id := p_user_id;
  END IF;

  -- Failsafe check
  IF v_target_id IS NULL THEN
     RETURN false;
  END IF;

  -- 1. Find the patient with the matching code
  SELECT id INTO v_patient_id
  FROM patients
  WHERE companion_code = p_code
  LIMIT 1;

  -- 2. If no patient exists with this code, return false
  IF v_patient_id IS NULL THEN
    RETURN false;
  END IF;

  -- 3. Insert or update the link in the companions table
  INSERT INTO companions (id, linked_patient_id)
  VALUES (v_target_id, v_patient_id)
  ON CONFLICT (id) DO UPDATE 
  SET linked_patient_id = EXCLUDED.linked_patient_id;

  RETURN true;
END;
$$;

-- Grant execution permission to both authenticated AND anonymous users
-- (Anonymous is required for the immediate post-signup step if email confirmations are enabled)
GRANT EXECUTE ON FUNCTION public.link_companion_to_patient(text, uuid) TO authenticated, anon;
