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

CREATE INDEX IF NOT EXISTS glass_projects_created_at_idx ON glass_projects(created_at DESC);