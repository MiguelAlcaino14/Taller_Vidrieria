/*
  # Fix RLS - Step 1: Allow Operator Role

  ## Overview
  First step: Update the constraint to allow 'operator' role so we can migrate users.

  ## Changes
  - Add 'operator' to allowed roles temporarily
  - This allows us to migrate users in the next step
*/

-- Update constraint to allow operator role
ALTER TABLE user_profiles
DROP CONSTRAINT IF EXISTS user_profiles_role_check;

ALTER TABLE user_profiles
ADD CONSTRAINT user_profiles_role_check
CHECK (role IN ('user', 'manager', 'admin', 'operator'));