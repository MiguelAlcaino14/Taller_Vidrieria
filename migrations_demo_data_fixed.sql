/*
  # Seed Demo Data - VERSIÓN CORREGIDA

  Este script crea usuarios demo y datos de prueba de forma segura.

  ## Usuarios que se crearán:
  - admin@demo.com (Administrador)
  - manager@demo.com (Manager)
  - usuario1@demo.com (Usuario cortador 1)
  - usuario2@demo.com (Usuario cortador 2)

  ## Contraseña para todos: demo123

  ## Datos creados:
  1. Usuarios con roles apropiados
  2. Asignaciones de manager
  3. Clientes de ejemplo
  4. Pedidos de ejemplo
  5. Materiales de ejemplo
*/

-- =====================================================
-- PASO 1: Crear usuarios demo en auth.users
-- =====================================================

-- Insertar usuarios en auth.users (si no existen)
INSERT INTO auth.users (
  id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  role
)
SELECT
  gen_random_uuid(),
  email,
  crypt('demo123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('full_name', full_name),
  false,
  'authenticated'
FROM (
  VALUES
    ('admin@demo.com', 'Administrador Demo'),
    ('manager@demo.com', 'Manager Demo'),
    ('usuario1@demo.com', 'Juan Cortador'),
    ('usuario2@demo.com', 'María Cortadora')
) AS users(email, full_name)
WHERE NOT EXISTS (
  SELECT 1 FROM auth.users WHERE auth.users.email = users.email
);

-- =====================================================
-- PASO 2: Crear perfiles de usuario
-- =====================================================

INSERT INTO user_profiles (id, email, full_name, role, created_at, updated_at)
SELECT
  u.id,
  u.email,
  u.raw_user_meta_data->>'full_name',
  CASE
    WHEN u.email = 'admin@demo.com' THEN 'admin'
    WHEN u.email = 'manager@demo.com' THEN 'manager'
    ELSE 'user'
  END,
  u.created_at,
  u.updated_at
FROM auth.users u
WHERE u.email IN ('admin@demo.com', 'manager@demo.com', 'usuario1@demo.com', 'usuario2@demo.com')
ON CONFLICT (id) DO UPDATE
SET
  role = EXCLUDED.role,
  full_name = EXCLUDED.full_name,
  updated_at = now();

-- =====================================================
-- PASO 3: Crear asignaciones de manager
-- =====================================================

INSERT INTO manager_assignments (manager_id, user_id, created_at)
SELECT
  manager.id,
  user_profile.id,
  now()
FROM user_profiles manager
CROSS JOIN user_profiles user_profile
WHERE manager.email = 'manager@demo.com'
  AND user_profile.email IN ('usuario1@demo.com', 'usuario2@demo.com')
ON CONFLICT (manager_id, user_id) DO NOTHING;

-- =====================================================
-- PASO 4: Crear clientes de ejemplo
-- =====================================================

INSERT INTO customers (name, contact_name, email, phone, address, notes, created_by, created_at, updated_at)
SELECT
  name,
  contact_name,
  email,
  phone,
  address,
  notes,
  (SELECT id FROM user_profiles WHERE email = 'admin@demo.com' LIMIT 1),
  now(),
  now()
FROM (
  VALUES
    (
      'Constructora Sol S.A.',
      'Roberto Martínez',
      'roberto@constructorasol.com',
      '+34 912 345 678',
      'Calle Mayor 45, Madrid',
      'Cliente VIP - Pago a 30 días'
    ),
    (
      'Diseños Modernos',
      'Laura García',
      'laura@disenosmodernos.com',
      '+34 933 456 789',
      'Av. Diagonal 123, Barcelona',
      'Proyectos de interiorismo'
    ),
    (
      'Ventanas del Norte',
      'Carlos Ruiz',
      'carlos@ventanasdelnorte.com',
      '+34 944 567 890',
      'Gran Vía 78, Bilbao',
      'Especialistas en ventanas'
    )
) AS c(name, contact_name, email, phone, address, notes)
WHERE NOT EXISTS (
  SELECT 1 FROM customers WHERE customers.email = c.email
);

-- =====================================================
-- PASO 5: Crear materiales en catálogo
-- =====================================================

INSERT INTO materials_catalog (name, type, width, height, thickness, unit_cost, stock_quantity, min_stock_level, notes, created_at, updated_at)
VALUES
  ('Vidrio Transparente 6mm', 'glass', 300, 200, 6, 45.50, 50, 10, 'Stock principal transparente', now(), now()),
  ('Vidrio Transparente 8mm', 'glass', 300, 200, 8, 62.00, 30, 8, 'Mayor grosor para puertas', now(), now()),
  ('Vidrio Templado 6mm', 'glass', 250, 180, 6, 78.00, 25, 5, 'Vidrio de seguridad', now(), now()),
  ('Vidrio Laminado 8mm', 'glass', 280, 190, 8, 95.00, 20, 5, 'Dos capas con PVB', now(), now())
ON CONFLICT DO NOTHING;

-- =====================================================
-- PASO 6: Crear pedidos de ejemplo
-- =====================================================

-- Pedido 1: Para Constructora Sol (admin)
INSERT INTO orders (
  order_number,
  customer_id,
  user_id,
  status,
  priority,
  delivery_date,
  notes,
  created_at,
  updated_at
)
SELECT
  'PED-' || to_char(now(), 'YYYYMMDD') || '-001',
  (SELECT id FROM customers WHERE email = 'roberto@constructorasol.com' LIMIT 1),
  (SELECT id FROM user_profiles WHERE email = 'admin@demo.com' LIMIT 1),
  'pending',
  'high',
  now() + interval '7 days',
  'Proyecto edificio Torre Norte - Fase 1',
  now(),
  now()
WHERE EXISTS (SELECT 1 FROM customers WHERE email = 'roberto@constructorasol.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'admin@demo.com')
RETURNING id;

-- Insertar items del pedido 1
WITH new_order AS (
  SELECT id FROM orders WHERE order_number = 'PED-' || to_char(now(), 'YYYYMMDD') || '-001' LIMIT 1
)
INSERT INTO order_items (order_id, width, height, quantity, edge_polishing, notes, created_at, updated_at)
SELECT
  new_order.id,
  width,
  height,
  quantity,
  edge_polishing,
  notes,
  now(),
  now()
FROM new_order
CROSS JOIN (
  VALUES
    (120, 180, 8, true, 'Ventanas principales - Templado'),
    (80, 120, 12, false, 'Ventanas baño'),
    (90, 200, 4, true, 'Puertas interiores')
) AS items(width, height, quantity, edge_polishing, notes);

-- Pedido 2: Para Diseños Modernos (manager)
INSERT INTO orders (
  order_number,
  customer_id,
  user_id,
  status,
  priority,
  delivery_date,
  notes,
  created_at,
  updated_at
)
SELECT
  'PED-' || to_char(now(), 'YYYYMMDD') || '-002',
  (SELECT id FROM customers WHERE email = 'laura@disenosmodernos.com' LIMIT 1),
  (SELECT id FROM user_profiles WHERE email = 'manager@demo.com' LIMIT 1),
  'in_progress',
  'medium',
  now() + interval '5 days',
  'Proyecto interiorismo oficinas',
  now(),
  now()
WHERE EXISTS (SELECT 1 FROM customers WHERE email = 'laura@disenosmodernos.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'manager@demo.com')
RETURNING id;

-- Insertar items del pedido 2
WITH new_order AS (
  SELECT id FROM orders WHERE order_number = 'PED-' || to_char(now(), 'YYYYMMDD') || '-002' LIMIT 1
)
INSERT INTO order_items (order_id, width, height, quantity, edge_polishing, notes, created_at, updated_at)
SELECT
  new_order.id,
  width,
  height,
  quantity,
  edge_polishing,
  notes,
  now(),
  now()
FROM new_order
CROSS JOIN (
  VALUES
    (60, 90, 15, true, 'Divisiones oficina'),
    (100, 100, 6, true, 'Mesas de cristal')
) AS items(width, height, quantity, edge_polishing, notes);

-- Pedido 3: Para Ventanas del Norte (usuario1)
INSERT INTO orders (
  order_number,
  customer_id,
  user_id,
  status,
  priority,
  delivery_date,
  notes,
  created_at,
  updated_at
)
SELECT
  'PED-' || to_char(now(), 'YYYYMMDD') || '-003',
  (SELECT id FROM customers WHERE email = 'carlos@ventanasdelnorte.com' LIMIT 1),
  (SELECT id FROM user_profiles WHERE email = 'usuario1@demo.com' LIMIT 1),
  'pending',
  'low',
  now() + interval '10 days',
  'Reposición stock ventanas',
  now(),
  now()
WHERE EXISTS (SELECT 1 FROM customers WHERE email = 'carlos@ventanasdelnorte.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'usuario1@demo.com')
RETURNING id;

-- Insertar items del pedido 3
WITH new_order AS (
  SELECT id FROM orders WHERE order_number = 'PED-' || to_char(now(), 'YYYYMMDD') || '-003' LIMIT 1
)
INSERT INTO order_items (order_id, width, height, quantity, edge_polishing, notes, created_at, updated_at)
SELECT
  new_order.id,
  width,
  height,
  quantity,
  edge_polishing,
  notes,
  now(),
  now()
FROM new_order
CROSS JOIN (
  VALUES
    (70, 110, 20, false, 'Ventanas estándar'),
    (50, 50, 10, false, 'Ventanas pequeñas')
) AS items(width, height, quantity, edge_polishing, notes);

-- =====================================================
-- RESUMEN
-- =====================================================

-- Mostrar resumen de datos creados
DO $$
DECLARE
  user_count INTEGER;
  customer_count INTEGER;
  order_count INTEGER;
  material_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO user_count FROM user_profiles WHERE email LIKE '%@demo.com';
  SELECT COUNT(*) INTO customer_count FROM customers;
  SELECT COUNT(*) INTO order_count FROM orders;
  SELECT COUNT(*) INTO material_count FROM materials_catalog;

  RAISE NOTICE '========================================';
  RAISE NOTICE 'DATOS DEMO CREADOS EXITOSAMENTE';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Usuarios demo: %', user_count;
  RAISE NOTICE 'Clientes: %', customer_count;
  RAISE NOTICE 'Pedidos: %', order_count;
  RAISE NOTICE 'Materiales: %', material_count;
  RAISE NOTICE '';
  RAISE NOTICE 'CREDENCIALES DE ACCESO:';
  RAISE NOTICE '- admin@demo.com / demo123';
  RAISE NOTICE '- manager@demo.com / demo123';
  RAISE NOTICE '- usuario1@demo.com / demo123';
  RAISE NOTICE '- usuario2@demo.com / demo123';
  RAISE NOTICE '========================================';
END $$;
