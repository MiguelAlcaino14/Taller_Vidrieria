/*
  # Fix RLS Recursion in user_profiles

  ## Problem
  The existing policies on user_profiles create infinite recursion because they query
  the user_profiles table from within the policies themselves.

  ## Solution
  1. Create a helper function that bypasses RLS to get user role
  2. Simplify policies to use this function instead of querying user_profiles
  3. This breaks the recursion cycle

  ## Changes
  - Create get_user_role() function with SECURITY DEFINER
  - Drop and recreate all user_profiles policies using the new function
  - Update dependent policies in other tables
*/

-- Create helper function to get user role without triggering RLS
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text AS $$
  SELECT role FROM public.user_profiles WHERE id = user_id;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- Drop all existing policies on user_profiles
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Managers can view assigned users profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON user_profiles;

-- Recreate policies using the helper function
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

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

CREATE POLICY "Admins can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id AND role = public.get_user_role(auth.uid()));

CREATE POLICY "Admins can update any profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

-- Update glass_projects policies to use the helper function
DROP POLICY IF EXISTS "Managers can view assigned users projects" ON glass_projects;
DROP POLICY IF EXISTS "Admins can view all projects" ON glass_projects;
DROP POLICY IF EXISTS "Admins can update any project" ON glass_projects;
DROP POLICY IF EXISTS "Admins can delete any project" ON glass_projects;

CREATE POLICY "Managers can view assigned users projects"
  ON glass_projects FOR SELECT
  TO authenticated
  USING (
    public.get_user_role(auth.uid()) = 'manager'
    AND EXISTS (
      SELECT 1 FROM manager_assignments ma
      WHERE ma.manager_id = auth.uid()
      AND ma.user_id = glass_projects.user_id
    )
  );

CREATE POLICY "Admins can view all projects"
  ON glass_projects FOR SELECT
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Admins can update any project"
  ON glass_projects FOR UPDATE
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Admins can delete any project"
  ON glass_projects FOR DELETE
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

-- Update manager_assignments policies
DROP POLICY IF EXISTS "Admins can view all assignments" ON manager_assignments;
DROP POLICY IF EXISTS "Admins can create assignments" ON manager_assignments;
DROP POLICY IF EXISTS "Admins can delete assignments" ON manager_assignments;

CREATE POLICY "Admins can view all assignments"
  ON manager_assignments FOR SELECT
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Admins can create assignments"
  ON manager_assignments FOR INSERT
  TO authenticated
  WITH CHECK (public.get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Admins can delete assignments"
  ON manager_assignments FOR DELETE
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

-- Add comment
COMMENT ON FUNCTION public.get_user_role IS 'Helper function to get user role without triggering RLS policies';
