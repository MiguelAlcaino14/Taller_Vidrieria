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