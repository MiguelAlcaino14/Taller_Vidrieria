/*
  # Create Customers Table

  ## Overview
  This migration creates the customers table to manage client information for the glass business.
  Customers can be individuals or companies that order windows and glass cutting services.

  ## New Tables
  
  ### `customers`
  Main table for storing customer information.
  - `id` (uuid, primary key) - Unique customer identifier
  - `user_id` (uuid, FK to user_profiles) - User who created this customer
  - `name` (text) - Customer full name or company name
  - `phone` (text) - Primary phone number
  - `email` (text) - Email address (optional)
  - `address` (text) - Physical address
  - `customer_type` (text) - Type: 'individual' or 'company'
  - `notes` (text) - Additional notes about the customer
  - `created_at` (timestamptz) - Customer creation timestamp
  - `updated_at` (timestamptz) - Last modification timestamp

  ## Security
  - Enable RLS on `customers` table
  - Users can view and manage their own customers
  - Managers can view customers from their assigned users
  - Admins can view and manage all customers

  ## Notes
  - Phone is the primary contact method (required field)
  - Email and address are optional but recommended
  - Customer type helps with reporting and categorization
*/

CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text NOT NULL,
  email text DEFAULT '',
  address text DEFAULT '',
  customer_type text NOT NULL DEFAULT 'individual' CHECK (customer_type IN ('individual', 'company')),
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

-- Policies for customers
CREATE POLICY "Users can view own customers"
  ON customers FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Managers can view assigned users customers"
  ON customers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles up
      WHERE up.id = auth.uid()
      AND up.role = 'manager'
      AND EXISTS (
        SELECT 1 FROM manager_assignments ma
        WHERE ma.manager_id = auth.uid()
        AND ma.user_id = customers.user_id
      )
    )
  );

CREATE POLICY "Admins can view all customers"
  ON customers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can create own customers"
  ON customers FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own customers"
  ON customers FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can update any customer"
  ON customers FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can delete own customers"
  ON customers FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can delete any customer"
  ON customers FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS customers_user_id_idx ON customers(user_id);
CREATE INDEX IF NOT EXISTS customers_name_idx ON customers(name);
CREATE INDEX IF NOT EXISTS customers_phone_idx ON customers(phone);
CREATE INDEX IF NOT EXISTS customers_created_at_idx ON customers(created_at DESC);

COMMENT ON TABLE customers IS 'Customer information for glass and window orders';
COMMENT ON COLUMN customers.customer_type IS 'Type of customer: individual (particular) or company (empresa)';
COMMENT ON COLUMN customers.user_id IS 'User who manages this customer (salesperson/admin)';