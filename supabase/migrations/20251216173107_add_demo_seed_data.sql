/*
  # Add Demo Seed Data

  ## Overview
  Adds sample data for testing the glass cutting management system.

  ## Data Added
  
  ### 1. Manager Assignments
  - Manager (manager@vidrios.com) manages:
    - usuario1@vidrios.com (Juan Pérez)
    - usuario2@vidrios.com (María González)

  ### 2. Sample Customers
  - 2 customers for admin
  - 2 customers for manager
  - 2 customers for usuario1
  - 2 customers for usuario2
  - 1 customer for malcaino

  ### 3. Sample Orders
  - Various orders with different statuses (quoted, approved, in_production, ready, delivered)
  - Orders distributed across all users
  - Orders linked to customers

  ## Notes
  - All data is for demonstration purposes only
  - User IDs are fetched dynamically based on email addresses
  - Orders have realistic data (dates, pricing, etc.)
*/

-- ============================================================================
-- MANAGER ASSIGNMENTS
-- ============================================================================

-- Manager manages usuario1 and usuario2
INSERT INTO manager_assignments (manager_id, user_id)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com')
WHERE NOT EXISTS (
  SELECT 1 FROM manager_assignments 
  WHERE manager_id = (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com')
  AND user_id = (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com')
);

INSERT INTO manager_assignments (manager_id, user_id)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  (SELECT id FROM user_profiles WHERE email = 'usuario2@vidrios.com')
WHERE NOT EXISTS (
  SELECT 1 FROM manager_assignments 
  WHERE manager_id = (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com')
  AND user_id = (SELECT id FROM user_profiles WHERE email = 'usuario2@vidrios.com')
);

-- ============================================================================
-- SAMPLE CUSTOMERS
-- ============================================================================

-- Customers for Admin
INSERT INTO customers (user_id, name, phone, email, address, customer_type, notes)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'admin@vidrios.com'),
  'Constructora El Sol SA',
  '+56912345678',
  'contacto@elsol.cl',
  'Av. Providencia 1234, Santiago',
  'company',
  'Cliente corporativo - Proyectos grandes'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone = '+56912345678');

INSERT INTO customers (user_id, name, phone, email, address, customer_type, notes)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'admin@vidrios.com'),
  'Edificio Plaza Central',
  '+56923456789',
  'admin@plazacentral.cl',
  'Av. Libertador Bernardo O''Higgins 500, Santiago',
  'company',
  'Edificio comercial - Mantenimiento periódico'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone = '+56923456789');

-- Customers for Manager
INSERT INTO customers (user_id, name, phone, email, address, customer_type, notes)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  'Restaurant Vista Mar',
  '+56934567890',
  'gerencia@vistamar.cl',
  'Av. del Mar 2500, Viña del Mar',
  'company',
  'Restaurante - Windows con vista al mar'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone = '+56934567890');

INSERT INTO customers (user_id, name, phone, email, address, customer_type, notes)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  'Carlos Muñoz',
  '+56945678901',
  'carlos.munoz@email.com',
  'Los Aromos 890, Valparaíso',
  'individual',
  'Casa particular - Renovación integral'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone = '+56945678901');

-- Customers for Usuario1 (Juan Pérez)
INSERT INTO customers (user_id, name, phone, email, address, customer_type, notes)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com'),
  'Rosa Silva',
  '+56956789012',
  'rosa.silva@email.com',
  'Pasaje Los Olivos 45, La Florida',
  'individual',
  'Casa nueva - Primera compra'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone = '+56956789012');

INSERT INTO customers (user_id, name, phone, email, address, customer_type, notes)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com'),
  'Familia Rodríguez',
  '+56967890123',
  'rodriguez.familia@email.com',
  'Calle Principal 123, Maipú',
  'individual',
  'Departamento - 3 dormitorios'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone = '+56967890123');

-- Customers for Usuario2 (María González)
INSERT INTO customers (user_id, name, phone, email, address, customer_type, notes)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'usuario2@vidrios.com'),
  'Clínica Salud Integral',
  '+56978901234',
  'compras@saludintegral.cl',
  'Av. Las Condes 5678, Las Condes',
  'company',
  'Clínica privada - Ventanas para consultorios'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone = '+56978901234');

INSERT INTO customers (user_id, name, phone, email, address, customer_type, notes)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'usuario2@vidrios.com'),
  'Pedro Soto',
  '+56989012345',
  'pedro.soto@email.com',
  'Av. Grecia 3456, Ñuñoa',
  'individual',
  'Remodelación baños - Espejos'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone = '+56989012345');

-- Customers for Miguel Alcaino
INSERT INTO customers (user_id, name, phone, email, address, customer_type, notes)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'malcaino@vidrios.com'),
  'Ana Torres',
  '+56990123456',
  'ana.torres@email.com',
  'Los Castaños 789, Providencia',
  'individual',
  'Ventanas para living comedor'
WHERE NOT EXISTS (SELECT 1 FROM customers WHERE phone = '+56990123456');

-- ============================================================================
-- SAMPLE ORDERS
-- ============================================================================

-- Orders for Admin (2 orders)
INSERT INTO glass_projects (user_id, customer_id, name, status, sheet_width, sheet_height, cut_thickness, notes, quote_date, approved_date, promised_date, subtotal_materials, subtotal_labor, total_amount)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'admin@vidrios.com'),
  (SELECT id FROM customers WHERE phone = '+56912345678'),
  'Proyecto Corporativo Torre A',
  'in_production',
  3000,
  2000,
  0.3,
  'Torre A - 15 pisos - Ventanas fachada',
  NOW() - INTERVAL '20 days',
  NOW() - INTERVAL '15 days',
  CURRENT_DATE + INTERVAL '10 days',
  1500000,
  350000,
  1850000
WHERE NOT EXISTS (SELECT 1 FROM glass_projects WHERE name = 'Proyecto Corporativo Torre A');

INSERT INTO glass_projects (user_id, customer_id, name, status, sheet_width, sheet_height, cut_thickness, notes, quote_date, promised_date, subtotal_materials, subtotal_labor, total_amount)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'admin@vidrios.com'),
  (SELECT id FROM customers WHERE phone = '+56923456789'),
  'Mantenimiento Plaza Central',
  'quoted',
  2440,
  1830,
  0.3,
  'Reemplazo de vidrios en área común',
  NOW() - INTERVAL '5 days',
  CURRENT_DATE + INTERVAL '30 days',
  85000,
  25000,
  110000
WHERE NOT EXISTS (SELECT 1 FROM glass_projects WHERE name = 'Mantenimiento Plaza Central');

-- Orders for Manager (3 orders)
INSERT INTO glass_projects (user_id, customer_id, name, status, sheet_width, sheet_height, cut_thickness, notes, quote_date, approved_date, promised_date, delivered_date, subtotal_materials, subtotal_labor, total_amount)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  (SELECT id FROM customers WHERE phone = '+56934567890'),
  'Restaurant Vista Mar - Ventanales',
  'delivered',
  3000,
  2400,
  0.3,
  '8 ventanales grandes para terraza con vista',
  NOW() - INTERVAL '45 days',
  NOW() - INTERVAL '40 days',
  CURRENT_DATE - INTERVAL '5 days',
  NOW() - INTERVAL '3 days',
  420000,
  95000,
  515000
WHERE NOT EXISTS (SELECT 1 FROM glass_projects WHERE name = 'Restaurant Vista Mar - Ventanales');

INSERT INTO glass_projects (user_id, customer_id, name, status, sheet_width, sheet_height, cut_thickness, notes, quote_date, approved_date, promised_date, subtotal_materials, subtotal_labor, total_amount)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  (SELECT id FROM customers WHERE phone = '+56945678901'),
  'Casa Carlos Muñoz - Renovación',
  'ready',
  2440,
  1830,
  0.3,
  'Ventanas dormitorios y living - Aluminio blanco',
  NOW() - INTERVAL '25 days',
  NOW() - INTERVAL '20 days',
  CURRENT_DATE + INTERVAL '2 days',
  185000,
  55000,
  240000
WHERE NOT EXISTS (SELECT 1 FROM glass_projects WHERE name = 'Casa Carlos Muñoz - Renovación');

INSERT INTO glass_projects (user_id, customer_id, name, status, sheet_width, sheet_height, cut_thickness, notes, quote_date, promised_date, subtotal_materials, subtotal_labor, total_amount)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'manager@vidrios.com'),
  (SELECT id FROM customers WHERE phone = '+56934567890'),
  'Vista Mar - Puertas de Vidrio',
  'quoted',
  2100,
  2400,
  0.3,
  'Puertas de entrada en vidrio templado',
  NOW() - INTERVAL '3 days',
  CURRENT_DATE + INTERVAL '25 days',
  320000,
  80000,
  400000
WHERE NOT EXISTS (SELECT 1 FROM glass_projects WHERE name = 'Vista Mar - Puertas de Vidrio');

-- Orders for Usuario1 (Juan Pérez) (2 orders)
INSERT INTO glass_projects (user_id, customer_id, name, status, sheet_width, sheet_height, cut_thickness, notes, quote_date, approved_date, promised_date, subtotal_materials, subtotal_labor, total_amount)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com'),
  (SELECT id FROM customers WHERE phone = '+56956789012'),
  'Casa Rosa Silva - Ventanas',
  'approved',
  2440,
  1830,
  0.3,
  'Casa nueva - 6 ventanas correderas',
  NOW() - INTERVAL '10 days',
  NOW() - INTERVAL '7 days',
  CURRENT_DATE + INTERVAL '15 days',
  125000,
  35000,
  160000
WHERE NOT EXISTS (SELECT 1 FROM glass_projects WHERE name = 'Casa Rosa Silva - Ventanas');

INSERT INTO glass_projects (user_id, customer_id, name, status, sheet_width, sheet_height, cut_thickness, notes, quote_date, approved_date, promised_date, subtotal_materials, subtotal_labor, total_amount)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'usuario1@vidrios.com'),
  (SELECT id FROM customers WHERE phone = '+56967890123'),
  'Dpto. Familia Rodríguez',
  'in_production',
  2000,
  1500,
  0.3,
  'Ventanas para 3 dormitorios - Vidrio templado',
  NOW() - INTERVAL '18 days',
  NOW() - INTERVAL '15 days',
  CURRENT_DATE + INTERVAL '8 days',
  95000,
  28000,
  123000
WHERE NOT EXISTS (SELECT 1 FROM glass_projects WHERE name = 'Dpto. Familia Rodríguez');

-- Orders for Usuario2 (María González) (2 orders)
INSERT INTO glass_projects (user_id, customer_id, name, status, sheet_width, sheet_height, cut_thickness, notes, quote_date, approved_date, promised_date, delivered_date, subtotal_materials, subtotal_labor, total_amount)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'usuario2@vidrios.com'),
  (SELECT id FROM customers WHERE phone = '+56978901234'),
  'Clínica Salud Integral - Fase 1',
  'delivered',
  2440,
  1830,
  0.3,
  'Ventanas para consultorios 2do piso',
  NOW() - INTERVAL '35 days',
  NOW() - INTERVAL '30 days',
  CURRENT_DATE - INTERVAL '10 days',
  NOW() - INTERVAL '8 days',
  280000,
  75000,
  355000
WHERE NOT EXISTS (SELECT 1 FROM glass_projects WHERE name = 'Clínica Salud Integral - Fase 1');

INSERT INTO glass_projects (user_id, customer_id, name, status, sheet_width, sheet_height, cut_thickness, notes, quote_date, promised_date, subtotal_materials, subtotal_labor, total_amount)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'usuario2@vidrios.com'),
  (SELECT id FROM customers WHERE phone = '+56989012345'),
  'Espejos Baño Pedro Soto',
  'quoted',
  2440,
  1830,
  0.3,
  '3 espejos grandes para baños',
  NOW() - INTERVAL '2 days',
  CURRENT_DATE + INTERVAL '20 days',
  45000,
  15000,
  60000
WHERE NOT EXISTS (SELECT 1 FROM glass_projects WHERE name = 'Espejos Baño Pedro Soto');

-- Orders for Miguel Alcaino (1 order)
INSERT INTO glass_projects (user_id, customer_id, name, status, sheet_width, sheet_height, cut_thickness, notes, quote_date, approved_date, promised_date, subtotal_materials, subtotal_labor, total_amount)
SELECT 
  (SELECT id FROM user_profiles WHERE email = 'malcaino@vidrios.com'),
  (SELECT id FROM customers WHERE phone = '+56990123456'),
  'Living Comedor Ana Torres',
  'approved',
  2440,
  1830,
  0.3,
  '2 ventanales grandes para living',
  NOW() - INTERVAL '12 days',
  NOW() - INTERVAL '8 days',
  CURRENT_DATE + INTERVAL '12 days',
  78000,
  22000,
  100000
WHERE NOT EXISTS (SELECT 1 FROM glass_projects WHERE name = 'Living Comedor Ana Torres');
