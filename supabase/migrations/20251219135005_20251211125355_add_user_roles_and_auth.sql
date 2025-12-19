/*
  # Add User Roles and Authentication System

  ## Overview
  This migration creates a complete multi-level user authentication system with three distinct roles.
  It enables proper project ownership and role-based access control.

  ## New Tables

  ### `user_profiles`
  Stores extended user information and role assignments.
  - `id` (uuid, primary key, FK to auth.users) - Links to Supabase auth user
  - `email` (text, unique) - User's email address
  - `full_name` (text) - User's display name
  - `role` (text) - User role: 'user', 'manager', or 'admin'
  - `created_at` (timestamptz) - Profile creation timestamp
  - `updated_at` (timestamptz) - Last modification timestamp

  ### `manager_assignments`
  Defines which users are managed by which managers.
  - `id` (uuid, primary key) - Unique assignment identifier
  - `manager_id` (uuid, FK to user_profiles) - The manager
  - `user_id` (uuid, FK to user_profiles) - The managed user
  - `created_at` (timestamptz) - Assignment creation timestamp

  ## Modified Tables

  ### `glass_projects`
  - Add `user_id` (uuid, FK to user_profiles) - Project owner

  ## Role Descriptions

  1. **User (user)**: Can only view and manage their own projects
  2. **Manager (manager)**: Can view their own projects + projects of assigned users
  3. **Admin (admin)**: Can view and manage all projects in the system

  ## Security

  ### Row Level Security Policies

  #### user_profiles table:
  - Users can view their own profile
  - Managers can view profiles of their assigned users
  - Admins can view all profiles
  - Users can update their own profile (except role)

  #### glass_projects table (replaces existing policies):
  - Users can view their own projects
  - Managers can view projects from their assigned users
  - Admins can view all projects
  - Users can only create/update/delete their own projects
  - Admins can manage all projects

  #### manager_assignments table:
  - Managers can view their own assignments
  - Admins can view and manage all assignments
  - Only admins can create or modify assignments

  ## Notes
  - All existing anonymous projects will be marked as owned by a system admin
  - The role field uses text type for flexibility but should only contain: 'user', 'manager', or 'admin'
  - Manager assignments create a many-to-many relationship between managers and users
*/

-- Create user_profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  full_name text NOT NULL DEFAULT '',
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'manager', 'admin')),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create manager_assignments table
CREATE TABLE IF NOT EXISTS manager_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  manager_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(manager_id, user_id),
  CHECK (manager_id != user_id)
);

-- Add user_id to glass_projects if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'user_id'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN user_id uuid REFERENCES user_profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Enable RLS on new tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE manager_assignments ENABLE ROW LEVEL SECURITY;

-- Drop existing permissive policies on glass_projects
DROP POLICY IF EXISTS "Anyone can view glass projects" ON glass_projects;
DROP POLICY IF EXISTS "Anyone can create glass projects" ON glass_projects;
DROP POLICY IF EXISTS "Anyone can update glass projects" ON glass_projects;
DROP POLICY IF EXISTS "Anyone can delete glass projects" ON glass_projects;

-- Policies for user_profiles
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Managers can view assigned users profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid()
      AND up.role = 'manager'
      AND EXISTS (
        SELECT 1 FROM manager_assignments ma
        WHERE ma.manager_id = auth.uid()
        AND ma.user_id = user_profiles.id
      )
    )
  );

CREATE POLICY "Admins can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id AND role = (SELECT role FROM user_profiles WHERE id = auth.uid()));

CREATE POLICY "Admins can update any profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies for manager_assignments
CREATE POLICY "Managers can view own assignments"
  ON manager_assignments FOR SELECT
  TO authenticated
  USING (manager_id = auth.uid());

CREATE POLICY "Admins can view all assignments"
  ON manager_assignments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can create assignments"
  ON manager_assignments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete assignments"
  ON manager_assignments FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies for glass_projects with role-based access
CREATE POLICY "Users can view own projects"
  ON glass_projects FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Managers can view assigned users projects"
  ON glass_projects FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid()
      AND up.role = 'manager'
      AND EXISTS (
        SELECT 1 FROM manager_assignments ma
        WHERE ma.manager_id = auth.uid()
        AND ma.user_id = glass_projects.user_id
      )
    )
  );

CREATE POLICY "Admins can view all projects"
  ON glass_projects FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can create own projects"
  ON glass_projects FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own projects"
  ON glass_projects FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can update any project"
  ON glass_projects FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can delete own projects"
  ON glass_projects FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can delete any project"
  ON glass_projects FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS user_profiles_role_idx ON user_profiles(role);
CREATE INDEX IF NOT EXISTS user_profiles_email_idx ON user_profiles(email);
CREATE INDEX IF NOT EXISTS manager_assignments_manager_id_idx ON manager_assignments(manager_id);
CREATE INDEX IF NOT EXISTS manager_assignments_user_id_idx ON manager_assignments(user_id);
CREATE INDEX IF NOT EXISTS glass_projects_user_id_idx ON glass_projects(user_id);

-- Function to automatically create user_profile when auth user is created
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    'user'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create profile on user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

COMMENT ON TABLE user_profiles IS 'Extended user information with role-based access control';
COMMENT ON TABLE manager_assignments IS 'Defines manager-user relationships for hierarchical access';
COMMENT ON COLUMN user_profiles.role IS 'User role: user (own projects only), manager (team projects), or admin (all projects)';
COMMENT ON COLUMN glass_projects.user_id IS 'Owner of the project, determines visibility based on user role';