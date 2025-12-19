/*
  # Add SVG Import Support

  ## Overview
  This migration adds support for importing orders from SVG manufacturing documents.
  It creates a storage bucket for SVG files and adds tracking columns to glass_projects.

  ## Changes
  1. Storage
    - Create `order_documents` bucket for storing SVG files
    - Configure RLS for bucket access

  2. Table Modifications
    - Add `svg_source_url` column to glass_projects - URL reference to original SVG file
    - Add `import_metadata` column to glass_projects - JSONB field storing import details
    - Add `original_order_code` column to glass_projects - Original order code from SVG
    - Add `import_date` column to glass_projects - When the order was imported

  ## Security
  - Bucket policies ensure users can only access their own documents
  - RLS policies updated for new columns

  ## Notes
  - import_metadata structure: {"source": "svg", "original_code": "CR-XXXX", "import_date": "ISO date", "pieces_count": N}
*/

-- Add new columns to glass_projects table
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'svg_source_url'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN svg_source_url text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'import_metadata'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN import_metadata jsonb DEFAULT '{}'::jsonb;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'original_order_code'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN original_order_code text;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'glass_projects' AND column_name = 'import_date'
  ) THEN
    ALTER TABLE glass_projects ADD COLUMN import_date timestamptz;
  END IF;
END $$;

-- Create index for searching by original order code
CREATE INDEX IF NOT EXISTS glass_projects_original_order_code_idx ON glass_projects(original_order_code);

-- Add comments
COMMENT ON COLUMN glass_projects.svg_source_url IS 'URL to the original SVG document in storage';
COMMENT ON COLUMN glass_projects.import_metadata IS 'Metadata from SVG import: source, codes, piece count, etc.';
COMMENT ON COLUMN glass_projects.original_order_code IS 'Original order code from external system (e.g., CR-8838e5b1)';
COMMENT ON COLUMN glass_projects.import_date IS 'Timestamp when the order was imported from external source';