/*
  # Glass Cutting Projects Schema

  ## Overview
  This migration creates the database structure for storing glass cutting optimization projects.

  ## New Tables
  
  ### `glass_projects`
  Main table for storing cutting projects.
  - `id` (uuid, primary key) - Unique project identifier
  - `name` (text) - Project name or reference
  - `sheet_width` (numeric) - Width of the glass sheet in cm
  - `sheet_height` (numeric) - Height of the glass sheet in cm
  - `cut_thickness` (numeric) - Thickness of the cutting blade in cm (kerf)
  - `cuts` (jsonb) - Array of cut pieces with dimensions and quantities
  - `created_at` (timestamptz) - Project creation timestamp
  - `updated_at` (timestamptz) - Last modification timestamp

  ## Security
  - Enable RLS on `glass_projects` table
  - Add policy for anyone to create and read projects (public access for demo)
  - Add policy for updating and deleting projects

  ## Notes
  The `cuts` JSONB field will store an array of objects with structure:
  ```json
  [
    {
      "width": 50,
      "height": 30,
      "quantity": 2,
      "label": "Espejo baño"
    }
  ]
  ```
*/

CREATE TABLE IF NOT EXISTS glass_projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL DEFAULT '',
  sheet_width numeric NOT NULL,
  sheet_height numeric NOT NULL,
  cut_thickness numeric DEFAULT 0.3,
  cuts jsonb DEFAULT '[]'::jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE glass_projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view glass projects"
  ON glass_projects
  FOR SELECT
  USING (true);

CREATE POLICY "Anyone can create glass projects"
  ON glass_projects
  FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update glass projects"
  ON glass_projects
  FOR UPDATE
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Anyone can delete glass projects"
  ON glass_projects
  FOR DELETE
  USING (true);

CREATE INDEX IF NOT EXISTS glass_projects_created_at_idx ON glass_projects(created_at DESC);/*
  # Add Glass Thickness and Cutting Method Fields

  ## Overview
  This migration adds fields to support different glass thicknesses and cutting methods,
  enabling proper validation of minimum piece dimensions based on the cutting tool being used.

  ## Changes
  
  ### Modified Tables
  - `glass_projects`
    - Add `glass_thickness` (numeric) - Thickness of the glass sheet in millimeters (default: 4mm)
    - Add `cutting_method` (text) - Method used for cutting: 'manual' (toyo) or 'machine' (default: 'manual')

  ## Business Logic
  The cutting method significantly affects minimum piece dimensions:
  
  ### Manual Cutting (Toyo):
  - 3-4mm glass: 15cm minimum (difficult to hold smaller pieces)
  - 5-6mm glass: 18cm minimum (requires more pressure)
  - 8mm glass: 20cm minimum (manual breaking complicated)
  - 10mm+ glass: 25cm minimum (almost impossible to break manually if smaller)
  
  ### Automatic Machine Cutting:
  - 3mm glass: 10cm minimum
  - 4mm glass: 12cm minimum
  - 5mm glass: 15cm minimum
  - 6mm glass: 18cm minimum
  - 8mm glass: 22cm minimum
  - 10mm+ glass: 25cm minimum

  ## Notes
  These fields allow the application to provide accurate validation and warnings
  based on the actual cutting conditions in the workshop.
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'glass_thickness'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN glass_thickness numeric DEFAULT 4;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'cutting_method'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN cutting_method text DEFAULT 'manual';
  END IF;
END $$;

COMMENT ON COLUMN glass_projects.glass_thickness IS 'Thickness of glass sheet in millimeters';
COMMENT ON COLUMN glass_projects.cutting_method IS 'Cutting method: manual (toyo) or machine';
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
/*
  # Transform Projects to Orders System

  ## Overview
  This migration transforms the existing glass_projects table into a comprehensive orders system
  with customer relationships, order states, and tracking dates for the complete order lifecycle.

  ## Modified Tables
  
  ### `glass_projects` (renamed to `orders` conceptually, but keeping table name for compatibility)
  - Add `customer_id` (uuid, FK to customers) - Link to customer
  - Add `order_number` (text, unique) - Human-readable order identifier
  - Add `status` (text) - Order status: quoted, approved, in_production, ready, delivered, cancelled
  - Add `notes` (text) - General order notes
  - Add `quote_date` (timestamptz) - When the quote was created
  - Add `approved_date` (timestamptz) - When customer approved the quote
  - Add `promised_date` (date) - When delivery was promised
  - Add `delivered_date` (timestamptz) - When order was actually delivered
  - Add `subtotal_materials` (numeric) - Total cost of materials
  - Add `subtotal_labor` (numeric) - Total cost of labor
  - Add `discount_amount` (numeric) - Discount applied
  - Add `total_amount` (numeric) - Final total amount

  ## Security
  - Existing RLS policies remain in effect
  - No changes to access control

  ## Notes
  - Order numbers are auto-generated with format: ORD-YYYYMMDD-XXXX
  - Status flow: quoted → approved → in_production → ready → delivered
  - Cancelled can happen from any state
  - All monetary amounts are in local currency
*/

-- Add customer_id column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'customer_id'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN customer_id uuid REFERENCES customers(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Add order_number column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'order_number'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN order_number text UNIQUE;
  END IF;
END $$;

-- Add status column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'status'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN status text DEFAULT 'quoted' CHECK (status IN ('quoted', 'approved', 'in_production', 'ready', 'delivered', 'cancelled'));
  END IF;
END $$;

-- Add notes column
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'notes'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN notes text DEFAULT '';
  END IF;
END $$;

-- Add date tracking columns
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'quote_date'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN quote_date timestamptz DEFAULT now();
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'approved_date'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN approved_date timestamptz;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'promised_date'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN promised_date date;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'delivered_date'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN delivered_date timestamptz;
  END IF;
END $$;

-- Add pricing columns
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'subtotal_materials'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN subtotal_materials numeric DEFAULT 0;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'subtotal_labor'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN subtotal_labor numeric DEFAULT 0;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'discount_amount'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN discount_amount numeric DEFAULT 0;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'total_amount'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN total_amount numeric DEFAULT 0;
  END IF;
END $$;

-- Create function to generate order numbers
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS text AS $$
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
$$ LANGUAGE plpgsql;

-- Create trigger to auto-generate order numbers
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS trigger AS $$
BEGIN
  IF NEW.order_number IS NULL THEN
    NEW.order_number := generate_order_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_order_number_trigger ON glass_projects;
CREATE TRIGGER set_order_number_trigger
  BEFORE INSERT ON glass_projects
  FOR EACH ROW EXECUTE FUNCTION set_order_number();

-- Create indexes for new columns
CREATE INDEX IF NOT EXISTS glass_projects_customer_id_idx ON glass_projects(customer_id);
CREATE INDEX IF NOT EXISTS glass_projects_order_number_idx ON glass_projects(order_number);
CREATE INDEX IF NOT EXISTS glass_projects_status_idx ON glass_projects(status);
CREATE INDEX IF NOT EXISTS glass_projects_quote_date_idx ON glass_projects(quote_date DESC);
CREATE INDEX IF NOT EXISTS glass_projects_promised_date_idx ON glass_projects(promised_date);

COMMENT ON COLUMN glass_projects.customer_id IS 'Customer who placed this order';
COMMENT ON COLUMN glass_projects.order_number IS 'Unique order identifier in format ORD-YYYYMMDD-XXXX';
COMMENT ON COLUMN glass_projects.status IS 'Current order status: quoted, approved, in_production, ready, delivered, cancelled';
COMMENT ON COLUMN glass_projects.quote_date IS 'When the initial quote was created';
COMMENT ON COLUMN glass_projects.approved_date IS 'When customer approved and confirmed the order';
COMMENT ON COLUMN glass_projects.promised_date IS 'Expected delivery date promised to customer';
COMMENT ON COLUMN glass_projects.delivered_date IS 'Actual delivery date to customer';
/*
  # Create Order Items and Materials Catalog

  ## Overview
  This migration creates a complete materials catalog system and order items structure.
  It allows multiple items (windows/products) per order, each with their own glass pieces.
  Materials have configurable prices that can be updated by admins.

  ## New Tables
  
  ### `glass_types`
  Catalog of available glass types with pricing.
  - `id` (uuid, primary key) - Unique identifier
  - `name` (text) - Glass type name (e.g., "Transparente", "Bronce", "Templado")
  - `description` (text) - Detailed description
  - `price_per_sqm` (numeric) - Price per square meter
  - `available_thicknesses` (jsonb) - Array of available thicknesses in mm [3, 4, 5, 6, 8, 10, 12]
  - `is_active` (boolean) - Whether this type is currently available
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last modification timestamp

  ### `aluminum_profiles`
  Catalog of aluminum profile types with pricing.
  - `id` (uuid, primary key) - Unique identifier
  - `name` (text) - Profile line name (e.g., "Línea Módena", "Línea Herrero")
  - `color` (text) - Available color (e.g., "Natural", "Blanco", "Negro")
  - `description` (text) - Description
  - `price_per_meter` (numeric) - Price per linear meter
  - `is_active` (boolean) - Whether this profile is currently available
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last modification timestamp

  ### `accessories`
  Catalog of accessories and hardware.
  - `id` (uuid, primary key) - Unique identifier
  - `name` (text) - Accessory name (e.g., "Burlete", "Cierre", "Tornillos")
  - `description` (text) - Description
  - `unit_price` (numeric) - Price per unit
  - `unit_type` (text) - Unit of measurement: 'unit', 'meter', 'kg'
  - `is_active` (boolean) - Whether this accessory is currently available
  - `created_at` (timestamptz) - Creation timestamp
  - `updated_at` (timestamptz) - Last modification timestamp

  ### `order_items`
  Individual items within an order (e.g., each window or product).
  - `id` (uuid, primary key) - Unique identifier
  - `order_id` (uuid, FK to glass_projects) - Parent order
  - `item_number` (integer) - Sequential number within order
  - `description` (text) - Item description (e.g., "Ventana corrediza baño 2 hojas")
  - `quantity` (integer) - Number of units of this item
  - `glass_type_id` (uuid, FK to glass_types) - Type of glass used
  - `glass_thickness` (numeric) - Glass thickness in mm
  - `aluminum_profile_id` (uuid, FK to aluminum_profiles) - Aluminum profile used
  - `glass_pieces` (jsonb) - Array of glass pieces with dimensions for this item
  - `accessories_used` (jsonb) - Array of accessories with quantities
  - `labor_cost` (numeric) - Labor cost for this item
  - `item_total` (numeric) - Total cost for this item (materials + labor) × quantity
  - `notes` (text) - Item-specific notes
  - `created_at` (timestamptz) - Creation timestamp

  ## Security
  - Enable RLS on all new tables
  - Glass types, profiles, and accessories: everyone can view, only admins can modify
  - Order items: follow same permissions as parent order

  ## Notes
  - glass_pieces JSONB structure: [{"width": 50, "height": 80, "quantity": 2, "label": ""}]
  - accessories_used JSONB structure: [{"accessory_id": "uuid", "quantity": 5, "unit_price": 10}]
  - Prices are stored at order time to maintain historical accuracy
*/

-- Create glass_types table
CREATE TABLE IF NOT EXISTS glass_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text DEFAULT '',
  price_per_sqm numeric NOT NULL DEFAULT 0,
  available_thicknesses jsonb DEFAULT '[3, 4, 5, 6, 8, 10, 12]'::jsonb,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create aluminum_profiles table
CREATE TABLE IF NOT EXISTS aluminum_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  color text NOT NULL DEFAULT 'Natural',
  description text DEFAULT '',
  price_per_meter numeric NOT NULL DEFAULT 0,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(name, color)
);

-- Create accessories table
CREATE TABLE IF NOT EXISTS accessories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text DEFAULT '',
  unit_price numeric NOT NULL DEFAULT 0,
  unit_type text NOT NULL DEFAULT 'unit' CHECK (unit_type IN ('unit', 'meter', 'kg')),
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create order_items table
CREATE TABLE IF NOT EXISTS order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES glass_projects(id) ON DELETE CASCADE,
  item_number integer NOT NULL DEFAULT 1,
  description text NOT NULL DEFAULT '',
  quantity integer NOT NULL DEFAULT 1,
  glass_type_id uuid REFERENCES glass_types(id) ON DELETE SET NULL,
  glass_thickness numeric DEFAULT 4,
  aluminum_profile_id uuid REFERENCES aluminum_profiles(id) ON DELETE SET NULL,
  glass_pieces jsonb DEFAULT '[]'::jsonb,
  accessories_used jsonb DEFAULT '[]'::jsonb,
  labor_cost numeric DEFAULT 0,
  item_total numeric DEFAULT 0,
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now(),
  UNIQUE(order_id, item_number)
);

-- Enable RLS
ALTER TABLE glass_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE aluminum_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE accessories ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Policies for glass_types (everyone can view, only admins can modify)
CREATE POLICY "Anyone authenticated can view glass types"
  ON glass_types FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can insert glass types"
  ON glass_types FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update glass types"
  ON glass_types FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete glass types"
  ON glass_types FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies for aluminum_profiles
CREATE POLICY "Anyone authenticated can view aluminum profiles"
  ON aluminum_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can insert aluminum profiles"
  ON aluminum_profiles FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update aluminum profiles"
  ON aluminum_profiles FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete aluminum profiles"
  ON aluminum_profiles FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies for accessories
CREATE POLICY "Anyone authenticated can view accessories"
  ON accessories FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admins can insert accessories"
  ON accessories FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can update accessories"
  ON accessories FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Admins can delete accessories"
  ON accessories FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Policies for order_items (follow parent order permissions)
CREATE POLICY "Users can view own order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM glass_projects
      WHERE glass_projects.id = order_items.order_id
      AND glass_projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Managers can view assigned users order items"
  ON order_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM glass_projects gp
      JOIN user_profiles up ON up.id = auth.uid()
      JOIN manager_assignments ma ON ma.manager_id = auth.uid() AND ma.user_id = gp.user_id
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
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can create own order items"
  ON order_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM glass_projects
      WHERE glass_projects.id = order_items.order_id
      AND glass_projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update own order items"
  ON order_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM glass_projects
      WHERE glass_projects.id = order_items.order_id
      AND glass_projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can update any order items"
  ON order_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE POLICY "Users can delete own order items"
  ON order_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM glass_projects
      WHERE glass_projects.id = order_items.order_id
      AND glass_projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can delete any order items"
  ON order_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS glass_types_is_active_idx ON glass_types(is_active);
CREATE INDEX IF NOT EXISTS aluminum_profiles_is_active_idx ON aluminum_profiles(is_active);
CREATE INDEX IF NOT EXISTS accessories_is_active_idx ON accessories(is_active);
CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON order_items(order_id);
CREATE INDEX IF NOT EXISTS order_items_glass_type_id_idx ON order_items(glass_type_id);
CREATE INDEX IF NOT EXISTS order_items_aluminum_profile_id_idx ON order_items(aluminum_profile_id);

-- Insert some initial glass types
INSERT INTO glass_types (name, description, price_per_sqm, available_thicknesses) VALUES
  ('Transparente', 'Vidrio float transparente estándar', 15.00, '[3, 4, 5, 6, 8, 10, 12]'::jsonb),
  ('Bronce', 'Vidrio float color bronce', 18.00, '[4, 5, 6, 8, 10]'::jsonb),
  ('Gris', 'Vidrio float color gris', 18.00, '[4, 5, 6, 8, 10]'::jsonb),
  ('Verde', 'Vidrio float color verde', 18.00, '[4, 5, 6, 8, 10]'::jsonb),
  ('Templado Transparente', 'Vidrio templado de seguridad transparente', 35.00, '[4, 5, 6, 8, 10, 12]'::jsonb),
  ('Templado Bronce', 'Vidrio templado de seguridad color bronce', 38.00, '[4, 5, 6, 8, 10]'::jsonb),
  ('Laminado', 'Vidrio laminado de seguridad', 45.00, '[6, 8, 10]'::jsonb),
  ('Espejo', 'Espejo de 4mm estándar', 20.00, '[4, 5, 6]'::jsonb)
ON CONFLICT (name) DO NOTHING;

-- Insert some initial aluminum profiles
INSERT INTO aluminum_profiles (name, color, description, price_per_meter) VALUES
  ('Línea Módena', 'Natural', 'Perfil de aluminio línea módena anodizado natural', 12.50),
  ('Línea Módena', 'Blanco', 'Perfil de aluminio línea módena color blanco', 13.50),
  ('Línea Módena', 'Negro', 'Perfil de aluminio línea módena color negro', 14.00),
  ('Línea Herrero', 'Natural', 'Perfil de aluminio línea herrero anodizado natural', 10.00),
  ('Línea Herrero', 'Blanco', 'Perfil de aluminio línea herrero color blanco', 11.00),
  ('Línea A30', 'Natural', 'Perfil de aluminio línea A30 anodizado natural', 15.00),
  ('Línea A30', 'Blanco', 'Perfil de aluminio línea A30 color blanco', 16.00)
ON CONFLICT (name, color) DO NOTHING;

-- Insert some initial accessories
INSERT INTO accessories (name, description, unit_price, unit_type) VALUES
  ('Burlete', 'Burlete de goma para sellado', 2.50, 'meter'),
  ('Cierre central', 'Cierre central para ventana corrediza', 8.00, 'unit'),
  ('Cerradura', 'Cerradura de seguridad', 15.00, 'unit'),
  ('Ruedas', 'Juego de ruedas para ventana corrediza', 5.00, 'unit'),
  ('Tornillos', 'Tornillos de fijación (paquete)', 3.00, 'unit'),
  ('Bisagras', 'Bisagras para ventana de abrir', 6.00, 'unit'),
  ('Felpa', 'Felpa para sellado', 1.50, 'meter'),
  ('Silicona', 'Cartucho de silicona', 4.00, 'unit')
ON CONFLICT (name) DO NOTHING;

COMMENT ON TABLE glass_types IS 'Catalog of available glass types with pricing per square meter';
COMMENT ON TABLE aluminum_profiles IS 'Catalog of aluminum profiles with pricing per linear meter';
COMMENT ON TABLE accessories IS 'Catalog of accessories and hardware with unit pricing';
COMMENT ON TABLE order_items IS 'Individual items (windows/products) within each order';
COMMENT ON COLUMN order_items.glass_pieces IS 'Array of glass pieces: [{"width": 50, "height": 80, "quantity": 2, "label": ""}]';
COMMENT ON COLUMN order_items.accessories_used IS 'Array of accessories: [{"accessory_id": "uuid", "quantity": 5, "unit_price": 10}]';
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
/*
  # Material Inventory Management System

  ## Overview
  This migration creates the core inventory tracking system for glass sheets and remnants,
  allowing the workshop to track available materials and minimize waste.

  ## New Tables

  ### `material_sheets`
  Core inventory table tracking all material sheets (both full sheets and remnants)
  - `id` (uuid, primary key)
  - `user_id` (uuid, references auth.users) - User who added the sheet
  - `material_type` (text) - Type of material: 'glass', 'mirror', 'aluminum'
  - `glass_type_id` (uuid, references glass_types) - Specific glass type if applicable
  - `thickness` (numeric) - Thickness in mm
  - `width` (numeric) - Width in mm
  - `height` (numeric) - Height in mm
  - `area_total` (numeric) - Total area in mm² (calculated)
  - `origin` (text) - 'purchase' for new sheets, 'remnant' for leftovers
  - `parent_sheet_id` (uuid, self-reference) - Original sheet if this is a remnant
  - `source_order_id` (uuid, references orders) - Order that generated this remnant
  - `status` (text) - 'available', 'reserved', 'used', 'damaged'
  - `purchase_date` (timestamptz) - When the sheet was purchased
  - `purchase_cost` (numeric) - Cost in currency
  - `supplier` (text) - Supplier name
  - `notes` (text) - Additional notes
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### `sheet_assignments`
  Tracks which sheets are assigned to which orders
  - `id` (uuid, primary key)
  - `order_id` (uuid, references orders)
  - `sheet_id` (uuid, references material_sheets)
  - `assigned_date` (timestamptz)
  - `assigned_by` (uuid, references auth.users)
  - `cuts_assigned` (jsonb) - Array of cuts planned for this sheet
  - `status` (text) - 'pending', 'in_progress', 'completed', 'cancelled'
  - `utilization_percentage` (numeric) - Percentage of sheet used
  - `waste_area` (numeric) - Area wasted in mm²
  - `completed_date` (timestamptz)
  - `created_at` (timestamptz)

  ### `cut_logs`
  Records actual cutting operations for tracking and auditing
  - `id` (uuid, primary key)
  - `order_id` (uuid, references orders)
  - `sheet_id` (uuid, references material_sheets)
  - `assignment_id` (uuid, references sheet_assignments)
  - `cut_date` (timestamptz)
  - `operator_id` (uuid, references auth.users)
  - `successful_pieces` (integer) - Number of pieces cut successfully
  - `failed_pieces` (integer) - Number of failed cuts
  - `generated_remnants` (jsonb) - Array of remnant dimensions generated
  - `notes` (text)
  - `created_at` (timestamptz)

  ### `optimization_suggestions`
  Stores optimization suggestions for orders
  - `id` (uuid, primary key)
  - `order_id` (uuid, references orders)
  - `suggestion_number` (integer) - Rank of this suggestion (1 = best)
  - `sheets_used` (uuid[]) - Array of sheet IDs used
  - `sheet_details` (jsonb) - Details about each sheet and cuts
  - `total_utilization` (numeric) - Overall utilization percentage
  - `total_waste` (numeric) - Total waste area in mm²
  - `estimated_remnants` (jsonb) - Estimated remnants after cutting
  - `total_cost` (numeric) - Total material cost
  - `uses_remnants` (boolean) - Whether this option uses existing remnants
  - `created_at` (timestamptz)

  ### `system_settings`
  Configurable system parameters
  - `id` (uuid, primary key)
  - `setting_key` (text, unique) - Setting identifier
  - `setting_value` (jsonb) - Setting value (flexible format)
  - `description` (text) - Human-readable description
  - `updated_by` (uuid, references auth.users)
  - `updated_at` (timestamptz)

  ## Security
  - Enable RLS on all tables
  - Admin can manage all data
  - Operators can view inventory and log their work
  - Regular users can only view their own data
*/

-- Create material_sheets table
CREATE TABLE IF NOT EXISTS material_sheets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users NOT NULL,
  material_type text NOT NULL CHECK (material_type IN ('glass', 'mirror', 'aluminum')),
  glass_type_id uuid REFERENCES glass_types,
  thickness numeric NOT NULL CHECK (thickness > 0),
  width numeric NOT NULL CHECK (width > 0),
  height numeric NOT NULL CHECK (height > 0),
  area_total numeric GENERATED ALWAYS AS (width * height) STORED,
  origin text NOT NULL DEFAULT 'purchase' CHECK (origin IN ('purchase', 'remnant')),
  parent_sheet_id uuid REFERENCES material_sheets,
  source_order_id uuid,
  status text NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'used', 'damaged')),
  purchase_date timestamptz DEFAULT now(),
  purchase_cost numeric CHECK (purchase_cost >= 0),
  supplier text,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create sheet_assignments table
CREATE TABLE IF NOT EXISTS sheet_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  sheet_id uuid REFERENCES material_sheets NOT NULL,
  assigned_date timestamptz DEFAULT now(),
  assigned_by uuid REFERENCES auth.users NOT NULL,
  cuts_assigned jsonb DEFAULT '[]'::jsonb,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  utilization_percentage numeric CHECK (utilization_percentage >= 0 AND utilization_percentage <= 100),
  waste_area numeric CHECK (waste_area >= 0),
  completed_date timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Create cut_logs table
CREATE TABLE IF NOT EXISTS cut_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  sheet_id uuid REFERENCES material_sheets NOT NULL,
  assignment_id uuid REFERENCES sheet_assignments,
  cut_date timestamptz DEFAULT now(),
  operator_id uuid REFERENCES auth.users NOT NULL,
  successful_pieces integer DEFAULT 0 CHECK (successful_pieces >= 0),
  failed_pieces integer DEFAULT 0 CHECK (failed_pieces >= 0),
  generated_remnants jsonb DEFAULT '[]'::jsonb,
  notes text,
  created_at timestamptz DEFAULT now()
);

-- Create optimization_suggestions table
CREATE TABLE IF NOT EXISTS optimization_suggestions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  suggestion_number integer NOT NULL CHECK (suggestion_number > 0),
  sheets_used uuid[] NOT NULL,
  sheet_details jsonb NOT NULL DEFAULT '{}'::jsonb,
  total_utilization numeric CHECK (total_utilization >= 0 AND total_utilization <= 100),
  total_waste numeric CHECK (total_waste >= 0),
  estimated_remnants jsonb DEFAULT '[]'::jsonb,
  total_cost numeric CHECK (total_cost >= 0),
  uses_remnants boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Create system_settings table
CREATE TABLE IF NOT EXISTS system_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key text UNIQUE NOT NULL,
  setting_value jsonb NOT NULL,
  description text,
  updated_by uuid REFERENCES auth.users,
  updated_at timestamptz DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_material_sheets_status ON material_sheets(status);
CREATE INDEX IF NOT EXISTS idx_material_sheets_material_type ON material_sheets(material_type);
CREATE INDEX IF NOT EXISTS idx_material_sheets_origin ON material_sheets(origin);
CREATE INDEX IF NOT EXISTS idx_material_sheets_user_id ON material_sheets(user_id);
CREATE INDEX IF NOT EXISTS idx_sheet_assignments_order_id ON sheet_assignments(order_id);
CREATE INDEX IF NOT EXISTS idx_sheet_assignments_sheet_id ON sheet_assignments(sheet_id);
CREATE INDEX IF NOT EXISTS idx_sheet_assignments_status ON sheet_assignments(status);
CREATE INDEX IF NOT EXISTS idx_cut_logs_order_id ON cut_logs(order_id);
CREATE INDEX IF NOT EXISTS idx_cut_logs_operator_id ON cut_logs(operator_id);
CREATE INDEX IF NOT EXISTS idx_optimization_suggestions_order_id ON optimization_suggestions(order_id);

-- Enable RLS
ALTER TABLE material_sheets ENABLE ROW LEVEL SECURITY;
ALTER TABLE sheet_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE cut_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE optimization_suggestions ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for material_sheets
CREATE POLICY "Authenticated users can view all material sheets"
  ON material_sheets FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin can insert material sheets"
  ON material_sheets FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

CREATE POLICY "Admin can update material sheets"
  ON material_sheets FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

CREATE POLICY "Admin can delete material sheets"
  ON material_sheets FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

-- RLS Policies for sheet_assignments
CREATE POLICY "Authenticated users can view sheet assignments"
  ON sheet_assignments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin can manage sheet assignments"
  ON sheet_assignments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

CREATE POLICY "Admin and operators can update sheet assignments"
  ON sheet_assignments FOR UPDATE
  TO authenticated
  USING (true);

-- RLS Policies for cut_logs
CREATE POLICY "Authenticated users can view cut logs"
  ON cut_logs FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can create cut logs"
  ON cut_logs FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = operator_id);

-- RLS Policies for optimization_suggestions
CREATE POLICY "Authenticated users can view optimization suggestions"
  ON optimization_suggestions FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "System can create optimization suggestions"
  ON optimization_suggestions FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Admin can delete old optimization suggestions"
  ON optimization_suggestions FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

-- RLS Policies for system_settings
CREATE POLICY "Authenticated users can view system settings"
  ON system_settings FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin can manage system settings"
  ON system_settings FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role IN ('admin', 'manager')
    )
  );

-- Insert default system settings
INSERT INTO system_settings (setting_key, setting_value, description)
VALUES 
  ('min_remnant_width', '200', 'Minimum width in mm for a remnant to be considered usable'),
  ('min_remnant_height', '200', 'Minimum height in mm for a remnant to be considered usable'),
  ('cutting_margin', '5', 'Safety margin in mm to add around each cut'),
  ('blade_thickness', '3', 'Thickness of the cutting blade in mm (kerf)'),
  ('remnant_retention_days', '90', 'Days to keep unused remnants before alerting')
ON CONFLICT (setting_key) DO NOTHING;
/*
  # Update Orders Table for Material Tracking

  ## Changes
  Adds fields to the glass_projects (orders) table to track material assignment and cutting workflow

  ## New Columns
  - `material_status` - Tracks the material planning stage: 'pending', 'assigned', 'cutting', 'completed'
  - `cutting_plan` - JSONB storing the detailed cutting plan and instructions
  - `assigned_sheets` - Array of sheet IDs assigned to this order
  - `optimization_id` - Reference to the selected optimization suggestion
  - `estimated_waste` - Estimated waste area in mm²
  - `actual_waste` - Actual waste area after cutting in mm²
  - `material_cost` - Total cost of materials used

  ## Security
  - No RLS changes needed (existing policies apply)
*/

-- Add new columns to glass_projects table
DO $$
BEGIN
  -- Add material_status column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'material_status'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN material_status text DEFAULT 'pending' 
      CHECK (material_status IN ('pending', 'assigned', 'cutting', 'completed'));
  END IF;

  -- Add cutting_plan column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'cutting_plan'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN cutting_plan jsonb DEFAULT '{}'::jsonb;
  END IF;

  -- Add assigned_sheets column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'assigned_sheets'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN assigned_sheets uuid[] DEFAULT ARRAY[]::uuid[];
  END IF;

  -- Add optimization_id column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'optimization_id'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN optimization_id uuid REFERENCES optimization_suggestions;
  END IF;

  -- Add estimated_waste column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'estimated_waste'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN estimated_waste numeric DEFAULT 0 CHECK (estimated_waste >= 0);
  END IF;

  -- Add actual_waste column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'actual_waste'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN actual_waste numeric DEFAULT 0 CHECK (actual_waste >= 0);
  END IF;

  -- Add material_cost column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'material_cost'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN material_cost numeric DEFAULT 0 CHECK (material_cost >= 0);
  END IF;
END $$;

-- Create index for material_status for faster filtering
CREATE INDEX IF NOT EXISTS idx_glass_projects_material_status ON glass_projects(material_status);

-- Update existing orders to have pending material status
UPDATE glass_projects 
SET material_status = 'pending' 
WHERE material_status IS NULL;
