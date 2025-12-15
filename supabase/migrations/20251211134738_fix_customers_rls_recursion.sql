/*
  # Fix RLS Recursion in customers table

  ## Problem
  The existing policies on customers table query user_profiles which can cause
  recursion issues. We need to use the helper function instead.

  ## Changes
  - Update all customers policies to use get_user_role() function
  - This prevents recursion and improves performance
*/

-- Drop existing policies that query user_profiles directly
DROP POLICY IF EXISTS "Managers can view assigned users customers" ON customers;
DROP POLICY IF EXISTS "Admins can view all customers" ON customers;
DROP POLICY IF EXISTS "Admins can update any customer" ON customers;
DROP POLICY IF EXISTS "Admins can delete any customer" ON customers;

-- Recreate policies using the helper function
CREATE POLICY "Managers can view assigned users customers"
  ON customers FOR SELECT
  TO authenticated
  USING (
    public.get_user_role(auth.uid()) = 'manager'
    AND EXISTS (
      SELECT 1 FROM manager_assignments ma
      WHERE ma.manager_id = auth.uid()
      AND ma.user_id = customers.user_id
    )
  );

CREATE POLICY "Admins can view all customers"
  ON customers FOR SELECT
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Admins can update any customer"
  ON customers FOR UPDATE
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');

CREATE POLICY "Admins can delete any customer"
  ON customers FOR DELETE
  TO authenticated
  USING (public.get_user_role(auth.uid()) = 'admin');
