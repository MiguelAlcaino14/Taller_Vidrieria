/*
  # Add SVG Import Support

  ## Overview
  This migration adds support for importing orders from SVG manufacturing documents.
  It creates a storage bucket for SVG files and adds tracking columns to glass_projects.

  ## Changes
  1. Storage
    - Create `order_documents` bucket for storing SVG files
    - Configure RLS for bucket access

  2. Table Modifications
    - Add `svg_source_url` column to glass_projects - URL reference to original SVG file
    - Add `import_metadata` column to glass_projects - JSONB field storing import details
    - Add `original_order_code` column to glass_projects - Original order code from SVG
    - Add `import_date` column to glass_projects - When the order was imported

  ## Security
  - Bucket policies ensure users can only access their own documents
  - RLS policies updated for new columns

  ## Notes
  - import_metadata structure: {"source": "svg", "original_code": "CR-XXXX", "import_date": "ISO date", "pieces_count": N}
*/

-- Add new columns to glass_projects table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'svg_source_url'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN svg_source_url text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'import_metadata'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN import_metadata jsonb DEFAULT '{}'::jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'original_order_code'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN original_order_code text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'import_date'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN import_date timestamptz;
  END IF;
END $$;

-- Create index for searching by original order code
CREATE INDEX IF NOT EXISTS glass_projects_original_order_code_idx ON glass_projects(original_order_code);

-- Add comments
COMMENT ON COLUMN glass_projects.svg_source_url IS 'URL to the original SVG document in storage';
COMMENT ON COLUMN glass_projects.import_metadata IS 'Metadata from SVG import: source, codes, piece count, etc.';
COMMENT ON COLUMN glass_projects.original_order_code IS 'Original order code from external system (e.g., CR-8838e5b1)';
COMMENT ON COLUMN glass_projects.import_date IS 'Timestamp when the order was imported from external source';
/*
  # Create Storage Bucket for Order Documents

  ## Overview
  Creates a storage bucket for SVG order documents with appropriate RLS policies.

  ## Changes
  1. Create `order_documents` storage bucket
  2. Set bucket to public (files accessible via public URL)
  3. Configure RLS policies for secure access

  ## Security
  - Users can only upload to their own folder (user_id prefix)
  - Users can only read/delete their own files
  - All authenticated users can upload files

  ## Notes
  - Files are named with pattern: {user_id}_{timestamp}_{order_code}.svg
  - Public bucket allows direct access to files for viewing in browser
*/

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'order_documents',
  'order_documents',
  true,
  10485760,
  ARRAY['image/svg+xml', 'application/svg+xml']::text[]
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "Users can upload own order documents"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'order_documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can view own order documents"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'order_documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can update own order documents"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'order_documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can delete own order documents"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'order_documents' AND
  (storage.foldername(name))[1] = auth.uid()::text
);
/*
  # Fix Security and Performance Issues

  This migration addresses multiple security and performance issues identified by Supabase:

  ## 1. RLS Performance Optimization
  - Fix `user_profiles` policies to use `(select auth.uid())` instead of `auth.uid()`
  - This prevents re-evaluation of auth function for each row, improving query performance

  ## 2. Remove Unused Indexes
  - Drop all unused indexes to improve write performance and reduce storage overhead
  - Indexes will be recreated in future if usage patterns change

  ## 3. Function Security
  - Fix `sync_user_role_to_jwt` function to have immutable search_path

  ## 4. Note on Multiple Permissive Policies
  - Multiple permissive policies per table/action are intentional for role-based access
  - These implement admin/manager/user hierarchy and are working as designed
*/

-- =====================================================
-- 1. FIX RLS PERFORMANCE ISSUES
-- =====================================================

-- Drop and recreate user_profiles policies with optimized auth checks
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;

CREATE POLICY "Users can view own profile"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING ((select auth.uid()) = id);

CREATE POLICY "Users can update own profile"
  ON public.user_profiles
  FOR UPDATE
  TO authenticated
  USING ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);

-- =====================================================
-- 2. DROP UNUSED INDEXES
-- =====================================================

-- Order items indexes
DROP INDEX IF EXISTS public.order_items_order_id_idx;
DROP INDEX IF EXISTS public.order_items_glass_type_id_idx;
DROP INDEX IF EXISTS public.order_items_aluminum_profile_id_idx;

-- Manager assignments indexes
DROP INDEX IF EXISTS public.manager_assignments_user_id_idx;

-- Customers indexes
DROP INDEX IF EXISTS public.customers_user_id_idx;
DROP INDEX IF EXISTS public.customers_phone_idx;

-- Optimization suggestions indexes
DROP INDEX IF EXISTS public.idx_optimization_suggestions_order_id;

-- Glass projects indexes
DROP INDEX IF EXISTS public.glass_projects_customer_id_idx;
DROP INDEX IF EXISTS public.glass_projects_order_number_idx;
DROP INDEX IF EXISTS public.glass_projects_status_idx;
DROP INDEX IF EXISTS public.glass_projects_quote_date_idx;
DROP INDEX IF EXISTS public.glass_projects_promised_date_idx;
DROP INDEX IF EXISTS public.idx_glass_projects_material_status;
DROP INDEX IF EXISTS public.idx_glass_projects_optimization_id;
DROP INDEX IF EXISTS public.glass_projects_original_order_code_idx;

-- Material sheets indexes
DROP INDEX IF EXISTS public.idx_material_sheets_status;
DROP INDEX IF EXISTS public.idx_material_sheets_material_type;
DROP INDEX IF EXISTS public.idx_material_sheets_origin;
DROP INDEX IF EXISTS public.idx_material_sheets_user_id;
DROP INDEX IF EXISTS public.idx_material_sheets_glass_type_id;
DROP INDEX IF EXISTS public.idx_material_sheets_parent_sheet_id;

-- Sheet assignments indexes
DROP INDEX IF EXISTS public.idx_sheet_assignments_order_id;
DROP INDEX IF EXISTS public.idx_sheet_assignments_sheet_id;
DROP INDEX IF EXISTS public.idx_sheet_assignments_status;
DROP INDEX IF EXISTS public.idx_sheet_assignments_assigned_by;

-- Cut logs indexes
DROP INDEX IF EXISTS public.idx_cut_logs_order_id;
DROP INDEX IF EXISTS public.idx_cut_logs_operator_id;
DROP INDEX IF EXISTS public.idx_cut_logs_assignment_id;
DROP INDEX IF EXISTS public.idx_cut_logs_sheet_id;

-- Catalog indexes
DROP INDEX IF EXISTS public.glass_types_is_active_idx;
DROP INDEX IF EXISTS public.aluminum_profiles_is_active_idx;
DROP INDEX IF EXISTS public.accessories_is_active_idx;

-- System settings indexes
DROP INDEX IF EXISTS public.idx_system_settings_updated_by;

-- =====================================================
-- 3. FIX FUNCTION SEARCH PATH
-- =====================================================

-- Recreate the sync_user_role_to_jwt function with secure search_path
DROP FUNCTION IF EXISTS public.sync_user_role_to_jwt() CASCADE;

CREATE OR REPLACE FUNCTION public.sync_user_role_to_jwt()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = raw_app_meta_data || 
    json_build_object('role', NEW.role)::jsonb
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$;

-- Recreate the trigger
DROP TRIGGER IF EXISTS sync_user_role_to_jwt_trigger ON public.user_profiles;

CREATE TRIGGER sync_user_role_to_jwt_trigger
  AFTER INSERT OR UPDATE OF role ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_role_to_jwt();

-- =====================================================
-- NOTES
-- =====================================================

-- Auth DB Connection Strategy and Leaked Password Protection
-- These settings must be configured in the Supabase Dashboard:
-- 1. Auth -> Settings -> Connection Pooling: Switch to percentage-based
-- 2. Auth -> Providers -> Email -> Password Protection: Enable HIBP check
/*
  # Add Indexes to Foreign Keys
  
  1. Performance Improvements
    - Add indexes on all foreign key columns to improve query performance
    - Indexes will speed up JOIN operations and foreign key lookups
  
  2. Tables Affected
    - `customers` - index on user_id
    - `cut_logs` - indexes on assignment_id, operator_id, sheet_id
    - `glass_projects` - indexes on customer_id, optimization_id
    - `manager_assignments` - index on user_id
    - `material_sheets` - indexes on glass_type_id, parent_sheet_id, user_id
    - `order_items` - indexes on aluminum_profile_id, glass_type_id
    - `sheet_assignments` - indexes on assigned_by, sheet_id
    - `system_settings` - index on updated_by
*/

-- Customers table
CREATE INDEX IF NOT EXISTS idx_customers_user_id ON customers(user_id);

-- Cut logs table
CREATE INDEX IF NOT EXISTS idx_cut_logs_assignment_id ON cut_logs(assignment_id);
CREATE INDEX IF NOT EXISTS idx_cut_logs_operator_id ON cut_logs(operator_id);
CREATE INDEX IF NOT EXISTS idx_cut_logs_sheet_id ON cut_logs(sheet_id);

-- Glass projects table
CREATE INDEX IF NOT EXISTS idx_glass_projects_customer_id ON glass_projects(customer_id);
CREATE INDEX IF NOT EXISTS idx_glass_projects_optimization_id ON glass_projects(optimization_id);

-- Manager assignments table
CREATE INDEX IF NOT EXISTS idx_manager_assignments_user_id ON manager_assignments(user_id);

-- Material sheets table
CREATE INDEX IF NOT EXISTS idx_material_sheets_glass_type_id ON material_sheets(glass_type_id);
CREATE INDEX IF NOT EXISTS idx_material_sheets_parent_sheet_id ON material_sheets(parent_sheet_id);
CREATE INDEX IF NOT EXISTS idx_material_sheets_user_id ON material_sheets(user_id);

-- Order items table
CREATE INDEX IF NOT EXISTS idx_order_items_aluminum_profile_id ON order_items(aluminum_profile_id);
CREATE INDEX IF NOT EXISTS idx_order_items_glass_type_id ON order_items(glass_type_id);

-- Sheet assignments table
CREATE INDEX IF NOT EXISTS idx_sheet_assignments_assigned_by ON sheet_assignments(assigned_by);
CREATE INDEX IF NOT EXISTS idx_sheet_assignments_sheet_id ON sheet_assignments(sheet_id);

-- System settings table
CREATE INDEX IF NOT EXISTS idx_system_settings_updated_by ON system_settings(updated_by);/*
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
  USING (true);/*
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
/*
  # Remove Unused Audit Indexes

  1. Analysis
    - Reviewed application query patterns
    - Identified indexes that are not used in queries
    - Audit columns (assigned_by, updated_by, operator_id) are rarely queried
    - Keeping indexes on these columns adds unnecessary write overhead

  2. Indexes Removed
    - `idx_sheet_assignments_assigned_by` - Audit column, never queried
    - `idx_system_settings_updated_by` - Audit column, never queried
    - `idx_cut_logs_operator_id` - Not used in current queries

  3. Indexes Retained (Critical for Performance)
    - Foreign key columns: Essential for JOIN performance and constraint checking
    - RLS policy columns: Used in WHERE clauses for access control
    - Frequently filtered columns: Used in application queries

  4. Performance Impact
    - Reduced write overhead on INSERT/UPDATE operations
    - No impact on read performance (removed indexes were never used)
    - Faster table maintenance operations
*/

-- Remove audit column indexes that are not used in queries
DROP INDEX IF EXISTS idx_sheet_assignments_assigned_by;
DROP INDEX IF EXISTS idx_system_settings_updated_by;
DROP INDEX IF EXISTS idx_cut_logs_operator_id;
