/*
  # Fix RLS - Step 3: Finalize Operator/Admin System

  ## Overview
  This migration completes the operator/admin system by:
  - Restricting roles to only 'operator' and 'admin'
  - Updating all RLS policies to use user_profiles.role instead of auth.users.role
  - Dropping manager_assignments table
  - Giving operators full read access to orders, customers, and inventory

  ## Key Changes
  - Operators can view and work with ALL orders
  - Operators can view ALL customers and inventory
  - Operators can create/update but not delete
  - Admins have full access to everything
  - All policies now correctly query user_profiles.role

  ## Security
  - RLS enabled on all tables
  - Policies use EXISTS() for performance
  - Only authenticated users can access data
*/

-- =====================================================
-- STEP 1: Finalize Role System
-- =====================================================

-- Update role constraint to ONLY allow 'operator' and 'admin'
ALTER TABLE user_profiles
DROP CONSTRAINT IF EXISTS user_profiles_role_check;

ALTER TABLE user_profiles
ADD CONSTRAINT user_profiles_role_check
CHECK (role IN ('operator', 'admin'));

-- Update the handle_new_user function to use 'operator' as default
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', ''),
    'operator'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop manager_assignments table (no longer needed)
DROP TABLE IF EXISTS manager_assignments CASCADE;

-- Update comments
COMMENT ON COLUMN user_profiles.role IS 'User role: operator (can view and work with all orders) or admin (full system access)';
COMMENT ON TABLE user_profiles IS 'Extended user information with simplified operator/admin role system';
COMMENT ON COLUMN glass_projects.user_id IS 'Creator of the order - all operators can view and work with all orders';

-- =====================================================
-- STEP 2: USER_PROFILES TABLE
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON user_profiles;
DROP POLICY IF EXISTS "Managers can view assigned users profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON user_profiles;

-- Create new simplified policies
CREATE POLICY "Authenticated users can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile name only"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = (SELECT role FROM user_profiles WHERE id = auth.uid())
  );

CREATE POLICY "Admins can update any profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- =====================================================
-- STEP 3: CUSTOMERS TABLE
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Authenticated users can view customers based on role" ON customers;
DROP POLICY IF EXISTS "Admins can view all customers" ON customers;
DROP POLICY IF EXISTS "Managers can view assigned users customers" ON customers;
DROP POLICY IF EXISTS "Users can view own customers" ON customers;
DROP POLICY IF EXISTS "Users can create own customers" ON customers;
DROP POLICY IF EXISTS "Users can update customers based on role" ON customers;
DROP POLICY IF EXISTS "Admins can update any customer" ON customers;
DROP POLICY IF EXISTS "Users can update own customers" ON customers;
DROP POLICY IF EXISTS "Users can delete customers based on role" ON customers;
DROP POLICY IF EXISTS "Admins can delete any customer" ON customers;
DROP POLICY IF EXISTS "Users can delete own customers" ON customers;

-- Create new policies
CREATE POLICY "Operators and admins can view all customers"
  ON customers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Operators and admins can create customers"
  ON customers FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
    AND user_id = auth.uid()
  );

CREATE POLICY "Operators and admins can update customers"
  ON customers FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Only admins can delete customers"
  ON customers FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- =====================================================
-- STEP 4: GLASS_PROJECTS (ORDERS) TABLE
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Authenticated users can view projects based on role" ON glass_projects;
DROP POLICY IF EXISTS "Users can view own projects" ON glass_projects;
DROP POLICY IF EXISTS "Managers can view assigned users projects" ON glass_projects;
DROP POLICY IF EXISTS "Admins can view all projects" ON glass_projects;
DROP POLICY IF EXISTS "Users can create own projects" ON glass_projects;
DROP POLICY IF EXISTS "Users can update projects based on role" ON glass_projects;
DROP POLICY IF EXISTS "Admins can update any project" ON glass_projects;
DROP POLICY IF EXISTS "Users can update own projects" ON glass_projects;
DROP POLICY IF EXISTS "Users can delete projects based on role" ON glass_projects;
DROP POLICY IF EXISTS "Admins can delete any project" ON glass_projects;
DROP POLICY IF EXISTS "Users can delete own projects" ON glass_projects;

-- Create new policies
CREATE POLICY "Operators and admins can view all orders"
  ON glass_projects FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Operators and admins can create orders"
  ON glass_projects FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
    AND user_id = auth.uid()
  );

CREATE POLICY "Operators and admins can update orders"
  ON glass_projects FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Only admins can delete orders"
  ON glass_projects FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- =====================================================
-- STEP 5: ORDER_ITEMS TABLE
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Authenticated users can view order items based on role" ON order_items;
DROP POLICY IF EXISTS "Admins can view all order items" ON order_items;
DROP POLICY IF EXISTS "Managers can view assigned users order items" ON order_items;
DROP POLICY IF EXISTS "Users can view own order items" ON order_items;
DROP POLICY IF EXISTS "Users can create own order items" ON order_items;
DROP POLICY IF EXISTS "Users can update order items based on role" ON order_items;
DROP POLICY IF EXISTS "Admins can update any order items" ON order_items;
DROP POLICY IF EXISTS "Users can update own order items" ON order_items;
DROP POLICY IF EXISTS "Users can delete order items based on role" ON order_items;
DROP POLICY IF EXISTS "Admins can delete any order items" ON order_items;
DROP POLICY IF EXISTS "Users can delete own order items" ON order_items;

-- Create new policies
CREATE POLICY "Operators and admins can view all order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Operators and admins can create order items"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Operators and admins can update order items"
  ON order_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Only admins can delete order items"
  ON order_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- =====================================================
-- STEP 6: MATERIAL_SHEETS (INVENTORY) TABLE
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Authenticated users can view material sheets" ON material_sheets;
DROP POLICY IF EXISTS "Admin can manage material sheets" ON material_sheets;
DROP POLICY IF EXISTS "Users can create own material sheets" ON material_sheets;
DROP POLICY IF EXISTS "Admin can update any material sheet" ON material_sheets;
DROP POLICY IF EXISTS "Users can update own material sheets" ON material_sheets;
DROP POLICY IF EXISTS "Admin can delete any material sheet" ON material_sheets;

-- Create new policies
CREATE POLICY "Operators and admins can view all material sheets"
  ON material_sheets FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Operators and admins can create material sheets"
  ON material_sheets FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
    AND user_id = auth.uid()
  );

CREATE POLICY "Operators and admins can update material sheets"
  ON material_sheets FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Only admins can delete material sheets"
  ON material_sheets FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- =====================================================
-- STEP 7: SHEET_ASSIGNMENTS TABLE
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view sheet assignments based on role" ON sheet_assignments;
DROP POLICY IF EXISTS "Admin can manage sheet assignments" ON sheet_assignments;
DROP POLICY IF EXISTS "Authenticated users can view sheet assignments" ON sheet_assignments;
DROP POLICY IF EXISTS "Admin and operators can update sheet assignments" ON sheet_assignments;
DROP POLICY IF EXISTS "Users can update sheet assignments based on role" ON sheet_assignments;

-- Create new policies
CREATE POLICY "Operators and admins can view all sheet assignments"
  ON sheet_assignments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Operators and admins can create sheet assignments"
  ON sheet_assignments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
    AND assigned_by = auth.uid()
  );

CREATE POLICY "Operators and admins can update sheet assignments"
  ON sheet_assignments FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Only admins can delete sheet assignments"
  ON sheet_assignments FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- =====================================================
-- STEP 8: CUT_LOGS TABLE
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Authenticated users can view cut logs" ON cut_logs;
DROP POLICY IF EXISTS "Operators can create cut logs" ON cut_logs;
DROP POLICY IF EXISTS "Admin can manage cut logs" ON cut_logs;

-- Create new policies
CREATE POLICY "Operators and admins can view all cut logs"
  ON cut_logs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Operators and admins can create cut logs"
  ON cut_logs FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
    AND operator_id = auth.uid()
  );

CREATE POLICY "Only admins can update cut logs"
  ON cut_logs FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

CREATE POLICY "Only admins can delete cut logs"
  ON cut_logs FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- =====================================================
-- STEP 9: OPTIMIZATION_SUGGESTIONS TABLE
-- =====================================================

-- Drop all existing policies
DROP POLICY IF EXISTS "Authenticated users can view optimization suggestions" ON optimization_suggestions;
DROP POLICY IF EXISTS "Authenticated users can create optimization suggestions" ON optimization_suggestions;
DROP POLICY IF EXISTS "Admin can manage optimization suggestions" ON optimization_suggestions;

-- Create new policies
CREATE POLICY "Operators and admins can view optimization suggestions"
  ON optimization_suggestions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Operators and admins can create optimization suggestions"
  ON optimization_suggestions FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Operators and admins can delete optimization suggestions"
  ON optimization_suggestions FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

-- =====================================================
-- STEP 10: CATALOG TABLES
-- =====================================================

-- GLASS_TYPES
DROP POLICY IF EXISTS "Anyone can view glass types" ON glass_types;
DROP POLICY IF EXISTS "Authenticated users can view glass types" ON glass_types;
DROP POLICY IF EXISTS "Admin can manage glass types" ON glass_types;
DROP POLICY IF EXISTS "Operators and admins can view glass types" ON glass_types;
DROP POLICY IF EXISTS "Only admins can manage glass types" ON glass_types;

CREATE POLICY "Operators and admins can view glass types"
  ON glass_types FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Only admins can manage glass types"
  ON glass_types FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- ALUMINUM_PROFILES
DROP POLICY IF EXISTS "Anyone can view aluminum profiles" ON aluminum_profiles;
DROP POLICY IF EXISTS "Authenticated users can view aluminum profiles" ON aluminum_profiles;
DROP POLICY IF EXISTS "Admin can manage aluminum profiles" ON aluminum_profiles;
DROP POLICY IF EXISTS "Operators and admins can view aluminum profiles" ON aluminum_profiles;
DROP POLICY IF EXISTS "Only admins can manage aluminum profiles" ON aluminum_profiles;

CREATE POLICY "Operators and admins can view aluminum profiles"
  ON aluminum_profiles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Only admins can manage aluminum profiles"
  ON aluminum_profiles FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- ACCESSORIES
DROP POLICY IF EXISTS "Anyone can view accessories" ON accessories;
DROP POLICY IF EXISTS "Authenticated users can view accessories" ON accessories;
DROP POLICY IF EXISTS "Admin can manage accessories" ON accessories;
DROP POLICY IF EXISTS "Operators and admins can view accessories" ON accessories;
DROP POLICY IF EXISTS "Only admins can manage accessories" ON accessories;

CREATE POLICY "Operators and admins can view accessories"
  ON accessories FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Only admins can manage accessories"
  ON accessories FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- =====================================================
-- STEP 11: SYSTEM_SETTINGS TABLE
-- =====================================================

DROP POLICY IF EXISTS "Users can view system settings" ON system_settings;
DROP POLICY IF EXISTS "Authenticated users can view system settings" ON system_settings;
DROP POLICY IF EXISTS "Admin can manage system settings" ON system_settings;
DROP POLICY IF EXISTS "Operators and admins can view system settings" ON system_settings;
DROP POLICY IF EXISTS "Only admins can manage system settings" ON system_settings;

CREATE POLICY "Operators and admins can view system settings"
  ON system_settings FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role IN ('operator', 'admin')
    )
  );

CREATE POLICY "Only admins can manage system settings"
  ON system_settings FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid()
      AND role = 'admin'
    )
  );

-- =====================================================
-- STEP 12: CLEANUP
-- =====================================================

-- Remove indexes on manager_assignments (table was dropped)
DROP INDEX IF EXISTS manager_assignments_manager_id_idx;
DROP INDEX IF EXISTS manager_assignments_user_id_idx;