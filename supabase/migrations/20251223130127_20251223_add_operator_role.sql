/*
  # Add Operator Role Support

  ## Overview
  Updates the user_profiles role check constraint to include 'operator' role.

  ## Changes
  - Drop existing role check constraint
  - Add new constraint allowing: user, operator, manager, admin
  - Update existing users to use 'operator' role instead of 'user'
*/

-- Drop existing constraint
ALTER TABLE user_profiles DROP CONSTRAINT IF EXISTS user_profiles_role_check;

-- Add new constraint with operator role
ALTER TABLE user_profiles 
ADD CONSTRAINT user_profiles_role_check 
CHECK (role IN ('user', 'operator', 'manager', 'admin'));

-- Update any existing 'user' roles to 'operator' (if desired)
-- Keeping this commented out to preserve existing data
-- UPDATE user_profiles SET role = 'operator' WHERE role = 'user';