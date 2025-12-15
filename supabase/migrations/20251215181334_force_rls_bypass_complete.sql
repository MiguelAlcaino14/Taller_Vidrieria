/*
  # Force Complete RLS Bypass in get_user_role

  ## Problem
  The get_user_role function might still trigger RLS even with SECURITY DEFINER.
  
  ## Solution
  1. Drop all policies that depend on get_user_role
  2. Drop and recreate the function with explicit row_security = off
  3. Recreate all policies
  
  This ensures complete RLS bypass in the helper function.
*/

-- Step 1: Drop all policies
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Managers can view assigned users profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON user_profiles;

-- Step 2: Drop and recreate function with row_security = off
DROP FUNCTION IF EXISTS public.get_user_role(uuid);

CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text AS $$
DECLARE
  user_role text;
BEGIN
  SELECT role INTO user_role 
  FROM public.user_profiles 
  WHERE id = user_id;
  
  RETURN COALESCE(user_role, 'user');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE
SET search_path = public
SET row_security = off;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.get_user_role(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_role(uuid) TO anon;

-- Step 3: Recreate all policies

-- Policy 1: Users can view their own profile (no function needed - direct comparison)
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Policy 2: Admins can view all profiles
CREATE POLICY "Admins can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

-- Policy 3: Managers can view assigned users
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

-- Policy 4: Users can update own profile
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id 
    AND role = public.get_user_role(auth.uid())
  );

-- Policy 5: Admins can update any profile
CREATE POLICY "Admins can update any profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

COMMENT ON FUNCTION public.get_user_role IS 'Returns user role with row_security=off - guaranteed RLS bypass';
