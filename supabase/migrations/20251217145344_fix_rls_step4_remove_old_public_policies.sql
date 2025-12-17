/*
  # Fix RLS - Step 4: Remove Old Public Policies

  ## Overview
  Remove any remaining old policies that allow public access to glass_projects.
  These are leftover from the initial migrations before the auth system was added.

  ## Changes
  - Remove "Anyone can..." policies from glass_projects
  - Ensures only authenticated operators and admins can access orders
*/

-- Remove old public policies from glass_projects
DROP POLICY IF EXISTS "Anyone can view glass projects" ON glass_projects;
DROP POLICY IF EXISTS "Anyone can create glass projects" ON glass_projects;
DROP POLICY IF EXISTS "Anyone can update glass projects" ON glass_projects;
DROP POLICY IF EXISTS "Anyone can delete glass projects" ON glass_projects;