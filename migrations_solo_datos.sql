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

INSERT INTO customers (name, email, phone, address, customer_type, notes, user_id, created_at, updated_at)
SELECT
  'Constructora Sol S.A.',
  'roberto@constructorasol.com',
  '+34 912 345 678',
  'Calle Mayor 45, Madrid',
  'company',
  'Cliente VIP - Contacto: Roberto Martínez - Pago a 30 días',
  (SELECT id FROM user_profiles WHERE email = 'admin@vidrios.com' LIMIT 1),
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE email = 'roberto@constructorasol.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'admin@vidrios.com');

INSERT INTO customers (name, email, phone, address, customer_type, notes, user_id, created_at, updated_at)
SELECT
  'Diseños Modernos',
  'laura@disenosmodernos.com',
  '+34 933 456 789',
  'Av. Diagonal 123, Barcelona',
  'company',
  'Proyectos de interiorismo - Contacto: Laura García',
  (SELECT id FROM user_profiles WHERE email = 'admin@vidrios.com' LIMIT 1),
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE email = 'laura@disenosmodernos.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'admin@vidrios.com');

INSERT INTO customers (name, email, phone, address, customer_type, notes, user_id, created_at, updated_at)
SELECT
  'Carlos Ruiz',
  'carlos@ventanasdelnorte.com',
  '+34 944 567 890',
  'Gran Vía 78, Bilbao',
  'individual',
  'Especialista en ventanas - Compras frecuentes',
  (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com' LIMIT 1),
  now(),
  now()
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE email = 'carlos@ventanasdelnorte.com')
  AND EXISTS (SELECT 1 FROM user_profiles WHERE email = 'usuario1@vidrios.com');

-- =====================================================
-- HOJAS DE MATERIAL (INVENTARIO)
-- =====================================================

-- Insertar algunas hojas de vidrio en inventario
DO $$
DECLARE
  v_user_id uuid;
  v_glass_type_transparente uuid;
  v_glass_type_templado uuid;
BEGIN
  -- Obtener IDs
  SELECT id INTO v_user_id FROM user_profiles WHERE email = 'admin@vidrios.com' LIMIT 1;
  SELECT id INTO v_glass_type_transparente FROM glass_types WHERE name = 'Transparente' LIMIT 1;
  SELECT id INTO v_glass_type_templado FROM glass_types WHERE name = 'Templado Transparente' LIMIT 1;

  IF v_user_id IS NOT NULL AND v_glass_type_transparente IS NOT NULL THEN
    -- Hojas de vidrio transparente
    INSERT INTO material_sheets (user_id, material_type, glass_type_id, thickness, width, height, origin, status, purchase_date, purchase_cost, supplier, notes)
    VALUES
      (v_user_id, 'glass', v_glass_type_transparente, 6, 3000, 2000, 'purchase', 'available', now() - interval '5 days', 135.00, 'Vidrios del Norte', 'Lote 2024-001'),
      (v_user_id, 'glass', v_glass_type_transparente, 6, 3000, 2000, 'purchase', 'available', now() - interval '5 days', 135.00, 'Vidrios del Norte', 'Lote 2024-001'),
      (v_user_id, 'glass', v_glass_type_transparente, 8, 3000, 2000, 'purchase', 'available', now() - interval '3 days', 186.00, 'Vidrios del Norte', 'Lote 2024-002');
  END IF;

  IF v_user_id IS NOT NULL AND v_glass_type_templado IS NOT NULL THEN
    -- Hojas de vidrio templado
    INSERT INTO material_sheets (user_id, material_type, glass_type_id, thickness, width, height, origin, status, purchase_date, purchase_cost, supplier, notes)
    VALUES
      (v_user_id, 'glass', v_glass_type_templado, 6, 2500, 1800, 'purchase', 'available', now() - interval '2 days', 157.50, 'Templados SA', 'Certificado seguridad incluido');
  END IF;
END $$;

-- =====================================================
-- PEDIDOS
-- =====================================================

-- Pedido 1: Constructora Sol (Admin)
DO $$
DECLARE
  v_order_id uuid;
  v_customer_id uuid;
  v_user_id uuid;
  v_glass_type_id uuid;
  v_aluminum_id uuid;
BEGIN
  -- Obtener IDs
  SELECT id INTO v_customer_id FROM customers WHERE email = 'roberto@constructorasol.com' LIMIT 1;
  SELECT id INTO v_user_id FROM user_profiles WHERE email = 'admin@vidrios.com' LIMIT 1;
  SELECT id INTO v_glass_type_id FROM glass_types WHERE name = 'Templado Transparente' LIMIT 1;
  SELECT id INTO v_aluminum_id FROM aluminum_profiles WHERE name = 'Línea Módena' AND color = 'Natural' LIMIT 1;

  -- Solo continuar si existen
  IF v_customer_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    -- Crear pedido
    INSERT INTO glass_projects (
      name,
      user_id,
      customer_id,
      sheet_width,
      sheet_height,
      cut_thickness,
      cuts,
      status,
      notes,
      promised_date,
      quote_date,
      created_at,
      updated_at
    ) VALUES (
      'Edificio Torre Norte - Fase 1',
      v_user_id,
      v_customer_id,
      300,
      200,
      0.3,
      '[]'::jsonb,
      'approved',
      'Proyecto edificio Torre Norte - Ventanas principales',
      (now() + interval '7 days')::date,
      now(),
      now(),
      now()
    )
    RETURNING id INTO v_order_id;

    -- Crear items del pedido
    IF v_glass_type_id IS NOT NULL AND v_aluminum_id IS NOT NULL THEN
      INSERT INTO order_items (order_id, item_number, description, quantity, glass_type_id, glass_thickness, aluminum_profile_id, glass_pieces, labor_cost, item_total, notes)
      VALUES
        (v_order_id, 1, 'Ventanas corredizas principales', 8, v_glass_type_id, 6, v_aluminum_id, '[{"width": 1200, "height": 1800, "quantity": 2}]'::jsonb, 80.00, 1200.00, 'Templado de seguridad'),
        (v_order_id, 2, 'Ventanas baño', 12, v_glass_type_id, 4, v_aluminum_id, '[{"width": 800, "height": 1200, "quantity": 1}]'::jsonb, 40.00, 480.00, 'Ventanas pequeñas'),
        (v_order_id, 3, 'Puertas vidrio balcón', 4, v_glass_type_id, 8, v_aluminum_id, '[{"width": 900, "height": 2000, "quantity": 1}]'::jsonb, 120.00, 840.00, 'Vidrio templado 8mm');
    END IF;
  END IF;
END $$;

-- Pedido 2: Diseños Modernos (Manager)
DO $$
DECLARE
  v_order_id uuid;
  v_customer_id uuid;
  v_user_id uuid;
  v_glass_type_id uuid;
BEGIN
  SELECT id INTO v_customer_id FROM customers WHERE email = 'laura@disenosmodernos.com' LIMIT 1;
  SELECT id INTO v_user_id FROM user_profiles WHERE email = 'manager@vidrios.com' LIMIT 1;
  SELECT id INTO v_glass_type_id FROM glass_types WHERE name = 'Transparente' LIMIT 1;

  IF v_customer_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    INSERT INTO glass_projects (
      name,
      user_id,
      customer_id,
      sheet_width,
      sheet_height,
      cut_thickness,
      cuts,
      status,
      notes,
      promised_date,
      quote_date,
      approved_date,
      created_at,
      updated_at
    ) VALUES (
      'Interiorismo Oficinas Central',
      v_user_id,
      v_customer_id,
      300,
      200,
      0.3,
      '[]'::jsonb,
      'in_production',
      'Proyecto interiorismo oficinas - Divisiones de vidrio',
      (now() + interval '5 days')::date,
      now() - interval '2 days',
      now() - interval '1 day',
      now(),
      now()
    )
    RETURNING id INTO v_order_id;

    IF v_glass_type_id IS NOT NULL THEN
      INSERT INTO order_items (order_id, item_number, description, quantity, glass_type_id, glass_thickness, glass_pieces, labor_cost, item_total, notes)
      VALUES
        (v_order_id, 1, 'Divisiones oficina', 15, v_glass_type_id, 6, '[{"width": 600, "height": 900, "quantity": 1}]'::jsonb, 30.00, 450.00, 'Cristal transparente'),
        (v_order_id, 2, 'Mesas de cristal', 6, v_glass_type_id, 10, '[{"width": 1000, "height": 1000, "quantity": 1}]'::jsonb, 50.00, 380.00, 'Tableros mesa 10mm');
    END IF;
  END IF;
END $$;

-- Pedido 3: Ventanas del Norte (Usuario1)
DO $$
DECLARE
  v_order_id uuid;
  v_customer_id uuid;
  v_user_id uuid;
  v_glass_type_id uuid;
BEGIN
  SELECT id INTO v_customer_id FROM customers WHERE email = 'carlos@ventanasdelnorte.com' LIMIT 1;
  SELECT id INTO v_user_id FROM user_profiles WHERE email = 'usuario1@vidrios.com' LIMIT 1;
  SELECT id INTO v_glass_type_id FROM glass_types WHERE name = 'Bronce' LIMIT 1;

  IF v_customer_id IS NOT NULL AND v_user_id IS NOT NULL THEN
    INSERT INTO glass_projects (
      name,
      user_id,
      customer_id,
      sheet_width,
      sheet_height,
      cut_thickness,
      cuts,
      status,
      notes,
      promised_date,
      quote_date,
      created_at,
      updated_at
    ) VALUES (
      'Reposición Stock Ventanas',
      v_user_id,
      v_customer_id,
      300,
      200,
      0.3,
      '[]'::jsonb,
      'quoted',
      'Reposición stock ventanas estándar',
      (now() + interval '10 days')::date,
      now(),
      now(),
      now()
    )
    RETURNING id INTO v_order_id;

    IF v_glass_type_id IS NOT NULL THEN
      INSERT INTO order_items (order_id, item_number, description, quantity, glass_type_id, glass_thickness, glass_pieces, labor_cost, item_total, notes)
      VALUES
        (v_order_id, 1, 'Ventanas estándar', 20, v_glass_type_id, 4, '[{"width": 700, "height": 1100, "quantity": 1}]'::jsonb, 25.00, 520.00, 'Vidrio bronce estándar'),
        (v_order_id, 2, 'Ventanas pequeñas', 10, v_glass_type_id, 4, '[{"width": 500, "height": 500, "quantity": 1}]'::jsonb, 15.00, 180.00, 'Ventanas baño pequeñas');
    END IF;
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
  v_sheets INTEGER;
  v_items INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_users FROM user_profiles WHERE email LIKE '%@vidrios.com';
  SELECT COUNT(*) INTO v_customers FROM customers;
  SELECT COUNT(*) INTO v_orders FROM glass_projects WHERE customer_id IS NOT NULL;
  SELECT COUNT(*) INTO v_sheets FROM material_sheets;
  SELECT COUNT(*) INTO v_items FROM order_items;

  RAISE NOTICE '';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'RESUMEN DE DATOS CREADOS';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Usuarios encontrados: %', v_users;
  RAISE NOTICE 'Clientes creados: %', v_customers;
  RAISE NOTICE 'Pedidos creados: %', v_orders;
  RAISE NOTICE 'Items de pedido: %', v_items;
  RAISE NOTICE 'Hojas de material en inventario: %', v_sheets;
  RAISE NOTICE '========================================';
  RAISE NOTICE '';
END $$;
