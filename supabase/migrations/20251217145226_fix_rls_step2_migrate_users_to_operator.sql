/*
  # Fix RLS - Step 2: Migrate Users to Operator Role

  ## Overview
  Migrate existing 'user' and 'manager' roles to 'operator'.

  ## Changes
  - Convert all 'user' roles to 'operator'
  - Convert all 'manager' roles to 'operator'
  - Keep 'admin' unchanged
*/

-- Migrate existing users to operator role
UPDATE user_profiles
SET role = 'operator', updated_at = now()
WHERE role IN ('user', 'manager');