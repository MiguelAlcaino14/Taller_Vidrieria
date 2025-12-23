/*
  # Fix All Remaining Security and Performance Issues

  ## Overview
  This migration addresses all remaining security warnings and performance issues:

  1. **RLS Performance Optimization**
     - Replace `auth.uid()` with `(select auth.uid())` in all remaining policies
     - This prevents re-evaluation for each row, improving query performance

  2. **Remove Unused Indexes**
     - Drop all indexes that are not being used to improve write performance

  3. **Fix Function Search Paths**
     - Update functions to have immutable search paths for security

  4. **Note on Multiple Permissive Policies**
     - Multiple permissive policies are intentional for role-based access control
     - These implement admin/manager/user hierarchy and work as designed
*/

-- =====================================================
-- 1. FIX RLS PERFORMANCE ISSUES
-- =====================================================

-- Manager Assignments
DROP POLICY IF EXISTS "Managers can view own assignments" ON manager_assignments;
CREATE POLICY "Managers can view own assignments"
  ON manager_assignments FOR SELECT
  TO authenticated
  USING (manager_id = (select auth.uid()));

-- Glass Projects (already fixed in previous migration, but ensuring consistency)
DROP POLICY IF EXISTS "Users can view own projects" ON glass_projects;
DROP POLICY IF EXISTS "Users can create own projects" ON glass_projects;
DROP POLICY IF EXISTS "Users can update own projects" ON glass_projects;
DROP POLICY IF EXISTS "Users can delete own projects" ON glass_projects;

CREATE POLICY "Users can view own projects"
  ON glass_projects FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));

CREATE POLICY "Users can create own projects"
  ON glass_projects FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Users can update own projects"
  ON glass_projects FOR UPDATE
  TO authenticated
  USING (user_id = (select auth.uid()))
  WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Users can delete own projects"
  ON glass_projects FOR DELETE
  TO authenticated
  USING (user_id = (select auth.uid()));

-- Customers
DROP POLICY IF EXISTS "Users can view own customers" ON customers;
DROP POLICY IF EXISTS "Users can create own customers" ON customers;
DROP POLICY IF EXISTS "Users can update own customers" ON customers;
DROP POLICY IF EXISTS "Users can delete own customers" ON customers;

CREATE POLICY "Users can view own customers"
  ON customers FOR SELECT
  TO authenticated
  USING (user_id = (select auth.uid()));

CREATE POLICY "Users can create own customers"
  ON customers FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Users can update own customers"
  ON customers FOR UPDATE
  TO authenticated
  USING (user_id = (select auth.uid()))
  WITH CHECK (user_id = (select auth.uid()));

CREATE POLICY "Users can delete own customers"
  ON customers FOR DELETE
  TO authenticated
  USING (user_id = (select auth.uid()));

-- Glass Types
DROP POLICY IF EXISTS "Admins can insert glass types" ON glass_types;
DROP POLICY IF EXISTS "Admins can update glass types" ON glass_types;
DROP POLICY IF EXISTS "Admins can delete glass types" ON glass_types;

CREATE POLICY "Admins can insert glass types"
  ON glass_types FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update glass types"
  ON glass_types FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete glass types"
  ON glass_types FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- Aluminum Profiles
DROP POLICY IF EXISTS "Admins can insert aluminum profiles" ON aluminum_profiles;
DROP POLICY IF EXISTS "Admins can update aluminum profiles" ON aluminum_profiles;
DROP POLICY IF EXISTS "Admins can delete aluminum profiles" ON aluminum_profiles;

CREATE POLICY "Admins can insert aluminum profiles"
  ON aluminum_profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update aluminum profiles"
  ON aluminum_profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete aluminum profiles"
  ON aluminum_profiles FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- Accessories
DROP POLICY IF EXISTS "Admins can insert accessories" ON accessories;
DROP POLICY IF EXISTS "Admins can update accessories" ON accessories;
DROP POLICY IF EXISTS "Admins can delete accessories" ON accessories;

CREATE POLICY "Admins can insert accessories"
  ON accessories FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update accessories"
  ON accessories FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete accessories"
  ON accessories FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- Order Items
DROP POLICY IF EXISTS "Users can view own order items" ON order_items;
DROP POLICY IF EXISTS "Managers can view assigned users order items" ON order_items;
DROP POLICY IF EXISTS "Admins can view all order items" ON order_items;
DROP POLICY IF EXISTS "Users can create own order items" ON order_items;
DROP POLICY IF EXISTS "Users can update own order items" ON order_items;
DROP POLICY IF EXISTS "Admins can update any order items" ON order_items;
DROP POLICY IF EXISTS "Users can delete own order items" ON order_items;
DROP POLICY IF EXISTS "Admins can delete any order items" ON order_items;

CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM glass_projects
      WHERE glass_projects.id = order_items.order_id
      AND glass_projects.user_id = (select auth.uid())
    )
  );

CREATE POLICY "Managers can view assigned users order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM glass_projects gp
      JOIN user_profiles up ON up.id = (select auth.uid())
      JOIN manager_assignments ma ON ma.manager_id = (select auth.uid()) AND ma.user_id = gp.user_id
      WHERE gp.id = order_items.order_id
      AND up.role = 'manager'
    )
  );

CREATE POLICY "Admins can view all order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Users can create own order items"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM glass_projects
      WHERE glass_projects.id = order_items.order_id
      AND glass_projects.user_id = (select auth.uid())
    )
  );

CREATE POLICY "Users can update own order items"
  ON order_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM glass_projects
      WHERE glass_projects.id = order_items.order_id
      AND glass_projects.user_id = (select auth.uid())
    )
  );

CREATE POLICY "Admins can update any order items"
  ON order_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

CREATE POLICY "Users can delete own order items"
  ON order_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM glass_projects
      WHERE glass_projects.id = order_items.order_id
      AND glass_projects.user_id = (select auth.uid())
    )
  );

CREATE POLICY "Admins can delete any order items"
  ON order_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = (select auth.uid()) AND role = 'admin'
    )
  );

-- Material Sheets
DROP POLICY IF EXISTS "Admin can insert material sheets" ON material_sheets;
DROP POLICY IF EXISTS "Admin can update material sheets" ON material_sheets;
DROP POLICY IF EXISTS "Admin can delete material sheets" ON material_sheets;

CREATE POLICY "Admin can insert material sheets"
  ON material_sheets FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

CREATE POLICY "Admin can update material sheets"
  ON material_sheets FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

CREATE POLICY "Admin can delete material sheets"
  ON material_sheets FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

-- Sheet Assignments
DROP POLICY IF EXISTS "Admin can manage sheet assignments" ON sheet_assignments;

CREATE POLICY "Admin can manage sheet assignments"
  ON sheet_assignments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

-- Cut Logs
DROP POLICY IF EXISTS "Authenticated users can create cut logs" ON cut_logs;

CREATE POLICY "Authenticated users can create cut logs"
  ON cut_logs FOR INSERT
  TO authenticated
  WITH CHECK (operator_id = (select auth.uid()));

-- Optimization Suggestions
DROP POLICY IF EXISTS "Admin can delete old optimization suggestions" ON optimization_suggestions;

CREATE POLICY "Admin can delete old optimization suggestions"
  ON optimization_suggestions FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

-- System Settings
DROP POLICY IF EXISTS "Admin can manage system settings" ON system_settings;

CREATE POLICY "Admin can manage system settings"
  ON system_settings FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = (select auth.uid())
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

-- User Profiles
DROP POLICY IF EXISTS "Admins can view all profiles" ON user_profiles;
DROP POLICY IF EXISTS "Managers can view assigned users profiles" ON user_profiles;
DROP POLICY IF EXISTS "Admins can update any profile" ON user_profiles;

CREATE POLICY "Admins can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (public.get_user_role((select auth.uid())) = 'admin');

CREATE POLICY "Managers can view assigned users profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (
    public.get_user_role((select auth.uid())) = 'manager'
    AND EXISTS (
      SELECT 1 FROM manager_assignments ma
      WHERE ma.manager_id = (select auth.uid())
      AND ma.user_id = user_profiles.id
    )
  );

CREATE POLICY "Admins can update any profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (public.get_user_role((select auth.uid())) = 'admin');

-- =====================================================
-- 2. DROP UNUSED INDEXES
-- =====================================================

DROP INDEX IF EXISTS public.glass_projects_created_at_idx;
DROP INDEX IF EXISTS public.idx_customers_user_id;
DROP INDEX IF EXISTS public.idx_cut_logs_assignment_id;
DROP INDEX IF EXISTS public.idx_cut_logs_operator_id;
DROP INDEX IF EXISTS public.idx_cut_logs_sheet_id;
DROP INDEX IF EXISTS public.idx_glass_projects_customer_id;
DROP INDEX IF EXISTS public.idx_glass_projects_optimization_id;
DROP INDEX IF EXISTS public.idx_manager_assignments_user_id;
DROP INDEX IF EXISTS public.manager_assignments_manager_id_idx;
DROP INDEX IF EXISTS public.glass_projects_user_id_idx;
DROP INDEX IF EXISTS public.customers_name_idx;
DROP INDEX IF EXISTS public.customers_created_at_idx;
DROP INDEX IF EXISTS public.idx_material_sheets_glass_type_id;
DROP INDEX IF EXISTS public.idx_material_sheets_parent_sheet_id;
DROP INDEX IF EXISTS public.idx_material_sheets_user_id;
DROP INDEX IF EXISTS public.idx_order_items_aluminum_profile_id;
DROP INDEX IF EXISTS public.idx_order_items_glass_type_id;
DROP INDEX IF EXISTS public.idx_sheet_assignments_assigned_by;
DROP INDEX IF EXISTS public.idx_sheet_assignments_sheet_id;
DROP INDEX IF EXISTS public.idx_system_settings_updated_by;

-- =====================================================
-- 3. FIX FUNCTION SEARCH PATHS
-- =====================================================

-- Fix set_order_number function
DROP FUNCTION IF EXISTS public.set_order_number() CASCADE;

CREATE OR REPLACE FUNCTION public.set_order_number()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.order_number IS NULL THEN
    NEW.order_number := generate_order_number();
  END IF;
  RETURN NEW;
END;
$$;

-- Recreate trigger
DROP TRIGGER IF EXISTS set_order_number_trigger ON glass_projects;
CREATE TRIGGER set_order_number_trigger
  BEFORE INSERT ON glass_projects
  FOR EACH ROW EXECUTE FUNCTION set_order_number();

-- Fix handle_new_user function
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
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
$$;

-- Recreate trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Fix generate_order_number function
DROP FUNCTION IF EXISTS public.generate_order_number() CASCADE;

CREATE OR REPLACE FUNCTION public.generate_order_number()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  new_number text;
  date_part text;
  sequence_num int;
BEGIN
  date_part := TO_CHAR(CURRENT_DATE, 'YYYYMMDD');
  
  SELECT COALESCE(MAX(CAST(SUBSTRING(order_number FROM 14) AS INTEGER)), 0) + 1
  INTO sequence_num
  FROM glass_projects
  WHERE order_number LIKE 'ORD-' || date_part || '-%';
  
  new_number := 'ORD-' || date_part || '-' || LPAD(sequence_num::text, 4, '0');
  
  RETURN new_number;
END;
$$;

-- =====================================================
-- NOTES
-- =====================================================

-- Multiple Permissive Policies:
-- The following tables intentionally have multiple permissive policies per action
-- to implement role-based access control (admin/manager/user hierarchy):
-- - order_items: Multiple SELECT, UPDATE, DELETE policies for role hierarchy
-- - system_settings: Multiple SELECT policies for different access levels
-- - user_profiles: Multiple SELECT, UPDATE policies for role-based viewing/editing
-- This is working as designed and provides proper access control.