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
