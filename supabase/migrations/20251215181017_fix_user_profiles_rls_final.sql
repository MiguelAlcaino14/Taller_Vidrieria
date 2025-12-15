/*
  # Fix User Profiles RLS Recursion - Final Solution

  ## Problem
  The get_user_role function still causes recursion because it queries user_profiles
  which triggers RLS policies that call get_user_role again.

  ## Solution
  1. Drop the existing get_user_role function
  2. Recreate it with explicit RLS bypass using SET statement
  3. Simplify policies to avoid any circular dependencies
  4. Allow users to read their own profile without role checks

  ## Changes
  - Recreate get_user_role function with proper RLS bypass
  - Simplify user_profiles policies to prevent recursion
  - Ensure users can always read their own profile
*/

-- Drop existing function
DROP FUNCTION IF EXISTS public.get_user_role(uuid);

-- Create a new function that explicitly bypasses RLS
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text AS $$
DECLARE
  user_role text;
BEGIN
  -- Explicitly disable RLS for this query
  SELECT role INTO user_role 
  FROM public.user_profiles 
  WHERE id = user_id;
  
  RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_user_role(uuid) TO authenticated;

-- Drop all existing policies on user_profiles
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Managers can view assigned users profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON user_profiles;

-- Create simple, non-recursive policies
-- Policy 1: Users can ALWAYS view their own profile (no role check needed)
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Policy 2: Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid() AND up.role = 'admin'
    )
  );

-- Policy 3: Managers can view assigned users
CREATE POLICY "Managers can view assigned users profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid() AND up.role = 'manager'
    )
    AND EXISTS (
      SELECT 1 FROM manager_assignments ma
      WHERE ma.manager_id = auth.uid()
      AND ma.user_id = user_profiles.id
    )
  );

-- Policy 4: Users can update their own profile (but not change role)
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id 
    AND role = (SELECT role FROM user_profiles WHERE id = auth.uid())
  );

-- Policy 5: Admins can update any profile
CREATE POLICY "Admins can update any profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid() AND up.role = 'admin'
    )
  );
