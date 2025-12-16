/*
  # Add Thickness and Cutting Method to Projects

  ## Changes
  1. Add `glass_thickness` column to store the thickness of the glass material (e.g., 4mm, 6mm, 8mm)
  2. Add `cutting_method` column to store the cutting approach (manual or automated)
  
  ## New Columns
  - `glass_thickness` (numeric) - Thickness of the glass in mm, default 6mm
  - `cutting_method` (text) - Either 'manual' or 'automated', default 'manual'
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'glass_thickness'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN glass_thickness numeric DEFAULT 6;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'cutting_method'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN cutting_method text DEFAULT 'manual';
  END IF;
END $$;