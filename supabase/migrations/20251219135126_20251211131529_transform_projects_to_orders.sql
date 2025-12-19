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