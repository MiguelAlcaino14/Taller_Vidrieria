/*
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