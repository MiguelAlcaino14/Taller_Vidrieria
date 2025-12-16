/*
  # Crear Datos Demo (SOLO DATOS - NO USUARIOS)

  IMPORTANTE: Ejecuta esto DESPUÉS de llamar a la función setup-demo-users

  Este script crea:
  - Clientes de ejemplo
  - Materiales en catálogo
  - Pedidos con items
*/

-- =====================================================
-- CLIENTES
-- =====================================================

INSERT INTO customers (name, contact_name, email, phone, address, notes, created_by, created_at, updated_at)
SELECT
  'Constructora Sol S.A.',
  'Roberto Martínez',
  'roberto@constructorasol.com',
  '+34 912 345 678',
  'Calle Mayor 45, Madrid',
  'Cliente VIP - Pago a 30 días',
  (SELECT id FROM user_profiles WHERE email = 'admin@vidrios.com' LIMIT 1),
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE email = 'roberto@constructorasol.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'admin@vidrios.com');

INSERT INTO customers (name, contact_name, email, phone, address, notes, created_by, created_at, updated_at)
SELECT
  'Diseños Modernos',
  'Laura García',
  'laura@disenosmodernos.com',
  '+34 933 456 789',
  'Av. Diagonal 123, Barcelona',
  'Proyectos de interiorismo',
  (SELECT id FROM user_profiles WHERE email = 'admin@vidrios.com' LIMIT 1),
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE email = 'laura@disenosmodernos.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'admin@vidrios.com');

INSERT INTO customers (name, contact_name, email, phone, address, notes, created_by, created_at, updated_at)
SELECT
  'Ventanas del Norte',
  'Carlos Ruiz',
  'carlos@ventanasdelnorte.com',
  '+34 944 567 890',
  'Gran Vía 78, Bilbao',
  'Especialistas en ventanas',
  (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com' LIMIT 1),
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE email = 'carlos@ventanasdelnorte.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'usuario1@vidrios.com');

-- =====================================================
-- MATERIALES
-- =====================================================

INSERT INTO materials_catalog (name, type, width, height, thickness, unit_cost, stock_quantity, min_stock_level, notes, created_at, updated_at)
VALUES
  ('Vidrio Transparente 6mm', 'glass', 300, 200, 6, 45.50, 50, 10, 'Stock principal transparente', now(), now()),
  ('Vidrio Transparente 8mm', 'glass', 300, 200, 8, 62.00, 30, 8, 'Mayor grosor para puertas', now(), now()),
  ('Vidrio Templado 6mm', 'glass', 250, 180, 6, 78.00, 25, 5, 'Vidrio de seguridad', now(), now()),
  ('Vidrio Laminado 8mm', 'glass', 280, 190, 8, 95.00, 20, 5, 'Dos capas con PVB', now(), now())
ON CONFLICT DO NOTHING;

-- =====================================================
-- PEDIDOS
-- =====================================================

-- Pedido 1: Constructora Sol (Admin)
DO $$
DECLARE
  v_order_id uuid;
  v_customer_id uuid;
  v_user_id uuid;
BEGIN
  -- Obtener IDs
  SELECT id INTO v_customer_id FROM customers WHERE email = 'roberto@constructorasol.com' LIMIT 1;
  SELECT id INTO v_user_id FROM user_profiles WHERE email = 'admin@vidrios.com' LIMIT 1;

  -- Solo continuar si existen ambos
  IF v_customer_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    -- Crear pedido
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
    ) VALUES (
      'PED-' || to_char(now(), 'YYYYMMDD') || '-001',
      v_customer_id,
      v_user_id,
      'pending',
      'high',
      now() + interval '7 days',
      'Proyecto edificio Torre Norte - Fase 1',
      now(),
      now()
    )
    RETURNING id INTO v_order_id;

    -- Crear items
    INSERT INTO order_items (order_id, width, height, quantity, edge_polishing, notes, created_at, updated_at)
    VALUES
      (v_order_id, 120, 180, 8, true, 'Ventanas principales - Templado', now(), now()),
      (v_order_id, 80, 120, 12, false, 'Ventanas baño', now(), now()),
      (v_order_id, 90, 200, 4, true, 'Puertas interiores', now(), now());
  END IF;
END $$;

-- Pedido 2: Diseños Modernos (Manager)
DO $$
DECLARE
  v_order_id uuid;
  v_customer_id uuid;
  v_user_id uuid;
BEGIN
  SELECT id INTO v_customer_id FROM customers WHERE email = 'laura@disenosmodernos.com' LIMIT 1;
  SELECT id INTO v_user_id FROM user_profiles WHERE email = 'manager@vidrios.com' LIMIT 1;

  IF v_customer_id IS NOT NULL AND v_user_id IS NOT NULL THEN
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
    ) VALUES (
      'PED-' || to_char(now(), 'YYYYMMDD') || '-002',
      v_customer_id,
      v_user_id,
      'in_progress',
      'medium',
      now() + interval '5 days',
      'Proyecto interiorismo oficinas',
      now(),
      now()
    )
    RETURNING id INTO v_order_id;

    INSERT INTO order_items (order_id, width, height, quantity, edge_polishing, notes, created_at, updated_at)
    VALUES
      (v_order_id, 60, 90, 15, true, 'Divisiones oficina', now(), now()),
      (v_order_id, 100, 100, 6, true, 'Mesas de cristal', now(), now());
  END IF;
END $$;

-- Pedido 3: Ventanas del Norte (Usuario1)
DO $$
DECLARE
  v_order_id uuid;
  v_customer_id uuid;
  v_user_id uuid;
BEGIN
  SELECT id INTO v_customer_id FROM customers WHERE email = 'carlos@ventanasdelnorte.com' LIMIT 1;
  SELECT id INTO v_user_id FROM user_profiles WHERE email = 'usuario1@vidrios.com' LIMIT 1;

  IF v_customer_id IS NOT NULL AND v_user_id IS NOT NULL THEN
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
    ) VALUES (
      'PED-' || to_char(now(), 'YYYYMMDD') || '-003',
      v_customer_id,
      v_user_id,
      'pending',
      'low',
      now() + interval '10 days',
      'Reposición stock ventanas',
      now(),
      now()
    )
    RETURNING id INTO v_order_id;

    INSERT INTO order_items (order_id, width, height, quantity, edge_polishing, notes, created_at, updated_at)
    VALUES
      (v_order_id, 70, 110, 20, false, 'Ventanas estándar', now(), now()),
      (v_order_id, 50, 50, 10, false, 'Ventanas pequeñas', now(), now());
  END IF;
END $$;

-- =====================================================
-- VERIFICAR RESULTADOS
-- =====================================================

DO $$
DECLARE
  v_users INTEGER;
  v_customers INTEGER;
  v_orders INTEGER;
  v_materials INTEGER;
  v_items INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_users FROM user_profiles WHERE email LIKE '%@vidrios.com';
  SELECT COUNT(*) INTO v_customers FROM customers;
  SELECT COUNT(*) INTO v_orders FROM orders;
  SELECT COUNT(*) INTO v_materials FROM materials_catalog;
  SELECT COUNT(*) INTO v_items FROM order_items;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RESUMEN DE DATOS CREADOS';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Usuarios encontrados: %', v_users;
  RAISE NOTICE 'Clientes creados: %', v_customers;
  RAISE NOTICE 'Pedidos creados: %', v_orders;
  RAISE NOTICE 'Items de pedido: %', v_items;
  RAISE NOTICE 'Materiales en catálogo: %', v_materials;
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
END $$;
