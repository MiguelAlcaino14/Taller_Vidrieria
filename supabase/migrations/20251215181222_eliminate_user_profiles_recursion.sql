/*
  # Eliminate User Profiles RLS Recursion Completely

  ## Problem
  The policies still query user_profiles table within user_profiles policies,
  causing infinite recursion errors.

  ## Solution
  1. Drop ALL existing policies
  2. Create a SECURITY DEFINER function that bypasses RLS completely
  3. Use ONLY this function in policies (never query user_profiles directly)
  4. Keep the "view own profile" policy simple (no subqueries)

  ## Security Note
  The SECURITY DEFINER function is safe because it only returns the role,
  and policies still enforce proper access control.
*/

-- Drop all existing policies on user_profiles
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Managers can view assigned users profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON user_profiles;

-- Drop and recreate the helper function with explicit security definer
DROP FUNCTION IF EXISTS public.get_user_role(uuid);

CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text AS $$
DECLARE
  user_role text;
BEGIN
  -- This query will NOT trigger RLS because of SECURITY DEFINER
  SELECT role INTO user_role 
  FROM public.user_profiles 
  WHERE id = user_id;
  
  RETURN COALESCE(user_role, 'user');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.get_user_role(uuid) TO authenticated;

-- Policy 1: Users can ALWAYS view their own profile (simplest possible)
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Policy 2: Admins can view all profiles (using helper function)
CREATE POLICY "Admins can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

-- Policy 3: Managers can view assigned users (using helper function)
CREATE POLICY "Managers can view assigned users profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    public.get_user_role(auth.uid()) = 'manager'
    AND EXISTS (
      SELECT 1 FROM manager_assignments ma
      WHERE ma.manager_id = auth.uid()
      AND ma.user_id = user_profiles.id
    )
  );

-- Policy 4: Users can update their own profile (no role change)
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id 
    AND role = public.get_user_role(auth.uid())
  );

-- Policy 5: Admins can update any profile (using helper function)
CREATE POLICY "Admins can update any profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

-- Add helpful comment
COMMENT ON FUNCTION public.get_user_role IS 'Returns user role with RLS bypass - used by policies to prevent recursion';
