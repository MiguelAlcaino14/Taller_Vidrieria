/*
  # Seed Demo Data for Testing User Roles

  ## Overview
  This migration assigns roles to demo users and creates sample projects for testing.

  ## IMPORTANT
  This migration should be executed AFTER creating the following users manually:
  - admin@vidrios.com (Administrador Sistema)
  - manager@vidrios.com (Manager Regional)
  - usuario1@vidrios.com (Juan Pérez)
  - usuario2@vidrios.com (María González)

  ## Changes

  1. **Assign Roles:**
     - admin@vidrios.com → admin role
     - manager@vidrios.com → manager role
     - usuario1@vidrios.com → user role (default)
     - usuario2@vidrios.com → user role (default)

  2. **Create Manager Assignments:**
     - Manager manages usuario1 and usuario2

  3. **Create Sample Projects:**
     - 2 projects for admin user
     - 2 projects for manager user
     - 2 projects for usuario1
     - 2 projects for usuario2

  ## Notes
  This is a one-time migration for demo purposes. In production, roles would be
  assigned through an admin interface or API.
*/

-- Assign admin role
UPDATE user_profiles
SET role = 'admin', updated_at = now()
WHERE email = 'admin@vidrios.com';

-- Assign manager role
UPDATE user_profiles
SET role = 'manager', updated_at = now()
WHERE email = 'manager@vidrios.com';

-- Create manager assignments (manager manages usuario1 and usuario2)
INSERT INTO manager_assignments (manager_id, user_id)
SELECT
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com')
WHERE EXISTS (SELECT 1 FROM user_profiles WHERE email = 'manager@vidrios.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'usuario1@vidrios.com')
ON CONFLICT DO NOTHING;

INSERT INTO manager_assignments (manager_id, user_id)
SELECT
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  (SELECT id FROM user_profiles WHERE email = 'usuario2@vidrios.com')
WHERE EXISTS (SELECT 1 FROM user_profiles WHERE email = 'manager@vidrios.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'usuario2@vidrios.com')
ON CONFLICT DO NOTHING;

-- Create sample projects for admin
INSERT INTO glass_projects (user_id, name, sheet_width, sheet_height, cut_thickness, glass_thickness, cutting_method, cuts)
SELECT
  (SELECT id FROM user_profiles WHERE email = 'admin@vidrios.com'),
  'Proyecto Corporativo A',
  300,
  200,
  0.3,
  6,
  'machine',
  '[
    {"width": 80, "height": 120, "quantity": 4, "label": "Ventanas Oficina"},
    {"width": 60, "height": 90, "quantity": 6, "label": "Divisiones Internas"}
  ]'::jsonb
WHERE EXISTS (SELECT 1 FROM user_profiles WHERE email = 'admin@vidrios.com');

INSERT INTO glass_projects (user_id, name, sheet_width, sheet_height, cut_thickness, glass_thickness, cutting_method, cuts)
SELECT
  (SELECT id FROM user_profiles WHERE email = 'admin@vidrios.com'),
  'Proyecto Corporativo B',
  250,
  180,
  0.3,
  8,
  'machine',
  '[
    {"width": 70, "height": 140, "quantity": 3, "label": "Puertas Principal"},
    {"width": 50, "height": 50, "quantity": 8, "label": "Ventanas Pequeñas"}
  ]'::jsonb
WHERE EXISTS (SELECT 1 FROM user_profiles WHERE email = 'admin@vidrios.com');

-- Create sample projects for manager
INSERT INTO glass_projects (user_id, name, sheet_width, sheet_height, cut_thickness, glass_thickness, cutting_method, cuts)
SELECT
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  'Proyecto Comercial Norte',
  280,
  190,
  0.3,
  5,
  'machine',
  '[
    {"width": 90, "height": 150, "quantity": 2, "label": "Escaparates Tienda"},
    {"width": 40, "height": 60, "quantity": 10, "label": "Mostradores"}
  ]'::jsonb
WHERE EXISTS (SELECT 1 FROM user_profiles WHERE email = 'manager@vidrios.com');

INSERT INTO glass_projects (user_id, name, sheet_width, sheet_height, cut_thickness, glass_thickness, cutting_method, cuts)
SELECT
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  'Proyecto Residencial Sur',
  200,
  150,
  0.3,
  4,
  'manual',
  '[
    {"width": 60, "height": 80, "quantity": 5, "label": "Ventanas Dormitorios"},
    {"width": 45, "height": 45, "quantity": 4, "label": "Ventanas Baños"}
  ]'::jsonb
WHERE EXISTS (SELECT 1 FROM user_profiles WHERE email = 'manager@vidrios.com');

-- Create sample projects for usuario1
INSERT INTO glass_projects (user_id, name, sheet_width, sheet_height, cut_thickness, glass_thickness, cutting_method, cuts)
SELECT
  (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com'),
  'Proyecto Casa Particular',
  200,
  150,
  0.3,
  4,
  'manual',
  '[
    {"width": 50, "height": 80, "quantity": 3, "label": "Ventanas Sala"},
    {"width": 35, "height": 45, "quantity": 2, "label": "Ventanas Cocina"}
  ]'::jsonb
WHERE EXISTS (SELECT 1 FROM user_profiles WHERE email = 'usuario1@vidrios.com');

INSERT INTO glass_projects (user_id, name, sheet_width, sheet_height, cut_thickness, glass_thickness, cutting_method, cuts)
SELECT
  (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com'),
  'Ventanas Comedor',
  180,
  120,
  0.3,
  3,
  'manual',
  '[
    {"width": 55, "height": 90, "quantity": 2, "label": "Ventanas Grandes"},
    {"width": 30, "height": 40, "quantity": 4, "label": "Ventanas Pequeñas"}
  ]'::jsonb
WHERE EXISTS (SELECT 1 FROM user_profiles WHERE email = 'usuario1@vidrios.com');

-- Create sample projects for usuario2
INSERT INTO glass_projects (user_id, name, sheet_width, sheet_height, cut_thickness, glass_thickness, cutting_method, cuts)
SELECT
  (SELECT id FROM user_profiles WHERE email = 'usuario2@vidrios.com'),
  'Espejos Baño Principal',
  200,
  180,
  0.3,
  4,
  'manual',
  '[
    {"width": 80, "height": 120, "quantity": 2, "label": "Espejo Grande"},
    {"width": 40, "height": 50, "quantity": 2, "label": "Espejos Tocador"}
  ]'::jsonb
WHERE EXISTS (SELECT 1 FROM user_profiles WHERE email = 'usuario2@vidrios.com');

INSERT INTO glass_projects (user_id, name, sheet_width, sheet_height, cut_thickness, glass_thickness, cutting_method, cuts)
SELECT
  (SELECT id FROM user_profiles WHERE email = 'usuario2@vidrios.com'),
  'Puertas de Vidrio',
  250,
  200,
  0.3,
  6,
  'machine',
  '[
    {"width": 90, "height": 180, "quantity": 2, "label": "Puertas Entrada"},
    {"width": 70, "height": 160, "quantity": 1, "label": "Puerta Interior"}
  ]'::jsonb
WHERE EXISTS (SELECT 1 FROM user_profiles WHERE email = 'usuario2@vidrios.com');

-- Verify the setup
DO $$
DECLARE
  admin_count INTEGER;
  manager_count INTEGER;
  user_count INTEGER;
  assignment_count INTEGER;
  project_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO admin_count FROM user_profiles WHERE role = 'admin';
  SELECT COUNT(*) INTO manager_count FROM user_profiles WHERE role = 'manager';
  SELECT COUNT(*) INTO user_count FROM user_profiles WHERE role = 'user';
  SELECT COUNT(*) INTO assignment_count FROM manager_assignments;
  SELECT COUNT(*) INTO project_count FROM glass_projects WHERE user_id IS NOT NULL;

  RAISE NOTICE 'Demo Data Setup Complete:';
  RAISE NOTICE '  - Admin users: %', admin_count;
  RAISE NOTICE '  - Manager users: %', manager_count;
  RAISE NOTICE '  - Regular users: %', user_count;
  RAISE NOTICE '  - Manager assignments: %', assignment_count;
  RAISE NOTICE '  - Sample projects: %', project_count;
END $$;