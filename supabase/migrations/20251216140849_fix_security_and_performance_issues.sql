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
