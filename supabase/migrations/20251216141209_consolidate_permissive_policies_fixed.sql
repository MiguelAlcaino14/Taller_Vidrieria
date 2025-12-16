/*
  # Consolidate Multiple Permissive RLS Policies
  
  1. Security Improvements
    - Consolidate multiple permissive policies into single policies per action
    - Reduces complexity and improves security clarity
    - Combines role-based checks using OR conditions
  
  2. Tables Affected
    - `customers` - consolidate SELECT, UPDATE, DELETE policies
    - `glass_projects` - consolidate SELECT, UPDATE, DELETE policies
    - `manager_assignments` - consolidate SELECT policies
    - `order_items` - consolidate SELECT, UPDATE, DELETE policies
    - `sheet_assignments` - consolidate SELECT, UPDATE policies
    - `system_settings` - consolidate SELECT policies
  
  3. Policy Logic
    - Each consolidated policy checks user role and applies appropriate permissions
    - Admins have full access
    - Managers have read access to assigned users' data
    - Users have access to their own data
*/

-- =============================================
-- CUSTOMERS TABLE
-- =============================================

-- Drop existing permissive policies
DROP POLICY IF EXISTS "Admins can view all customers" ON customers;
DROP POLICY IF EXISTS "Managers can view assigned users customers" ON customers;
DROP POLICY IF EXISTS "Users can view own customers" ON customers;
DROP POLICY IF EXISTS "Admins can update any customer" ON customers;
DROP POLICY IF EXISTS "Users can update own customers" ON customers;
DROP POLICY IF EXISTS "Admins can delete any customer" ON customers;
DROP POLICY IF EXISTS "Users can delete own customers" ON customers;

-- Create consolidated policies
CREATE POLICY "Authenticated users can view customers based on role"
  ON customers FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR user_id = auth.uid()
    OR (
      (SELECT role FROM auth.users WHERE id = auth.uid()) = 'manager'
      AND user_id IN (SELECT user_id FROM manager_assignments WHERE manager_id = auth.uid())
    )
  );

CREATE POLICY "Users can update customers based on role"
  ON customers FOR UPDATE
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR user_id = auth.uid()
  )
  WITH CHECK (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR user_id = auth.uid()
  );

CREATE POLICY "Users can delete customers based on role"
  ON customers FOR DELETE
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR user_id = auth.uid()
  );

-- =============================================
-- GLASS PROJECTS TABLE
-- =============================================

-- Drop existing permissive policies
DROP POLICY IF EXISTS "Admins can view all projects" ON glass_projects;
DROP POLICY IF EXISTS "Managers can view assigned users projects" ON glass_projects;
DROP POLICY IF EXISTS "Users can view own projects" ON glass_projects;
DROP POLICY IF EXISTS "Admins can update any project" ON glass_projects;
DROP POLICY IF EXISTS "Users can update own projects" ON glass_projects;
DROP POLICY IF EXISTS "Admins can delete any project" ON glass_projects;
DROP POLICY IF EXISTS "Users can delete own projects" ON glass_projects;

-- Create consolidated policies
CREATE POLICY "Authenticated users can view projects based on role"
  ON glass_projects FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR user_id = auth.uid()
    OR (
      (SELECT role FROM auth.users WHERE id = auth.uid()) = 'manager'
      AND user_id IN (SELECT user_id FROM manager_assignments WHERE manager_id = auth.uid())
    )
  );

CREATE POLICY "Users can update projects based on role"
  ON glass_projects FOR UPDATE
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR user_id = auth.uid()
  )
  WITH CHECK (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR user_id = auth.uid()
  );

CREATE POLICY "Users can delete projects based on role"
  ON glass_projects FOR DELETE
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR user_id = auth.uid()
  );

-- =============================================
-- MANAGER ASSIGNMENTS TABLE
-- =============================================

-- Drop existing permissive policies
DROP POLICY IF EXISTS "Admins can view all assignments" ON manager_assignments;
DROP POLICY IF EXISTS "Managers can view own assignments" ON manager_assignments;

-- Create consolidated policy
CREATE POLICY "Users can view manager assignments based on role"
  ON manager_assignments FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR manager_id = auth.uid()
  );

-- =============================================
-- ORDER ITEMS TABLE
-- =============================================

-- Drop existing permissive policies
DROP POLICY IF EXISTS "Admins can view all order items" ON order_items;
DROP POLICY IF EXISTS "Managers can view assigned users order items" ON order_items;
DROP POLICY IF EXISTS "Users can view own order items" ON order_items;
DROP POLICY IF EXISTS "Admins can update any order items" ON order_items;
DROP POLICY IF EXISTS "Users can update own order items" ON order_items;
DROP POLICY IF EXISTS "Admins can delete any order items" ON order_items;
DROP POLICY IF EXISTS "Users can delete own order items" ON order_items;

-- Create consolidated policies
CREATE POLICY "Authenticated users can view order items based on role"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR EXISTS (
      SELECT 1 FROM glass_projects 
      WHERE glass_projects.id = order_items.order_id 
      AND glass_projects.user_id = auth.uid()
    )
    OR (
      (SELECT role FROM auth.users WHERE id = auth.uid()) = 'manager'
      AND EXISTS (
        SELECT 1 FROM glass_projects 
        WHERE glass_projects.id = order_items.order_id 
        AND glass_projects.user_id IN (SELECT user_id FROM manager_assignments WHERE manager_id = auth.uid())
      )
    )
  );

CREATE POLICY "Users can update order items based on role"
  ON order_items FOR UPDATE
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR EXISTS (
      SELECT 1 FROM glass_projects 
      WHERE glass_projects.id = order_items.order_id 
      AND glass_projects.user_id = auth.uid()
    )
  )
  WITH CHECK (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR EXISTS (
      SELECT 1 FROM glass_projects 
      WHERE glass_projects.id = order_items.order_id 
      AND glass_projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete order items based on role"
  ON order_items FOR DELETE
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) = 'admin'
    OR EXISTS (
      SELECT 1 FROM glass_projects 
      WHERE glass_projects.id = order_items.order_id 
      AND glass_projects.user_id = auth.uid()
    )
  );

-- =============================================
-- SHEET ASSIGNMENTS TABLE
-- =============================================

-- Drop existing permissive policies
DROP POLICY IF EXISTS "Admin can manage sheet assignments" ON sheet_assignments;
DROP POLICY IF EXISTS "Authenticated users can view sheet assignments" ON sheet_assignments;
DROP POLICY IF EXISTS "Admin and operators can update sheet assignments" ON sheet_assignments;

-- Create consolidated policies
CREATE POLICY "Users can view sheet assignments based on role"
  ON sheet_assignments FOR SELECT
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) IN ('admin', 'operator')
    OR EXISTS (
      SELECT 1 FROM glass_projects 
      WHERE glass_projects.id = sheet_assignments.order_id 
      AND glass_projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update sheet assignments based on role"
  ON sheet_assignments FOR UPDATE
  TO authenticated
  USING (
    (SELECT role FROM auth.users WHERE id = auth.uid()) IN ('admin', 'operator')
  )
  WITH CHECK (
    (SELECT role FROM auth.users WHERE id = auth.uid()) IN ('admin', 'operator')
  );

-- =============================================
-- SYSTEM SETTINGS TABLE
-- =============================================

-- Drop existing permissive policies
DROP POLICY IF EXISTS "Admin can manage system settings" ON system_settings;
DROP POLICY IF EXISTS "Authenticated users can view system settings" ON system_settings;

-- Create consolidated policy
CREATE POLICY "Users can view system settings"
  ON system_settings FOR SELECT
  TO authenticated
  USING (true);