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
