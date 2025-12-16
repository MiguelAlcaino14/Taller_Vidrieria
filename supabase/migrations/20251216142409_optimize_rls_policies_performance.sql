/*
  # Optimize RLS Policies for Performance

  1. Performance Optimization
    - Replace direct `auth.uid()` calls with `(select auth.uid())`
    - This ensures the function is evaluated once per query instead of once per row
    - Significantly improves query performance at scale

  2. Tables Updated
    - `customers` - All policies optimized
    - `glass_projects` - All policies optimized
    - `manager_assignments` - View policy optimized
    - `order_items` - All policies optimized
    - `sheet_assignments` - All policies optimized

  3. Security
    - No changes to security logic, only performance optimization
    - All existing access controls remain intact
*/

-- Store auth.uid() in a variable for reuse across policies
-- This pattern evaluates auth.uid() once per query instead of once per row

-- =====================================================
-- CUSTOMERS TABLE POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can view customers based on role" ON customers;
DROP POLICY IF EXISTS "Users can create own customers" ON customers;
DROP POLICY IF EXISTS "Users can update customers based on role" ON customers;
DROP POLICY IF EXISTS "Users can delete customers based on role" ON customers;

CREATE POLICY "Authenticated users can view customers based on role"
  ON customers
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin can view all
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      -- User can view own
      OR user_id = (SELECT auth.uid())
      -- Manager can view assigned users' customers
      OR (
        (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'manager'
        AND user_id IN (
          SELECT user_id FROM manager_assignments 
          WHERE manager_id = (SELECT auth.uid())
        )
      )
    )
  );

CREATE POLICY "Users can create own customers"
  ON customers
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can update customers based on role"
  ON customers
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin can update any
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      -- User can update own
      OR user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      OR user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can delete customers based on role"
  ON customers
  FOR DELETE
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin can delete any
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      -- User can delete own
      OR user_id = (SELECT auth.uid())
    )
  );

-- =====================================================
-- GLASS_PROJECTS TABLE POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can view projects based on role" ON glass_projects;
DROP POLICY IF EXISTS "Users can create own projects" ON glass_projects;
DROP POLICY IF EXISTS "Users can update projects based on role" ON glass_projects;
DROP POLICY IF EXISTS "Users can delete projects based on role" ON glass_projects;

CREATE POLICY "Authenticated users can view projects based on role"
  ON glass_projects
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin can view all
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      -- User can view own
      OR user_id = (SELECT auth.uid())
      -- Manager can view assigned users' projects
      OR (
        (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'manager'
        AND user_id IN (
          SELECT user_id FROM manager_assignments 
          WHERE manager_id = (SELECT auth.uid())
        )
      )
    )
  );

CREATE POLICY "Users can create own projects"
  ON glass_projects
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = (SELECT auth.uid()));

CREATE POLICY "Users can update projects based on role"
  ON glass_projects
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin can update any
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      -- User can update own
      OR user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      OR user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can delete projects based on role"
  ON glass_projects
  FOR DELETE
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin can delete any
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      -- User can delete own
      OR user_id = (SELECT auth.uid())
    )
  );

-- =====================================================
-- MANAGER_ASSIGNMENTS TABLE POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Users can view manager assignments based on role" ON manager_assignments;

CREATE POLICY "Users can view manager assignments based on role"
  ON manager_assignments
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin can view all
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      -- Manager can view own assignments
      OR manager_id = (SELECT auth.uid())
    )
  );

-- =====================================================
-- ORDER_ITEMS TABLE POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Authenticated users can view order items based on role" ON order_items;
DROP POLICY IF EXISTS "Users can create own order items" ON order_items;
DROP POLICY IF EXISTS "Users can update order items based on role" ON order_items;
DROP POLICY IF EXISTS "Users can delete order items based on role" ON order_items;

CREATE POLICY "Authenticated users can view order items based on role"
  ON order_items
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin can view all
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      -- User can view own order items
      OR EXISTS (
        SELECT 1 FROM glass_projects 
        WHERE id = order_items.order_id 
        AND user_id = (SELECT auth.uid())
      )
      -- Manager can view assigned users' order items
      OR (
        (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'manager'
        AND EXISTS (
          SELECT 1 FROM glass_projects 
          WHERE id = order_items.order_id 
          AND user_id IN (
            SELECT user_id FROM manager_assignments 
            WHERE manager_id = (SELECT auth.uid())
          )
        )
      )
    )
  );

CREATE POLICY "Users can create own order items"
  ON order_items
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM glass_projects 
      WHERE id = order_items.order_id 
      AND user_id = (SELECT auth.uid())
    )
  );

CREATE POLICY "Users can update order items based on role"
  ON order_items
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin can update any
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      -- User can update own order items
      OR EXISTS (
        SELECT 1 FROM glass_projects 
        WHERE id = order_items.order_id 
        AND user_id = (SELECT auth.uid())
      )
    )
  )
  WITH CHECK (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      OR EXISTS (
        SELECT 1 FROM glass_projects 
        WHERE id = order_items.order_id 
        AND user_id = (SELECT auth.uid())
      )
    )
  );

CREATE POLICY "Users can delete order items based on role"
  ON order_items
  FOR DELETE
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin can delete any
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text = 'admin'
      -- User can delete own order items
      OR EXISTS (
        SELECT 1 FROM glass_projects 
        WHERE id = order_items.order_id 
        AND user_id = (SELECT auth.uid())
      )
    )
  );

-- =====================================================
-- SHEET_ASSIGNMENTS TABLE POLICIES
-- =====================================================

DROP POLICY IF EXISTS "Users can view sheet assignments based on role" ON sheet_assignments;
DROP POLICY IF EXISTS "Users can update sheet assignments based on role" ON sheet_assignments;

CREATE POLICY "Users can view sheet assignments based on role"
  ON sheet_assignments
  FOR SELECT
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (
      -- Admin and operators can view all
      (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text IN ('admin', 'operator')
      -- User can view own assignments
      OR EXISTS (
        SELECT 1 FROM glass_projects 
        WHERE id = sheet_assignments.order_id 
        AND user_id = (SELECT auth.uid())
      )
    )
  );

CREATE POLICY "Users can update sheet assignments based on role"
  ON sheet_assignments
  FOR UPDATE
  TO authenticated
  USING (
    (SELECT auth.uid()) IS NOT NULL
    AND (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text IN ('admin', 'operator')
  )
  WITH CHECK (
    (SELECT auth.uid()) IS NOT NULL
    AND (SELECT role FROM auth.users WHERE id = (SELECT auth.uid()))::text IN ('admin', 'operator')
  );
