-- VidrieriaTaller Database Schema
-- Complete schema for glass cutting management system

-- Create UUID extension if not exists
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User Profiles Table
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT,
  role TEXT NOT NULL DEFAULT 'operator' CHECK (role IN ('admin', 'operator')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);
CREATE INDEX IF NOT EXISTS idx_user_profiles_role ON user_profiles(role);

-- Customers Table
CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  contact_name TEXT,
  email TEXT,
  phone TEXT,
  address TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_customers_name ON customers(name);

-- Materials Catalog Table
CREATE TABLE IF NOT EXISTS materials_catalog (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('glass', 'mirror', 'acrylic', 'other')),
  thickness NUMERIC,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_materials_type ON materials_catalog(type);

-- Material Inventory Table
CREATE TABLE IF NOT EXISTS material_inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  material_id UUID NOT NULL REFERENCES materials_catalog(id) ON DELETE CASCADE,
  length NUMERIC NOT NULL,
  width NUMERIC NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  location TEXT,
  is_remnant BOOLEAN DEFAULT FALSE,
  parent_sheet_id UUID REFERENCES material_inventory(id),
  added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  added_by UUID REFERENCES user_profiles(id),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_material_inventory_material ON material_inventory(material_id);
CREATE INDEX IF NOT EXISTS idx_material_inventory_remnant ON material_inventory(is_remnant);

-- Orders Table
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  order_number TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_by UUID REFERENCES user_profiles(id),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);

-- Order Items Table
CREATE TABLE IF NOT EXISTS order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  width NUMERIC NOT NULL,
  height NUMERIC NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  glass_type TEXT,
  thickness NUMERIC,
  notes TEXT,
  assigned_sheet_id UUID REFERENCES material_inventory(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_sheet ON order_items(assigned_sheet_id);

-- Insert default admin user (password: admin123)
INSERT INTO user_profiles (email, password_hash, full_name, role)
VALUES ('admin@vidrieriataller.com', '$2a$10$X8qJ5YXzM5h3QGzJ5YXzM.X8qJ5YXzM5h3QGzJ5YXzM5h3QGzJ5YXO', 'Administrador', 'admin')
ON CONFLICT (email) DO NOTHING;

-- Insert default operator user (password: operator123)
INSERT INTO user_profiles (email, password_hash, full_name, role)
VALUES ('operador@vidrieriataller.com', '$2a$10$Y9rK6ZYzN6i4RHaK6ZYzN.Y9rK6ZYzN6i4RHaK6ZYzN6i4RHaK6ZYP', 'Operador', 'operator')
ON CONFLICT (email) DO NOTHING;

-- Insert sample materials catalog
INSERT INTO materials_catalog (name, type, thickness, description) VALUES
  ('Vidrio Transparente 4mm', 'glass', 4, 'Vidrio float transparente estándar'),
  ('Vidrio Transparente 6mm', 'glass', 6, 'Vidrio float transparente estándar'),
  ('Espejo 4mm', 'mirror', 4, 'Espejo estándar'),
  ('Acrílico Transparente 3mm', 'acrylic', 3, 'Acrílico transparente')
ON CONFLICT DO NOTHING;

-- Insert sample inventory
INSERT INTO material_inventory (material_id, length, width, quantity, location, added_by)
SELECT
  (SELECT id FROM materials_catalog WHERE name = 'Vidrio Transparente 4mm' LIMIT 1),
  3000,
  2000,
  5,
  'Almacén Principal',
  (SELECT id FROM user_profiles WHERE role = 'admin' LIMIT 1)
WHERE EXISTS (SELECT 1 FROM materials_catalog WHERE name = 'Vidrio Transparente 4mm')
ON CONFLICT DO NOTHING;
