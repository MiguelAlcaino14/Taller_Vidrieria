# Documentación Técnica - Sistema de Gestión de Vidriería

## Índice
1. [Arquitectura del Sistema](#arquitectura-del-sistema)
2. [Stack Tecnológico](#stack-tecnológico)
3. [Estructura del Proyecto](#estructura-del-proyecto)
4. [Base de Datos](#base-de-datos)
5. [Autenticación y Seguridad](#autenticación-y-seguridad)
6. [Algoritmos de Optimización](#algoritmos-de-optimización)
7. [API y Servicios](#api-y-servicios)
8. [Componentes React](#componentes-react)
9. [Configuración y Despliegue](#configuración-y-despliegue)
10. [Desarrollo y Testing](#desarrollo-y-testing)
11. [Troubleshooting](#troubleshooting)

---

## Arquitectura del Sistema

### Arquitectura General

```
┌─────────────────────────────────────────────┐
│           Frontend (React + Vite)           │
│  ┌─────────┐  ┌──────────┐  ┌────────────┐ │
│  │Components│  │ Contexts │  │   Hooks    │ │
│  └─────────┘  └──────────┘  └────────────┘ │
│  ┌─────────┐  ┌──────────┐  ┌────────────┐ │
│  │  Utils  │  │Algorithms│  │   Types    │ │
│  └─────────┘  └──────────┘  └────────────┘ │
└─────────────────────────────────────────────┘
                     ↓ ↑
                 HTTPS/WSS
                     ↓ ↑
┌─────────────────────────────────────────────┐
│       Supabase (Backend as a Service)       │
│  ┌──────────┐  ┌──────────┐  ┌───────────┐ │
│  │PostgreSQL│  │   Auth   │  │  Storage  │ │
│  │    +     │  │  System  │  │  Buckets  │ │
│  │   RLS    │  │          │  │           │ │
│  └──────────┘  └──────────┘  └───────────┘ │
│  ┌──────────┐  ┌──────────┐                │
│  │   Edge   │  │Realtime  │                │
│  │Functions │  │Subscript │                │
│  └──────────┘  └──────────┘                │
└─────────────────────────────────────────────┘
```

### Flujo de Datos

1. **Autenticación**: Usuario → Auth Context → Supabase Auth
2. **Consultas**: Componente → Hook → Supabase Client → PostgreSQL
3. **Optimización**: Datos → Algoritmos (Frontend) → Visualización
4. **Tiempo Real**: Base de Datos → Realtime → React State → UI

---

## Stack Tecnológico

### Frontend

```json
{
  "framework": "React 18.3.1",
  "language": "TypeScript 5.5.3",
  "bundler": "Vite 5.4.2",
  "styling": "Tailwind CSS 3.4.1",
  "icons": "Lucide React 0.344.0",
  "http": "Supabase JS Client 2.57.4"
}
```

### Backend

```json
{
  "database": "PostgreSQL (Supabase)",
  "authentication": "Supabase Auth",
  "storage": "Supabase Storage",
  "functions": "Supabase Edge Functions",
  "realtime": "Supabase Realtime"
}
```

### DevOps

```json
{
  "hosting": "Netlify",
  "version_control": "Git",
  "ci_cd": "Netlify Build",
  "environment": "Node.js 18+"
}
```

---

## Estructura del Proyecto

```
taller-vidrieria/
├── src/
│   ├── components/              # Componentes React
│   │   ├── Dashboard.tsx        # Panel principal
│   │   ├── OrderBoard.tsx       # Gestión de pedidos
│   │   ├── CustomerList.tsx     # Lista de clientes
│   │   ├── CustomerModal.tsx    # Modal de cliente
│   │   ├── InventoryManagement.tsx   # Gestión de inventario
│   │   ├── MaterialAssignment.tsx    # Asignación de material
│   │   ├── CuttingExecution.tsx      # Ejecución de cortes
│   │   ├── InputPanel.tsx       # Panel de entrada (optimizador)
│   │   ├── VisualizationPanel.tsx    # Visualización de cortes
│   │   ├── AddSheetModal.tsx    # Modal agregar placa
│   │   ├── AuthModal.tsx        # Modal de autenticación
│   │   ├── UserProfilePanel.tsx # Panel de perfil
│   │   ├── ProjectModal.tsx     # Modal de proyectos
│   │   ├── OrderCard.tsx        # Tarjeta de pedido
│   │   ├── OrdersListView.tsx   # Vista lista de pedidos
│   │   ├── SVGOrderImportModal.tsx  # Importar SVG
│   │   └── DimensionReferenceModal.tsx  # Referencia dimensiones
│   │
│   ├── contexts/
│   │   └── AuthContext.tsx      # Contexto de autenticación
│   │
│   ├── hooks/
│   │   └── useOrders.ts         # Hook personalizado de pedidos
│   │
│   ├── lib/
│   │   └── supabase.ts          # Cliente de Supabase
│   │
│   ├── utils/                   # Utilidades
│   │   ├── algorithms/          # Algoritmos de optimización
│   │   │   ├── guillotine.ts    # Algoritmo Guillotine
│   │   │   ├── maxrects.ts      # Algoritmo MaxRects
│   │   │   ├── skyline.ts       # Algoritmo Skyline
│   │   │   ├── patternGuillotine.ts  # Pattern Guillotine
│   │   │   ├── optimizer.ts     # Optimizador principal
│   │   │   └── sorting.ts       # Funciones de ordenamiento
│   │   ├── packing.ts           # Empaquetado de cortes
│   │   ├── remnants.ts          # Cálculo de desperdicios
│   │   ├── validation.ts        # Validaciones
│   │   ├── materialSuggestions.ts  # Sugerencias de material
│   │   └── svgOrderParser.ts    # Parser de SVG
│   │
│   ├── types.ts                 # Definiciones TypeScript
│   ├── App.tsx                  # Componente principal
│   ├── main.tsx                 # Entry point
│   └── index.css                # Estilos globales
│
├── supabase/
│   ├── migrations/              # Migraciones de BD
│   │   ├── 20251210150629_create_glass_cutting_projects.sql
│   │   ├── 20251210151619_add_thickness_and_cutting_method.sql
│   │   ├── 20251211125355_add_user_roles_and_auth.sql
│   │   ├── 20251211131456_create_customers_table.sql
│   │   ├── 20251211131529_transform_projects_to_orders.sql
│   │   ├── 20251211131624_create_order_items_and_materials_catalog.sql
│   │   ├── 20251211160318_create_material_inventory_system.sql
│   │   ├── 20251211160346_update_orders_for_material_tracking.sql
│   │   ├── 20251216131341_add_svg_import_support.sql
│   │   ├── 20251216131533_create_order_documents_storage_bucket.sql
│   │   ├── 20251216140849_fix_security_and_performance_issues.sql
│   │   ├── 20251216141108_add_foreign_key_indexes.sql
│   │   ├── 20251216142409_optimize_rls_policies_performance.sql
│   │   └── 20251216173107_add_demo_seed_data.sql
│   │
│   └── functions/               # Edge Functions
│       ├── setup-demo-users/
│       │   └── index.ts
│       └── reset-demo-passwords/
│           └── index.ts
│
├── public/                      # Archivos estáticos
├── .env                         # Variables de entorno (no en git)
├── .env.example                 # Plantilla de variables
├── package.json                 # Dependencias NPM
├── tsconfig.json                # Configuración TypeScript
├── vite.config.ts               # Configuración Vite
├── tailwind.config.js           # Configuración Tailwind
├── netlify.toml                 # Configuración Netlify
└── README.md                    # Documentación principal
```

---

## Base de Datos

### Esquema de Base de Datos

#### Tabla: `user_profiles`

Almacena perfiles de usuario y roles.

```sql
CREATE TABLE user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  role text NOT NULL DEFAULT 'operator',
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),

  CONSTRAINT valid_role CHECK (role IN ('admin', 'operator', 'client'))
);
```

**Índices:**
```sql
CREATE INDEX idx_user_profiles_role ON user_profiles(role);
CREATE INDEX idx_user_profiles_email ON user_profiles(email);
```

#### Tabla: `customers`

Almacena información de clientes.

```sql
CREATE TABLE customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL,
  phone text NOT NULL,
  email text NOT NULL,
  address text NOT NULL,
  customer_type text NOT NULL DEFAULT 'individual',
  notes text DEFAULT '',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),

  CONSTRAINT valid_customer_type CHECK (customer_type IN ('individual', 'company'))
);
```

**Índices:**
```sql
CREATE INDEX idx_customers_user_id ON customers(user_id);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_created_at ON customers(created_at DESC);
```

#### Tabla: `orders`

Almacena pedidos de trabajo.

```sql
CREATE TABLE orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  order_number text NOT NULL,
  name text NOT NULL,
  status text NOT NULL DEFAULT 'quoted',
  notes text DEFAULT '',

  -- Dimensiones de placa
  sheet_width numeric NOT NULL,
  sheet_height numeric NOT NULL,
  cut_thickness numeric NOT NULL DEFAULT 3,
  glass_thickness numeric NOT NULL DEFAULT 4,
  cutting_method text NOT NULL DEFAULT 'manual',

  -- Datos de cortes (JSONB)
  cuts jsonb NOT NULL DEFAULT '[]',

  -- Fechas
  quote_date timestamptz DEFAULT now(),
  approved_date timestamptz,
  promised_date timestamptz,
  delivered_date timestamptz,

  -- Costos
  subtotal_materials numeric DEFAULT 0,
  subtotal_labor numeric DEFAULT 0,
  discount_amount numeric DEFAULT 0,
  total_amount numeric DEFAULT 0,

  -- Tracking de material
  material_status text DEFAULT 'pending',
  cutting_plan jsonb DEFAULT '{}',
  assigned_sheets text[] DEFAULT '{}',
  optimization_id uuid,
  estimated_waste numeric DEFAULT 0,
  actual_waste numeric DEFAULT 0,
  material_cost numeric DEFAULT 0,

  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),

  CONSTRAINT valid_status CHECK (status IN ('quoted', 'approved', 'in_production', 'ready', 'delivered', 'cancelled')),
  CONSTRAINT valid_cutting_method CHECK (cutting_method IN ('manual', 'machine')),
  CONSTRAINT valid_material_status CHECK (material_status IN ('pending', 'assigned', 'cutting', 'completed'))
);
```

**Índices:**
```sql
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_order_number ON orders(order_number);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_material_status ON orders(material_status);
```

#### Tabla: `material_sheets`

Inventario de placas y láminas.

```sql
CREATE TABLE material_sheets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Tipo de material
  material_type text NOT NULL,
  glass_type_id uuid,
  thickness numeric NOT NULL,

  -- Dimensiones
  width numeric NOT NULL,
  height numeric NOT NULL,
  area_total numeric GENERATED ALWAYS AS (width * height) STORED,

  -- Origen
  origin text NOT NULL DEFAULT 'purchase',
  parent_sheet_id uuid REFERENCES material_sheets(id),
  source_order_id uuid REFERENCES orders(id),

  -- Estado
  status text NOT NULL DEFAULT 'available',

  -- Información de compra
  purchase_date date DEFAULT CURRENT_DATE,
  purchase_cost numeric DEFAULT 0,
  supplier text DEFAULT '',
  notes text DEFAULT '',

  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),

  CONSTRAINT valid_material_type CHECK (material_type IN ('glass', 'mirror', 'aluminum')),
  CONSTRAINT valid_origin CHECK (origin IN ('purchase', 'remnant')),
  CONSTRAINT valid_status CHECK (status IN ('available', 'reserved', 'used', 'damaged'))
);
```

**Índices:**
```sql
CREATE INDEX idx_material_sheets_user_id ON material_sheets(user_id);
CREATE INDEX idx_material_sheets_status ON material_sheets(status);
CREATE INDEX idx_material_sheets_material_type ON material_sheets(material_type);
CREATE INDEX idx_material_sheets_thickness ON material_sheets(thickness);
CREATE INDEX idx_material_sheets_origin ON material_sheets(origin);
```

#### Tabla: `sheet_assignments`

Asignaciones de material a pedidos.

```sql
CREATE TABLE sheet_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  sheet_id uuid NOT NULL REFERENCES material_sheets(id) ON DELETE CASCADE,
  assigned_date timestamptz DEFAULT now(),
  assigned_by uuid REFERENCES auth.users(id),

  cuts_assigned jsonb NOT NULL DEFAULT '[]',
  status text NOT NULL DEFAULT 'pending',

  utilization_percentage numeric DEFAULT 0,
  waste_area numeric DEFAULT 0,

  completed_date timestamptz,
  created_at timestamptz DEFAULT now(),

  CONSTRAINT valid_assignment_status CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled'))
);
```

**Índices:**
```sql
CREATE INDEX idx_sheet_assignments_order_id ON sheet_assignments(order_id);
CREATE INDEX idx_sheet_assignments_sheet_id ON sheet_assignments(sheet_id);
CREATE INDEX idx_sheet_assignments_status ON sheet_assignments(status);
```

### Row Level Security (RLS)

Todas las tablas implementan RLS para proteger datos.

#### Políticas de Seguridad

**user_profiles:**
```sql
-- Los usuarios solo pueden ver su propio perfil
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Los usuarios pueden actualizar su propio perfil
CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
```

**customers:**
```sql
-- Los usuarios solo ven sus propios clientes
CREATE POLICY "Users can view own customers"
  ON customers FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Los usuarios pueden crear clientes
CREATE POLICY "Users can insert own customers"
  ON customers FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Los usuarios pueden actualizar sus clientes
CREATE POLICY "Users can update own customers"
  ON customers FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Los usuarios pueden eliminar sus clientes
CREATE POLICY "Users can delete own customers"
  ON customers FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);
```

**orders:**
```sql
-- Similar a customers, con permisos basados en user_id
CREATE POLICY "Users can manage own orders"
  ON orders FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

**material_sheets:**
```sql
-- Similar a customers, con permisos basados en user_id
CREATE POLICY "Users can manage own inventory"
  ON material_sheets FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

---

## Autenticación y Seguridad

### Configuración de Supabase Auth

El sistema usa Supabase Auth con email/password.

#### Cliente de Supabase

`src/lib/supabase.ts`:
```typescript
import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true
  }
});
```

#### Contexto de Autenticación

`src/contexts/AuthContext.tsx`:
```typescript
interface AuthContextType {
  user: User | null;
  profile: UserProfile | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, fullName: string) => Promise<void>;
  signOut: () => Promise<void>;
}

export const AuthProvider: React.FC = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Obtener sesión actual
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchProfile(session.user.id);
      } else {
        setLoading(false);
      }
    });

    // Escuchar cambios de autenticación
    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setUser(session?.user ?? null);
        if (session?.user) {
          fetchProfile(session.user.id);
        } else {
          setProfile(null);
          setLoading(false);
        }
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  // ... resto del código
};
```

### Flujo de Autenticación

1. **Sign Up**:
   ```typescript
   const { data, error } = await supabase.auth.signUp({
     email,
     password,
     options: {
       data: { full_name: fullName }
     }
   });
   ```

2. **Sign In**:
   ```typescript
   const { data, error } = await supabase.auth.signInWithPassword({
     email,
     password
   });
   ```

3. **Sign Out**:
   ```typescript
   const { error } = await supabase.auth.signOut();
   ```

### Protección de Rutas

Los componentes verifican autenticación:
```typescript
const { profile } = useAuth();

if (!profile) {
  return <div>Debe iniciar sesión</div>;
}
```

---

## Algoritmos de Optimización

El sistema implementa múltiples algoritmos para optimizar el corte de vidrio.

### 1. Algoritmo Guillotine

**Ubicación**: `src/utils/algorithms/guillotine.ts`

**Descripción**: Realiza cortes rectilíneos (guillotina) que dividen completamente la placa.

**Complejidad**: O(n log n)

```typescript
export function guillotinePack(
  cuts: Cut[],
  sheetWidth: number,
  sheetHeight: number,
  cutThickness: number
): PlacedCut[] {
  // Ordenar cortes por área descendente
  const sortedCuts = sortByArea(cuts);

  // Espacios libres disponibles
  const freeRects: Rectangle[] = [{
    x: 0,
    y: 0,
    width: sheetWidth,
    height: sheetHeight
  }];

  const placed: PlacedCut[] = [];

  for (const cut of sortedCuts) {
    // Buscar mejor espacio libre
    const bestRect = findBestFit(cut, freeRects, cutThickness);

    if (bestRect) {
      // Colocar corte
      placed.push({
        cut,
        x: bestRect.x,
        y: bestRect.y,
        width: cut.width,
        height: cut.height,
        rotated: false
      });

      // Dividir espacio (corte guillotina)
      splitFreeRect(bestRect, cut, freeRects, cutThickness);
    }
  }

  return placed;
}
```

### 2. Algoritmo MaxRects

**Ubicación**: `src/utils/algorithms/maxrects.ts`

**Descripción**: Mantiene lista de rectángulos libres y usa heurísticas para colocación óptima.

**Heurísticas**:
- Best Short Side Fit (BSSF)
- Best Long Side Fit (BLSF)
- Best Area Fit (BAF)
- Bottom-Left (BL)

```typescript
export function maxRectsPack(
  cuts: Cut[],
  sheetWidth: number,
  sheetHeight: number,
  cutThickness: number
): PlacedCut[] {
  const freeRects: Rectangle[] = [{
    x: 0,
    y: 0,
    width: sheetWidth,
    height: sheetHeight
  }];

  const placed: PlacedCut[] = [];
  const sortedCuts = sortByArea(cuts);

  for (const cut of sortedCuts) {
    let bestScore = Infinity;
    let bestRect: Rectangle | null = null;
    let bestRotated = false;

    // Probar todas las posiciones y rotaciones
    for (const rect of freeRects) {
      // Sin rotación
      const score1 = scorePosition(cut, rect, false);
      if (score1 < bestScore && fits(cut, rect, false, cutThickness)) {
        bestScore = score1;
        bestRect = rect;
        bestRotated = false;
      }

      // Con rotación
      const score2 = scorePosition(cut, rect, true);
      if (score2 < bestScore && fits(cut, rect, true, cutThickness)) {
        bestScore = score2;
        bestRect = rect;
        bestRotated = true;
      }
    }

    if (bestRect) {
      // Colocar corte
      const width = bestRotated ? cut.height : cut.width;
      const height = bestRotated ? cut.width : cut.height;

      placed.push({
        cut,
        x: bestRect.x,
        y: bestRect.y,
        width,
        height,
        rotated: bestRotated
      });

      // Actualizar rectángulos libres
      updateFreeRects(freeRects, bestRect, width, height, cutThickness);
    }
  }

  return placed;
}
```

### 3. Algoritmo Skyline

**Ubicación**: `src/utils/algorithms/skyline.ts`

**Descripción**: Mantiene una "línea de horizonte" y coloca piezas sobre ella.

```typescript
interface SkylineSegment {
  x: number;
  y: number;
  width: number;
}

export function skylinePack(
  cuts: Cut[],
  sheetWidth: number,
  sheetHeight: number,
  cutThickness: number
): PlacedCut[] {
  // Inicializar línea de horizonte
  const skyline: SkylineSegment[] = [{
    x: 0,
    y: 0,
    width: sheetWidth
  }];

  const placed: PlacedCut[] = [];
  const sortedCuts = sortByHeight(cuts);

  for (const cut of sortedCuts) {
    let bestY = Infinity;
    let bestIndex = -1;
    let bestRotated = false;

    // Buscar mejor posición en la línea de horizonte
    for (let i = 0; i < skyline.length; i++) {
      const { x, y, width } = skyline[i];

      // Verificar si cabe sin rotación
      if (cut.width + cutThickness <= width && y < bestY) {
        bestY = y;
        bestIndex = i;
        bestRotated = false;
      }

      // Verificar si cabe con rotación
      if (cut.height + cutThickness <= width && y < bestY) {
        bestY = y;
        bestIndex = i;
        bestRotated = true;
      }
    }

    if (bestIndex !== -1) {
      // Colocar corte
      const segment = skyline[bestIndex];
      const width = bestRotated ? cut.height : cut.width;
      const height = bestRotated ? cut.width : cut.height;

      placed.push({
        cut,
        x: segment.x,
        y: segment.y,
        width,
        height,
        rotated: bestRotated
      });

      // Actualizar línea de horizonte
      updateSkyline(skyline, bestIndex, width, height, cutThickness);
    }
  }

  return placed;
}
```

### 4. Optimizador Principal

**Ubicación**: `src/utils/algorithms/optimizer.ts`

**Descripción**: Ejecuta todos los algoritmos y selecciona el mejor resultado.

```typescript
export function optimizeCutting(
  cuts: Cut[],
  sheet: Sheet
): PackingResult {
  const results: PackingResult[] = [];

  // Ejecutar todos los algoritmos
  results.push({
    method: 'Guillotine',
    placedCuts: guillotinePack(cuts, sheet.width, sheet.height, sheet.cutThickness),
    utilization: 0
  });

  results.push({
    method: 'MaxRects',
    placedCuts: maxRectsPack(cuts, sheet.width, sheet.height, sheet.cutThickness),
    utilization: 0
  });

  results.push({
    method: 'Skyline',
    placedCuts: skylinePack(cuts, sheet.width, sheet.height, sheet.cutThickness),
    utilization: 0
  });

  // Calcular utilización para cada resultado
  results.forEach(result => {
    result.utilization = calculateUtilization(result.placedCuts, sheet);
  });

  // Retornar el mejor resultado
  return results.reduce((best, current) =>
    current.utilization > best.utilization ? current : best
  );
}
```

### Cálculo de Utilización

```typescript
function calculateUtilization(
  placedCuts: PlacedCut[],
  sheet: Sheet
): number {
  const totalArea = sheet.width * sheet.height;

  const usedArea = placedCuts.reduce((sum, placed) => {
    return sum + (placed.width * placed.height);
  }, 0);

  return (usedArea / totalArea) * 100;
}
```

---

## API y Servicios

### Consultas Supabase

#### Obtener Pedidos

```typescript
const { data: orders, error } = await supabase
  .from('orders')
  .select(`
    *,
    customer:customers(*)
  `)
  .eq('user_id', userId)
  .order('created_at', { ascending: false });
```

#### Crear Pedido

```typescript
const { data, error } = await supabase
  .from('orders')
  .insert([{
    user_id: userId,
    customer_id: customerId,
    order_number: generateOrderNumber(),
    name: orderName,
    status: 'quoted',
    sheet_width: 200,
    sheet_height: 300,
    cut_thickness: 3,
    glass_thickness: 4,
    cutting_method: 'manual',
    cuts: cutsArray
  }])
  .select()
  .single();
```

#### Actualizar Estado de Pedido

```typescript
const { error } = await supabase
  .from('orders')
  .update({ status: 'approved' })
  .eq('id', orderId);
```

#### Obtener Inventario

```typescript
const { data: sheets, error } = await supabase
  .from('material_sheets')
  .select('*')
  .eq('user_id', userId)
  .eq('status', 'available')
  .order('created_at', { ascending: false });
```

### Hooks Personalizados

#### useOrders

`src/hooks/useOrders.ts`:
```typescript
export function useOrders() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const { profile } = useAuth();

  useEffect(() => {
    if (!profile) return;
    fetchOrders();
  }, [profile]);

  const fetchOrders = async () => {
    setLoading(true);
    const { data, error } = await supabase
      .from('orders')
      .select('*, customer:customers(*)')
      .eq('user_id', profile.id)
      .order('created_at', { ascending: false });

    if (!error && data) {
      setOrders(data);
    }
    setLoading(false);
  };

  const createOrder = async (orderData: Partial<Order>) => {
    const { data, error } = await supabase
      .from('orders')
      .insert([{ ...orderData, user_id: profile.id }])
      .select()
      .single();

    if (!error) {
      await fetchOrders();
      return data;
    }
    throw error;
  };

  const updateOrder = async (orderId: string, updates: Partial<Order>) => {
    const { error } = await supabase
      .from('orders')
      .update(updates)
      .eq('id', orderId);

    if (!error) {
      await fetchOrders();
    } else {
      throw error;
    }
  };

  const deleteOrder = async (orderId: string) => {
    const { error } = await supabase
      .from('orders')
      .delete()
      .eq('id', orderId);

    if (!error) {
      await fetchOrders();
    } else {
      throw error;
    }
  };

  return {
    orders,
    loading,
    fetchOrders,
    createOrder,
    updateOrder,
    deleteOrder
  };
}
```

---

## Componentes React

### Dashboard

**Ubicación**: `src/components/Dashboard.tsx`

**Responsabilidad**: Muestra resumen general del sistema.

**Props**:
```typescript
interface DashboardProps {
  onNavigateToOrders: () => void;
  onNavigateToCustomers: () => void;
  onEditOrder: (order: Order) => void;
  onViewOrder: (order: Order) => void;
}
```

**Estado**:
- Estadísticas de pedidos
- Lista de pedidos recientes
- Alertas de inventario bajo

### OrderBoard

**Ubicación**: `src/components/OrderBoard.tsx`

**Responsabilidad**: Gestión de pedidos tipo Kanban.

**Estados de Pedidos**:
- Cotizado
- Aprobado
- En Producción
- Listo
- Entregado
- Cancelado

**Funcionalidades**:
- Drag & drop entre columnas
- Filtrado por cliente
- Búsqueda
- Creación/edición de pedidos

### InventoryManagement

**Ubicación**: `src/components/InventoryManagement.tsx`

**Responsabilidad**: Gestión de inventario de materiales.

**Funcionalidades**:
- Lista de placas disponibles
- Filtros por material, grosor, estado
- Agregar/editar/eliminar placas
- Ver histórico de uso
- Alertas de stock bajo

### MaterialAssignment

**Ubicación**: `src/components/MaterialAssignment.tsx`

**Responsabilidad**: Asignar material a pedidos.

**Flujo**:
1. Recibe pedido aprobado
2. Busca placas disponibles en inventario
3. Ejecuta algoritmos de optimización
4. Muestra sugerencias con utilización
5. Permite selección manual
6. Confirma asignación
7. Actualiza estado de pedido y material

### CuttingExecution

**Ubicación**: `src/components/CuttingExecution.tsx`

**Responsabilidad**: Ejecutar proceso de corte.

**Funcionalidades**:
- Visualización de plan de corte
- Instrucciones paso a paso
- Marcado de piezas completadas
- Registro de piezas fallidas
- Cálculo de desperdicios
- Creación automática de remnants

---

## Configuración y Despliegue

### Variables de Entorno

`.env`:
```bash
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu-anon-key
```

### Desarrollo Local

```bash
# Instalar dependencias
npm install

# Iniciar servidor de desarrollo
npm run dev

# El sitio estará disponible en http://localhost:5173
```

### Build de Producción

```bash
# Compilar para producción
npm run build

# Previsualizar build
npm run preview
```

### Despliegue en Netlify

**netlify.toml**:
```toml
[build]
  command = "npm run build"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[build.environment]
  NODE_VERSION = "18"
```

**Variables de Entorno en Netlify**:
1. Ir a Site Settings → Environment Variables
2. Agregar:
   - `VITE_SUPABASE_URL`
   - `VITE_SUPABASE_ANON_KEY`

**Despliegue Automático**:
- Push a rama `main` → Deploy automático
- Pull requests → Preview deploys

### Migraciones de Base de Datos

Las migraciones deben aplicarse en orden cronológico:

```bash
# Conectar a Supabase
supabase link --project-ref tu-proyecto

# Aplicar migraciones
supabase db push

# O aplicar manualmente en Supabase Dashboard → SQL Editor
```

---

## Desarrollo y Testing

### Convenciones de Código

**TypeScript**:
- Usar tipos explícitos
- Evitar `any`
- Interfaces para objetos complejos
- Enums para valores fijos

**React**:
- Componentes funcionales con hooks
- Props tipadas con TypeScript
- Nombres descriptivos
- Separación de lógica y presentación

**CSS**:
- Tailwind CSS para estilos
- Clases utilitarias
- Responsive design mobile-first
- Evitar estilos inline

### Estructura de Componentes

```typescript
// Imports
import { useState, useEffect } from 'react';
import { Component1, Component2 } from './components';
import { useCustomHook } from './hooks';
import { Type1, Type2 } from './types';

// Types/Interfaces
interface ComponentProps {
  prop1: string;
  prop2: number;
  onAction: () => void;
}

// Component
export function Component({ prop1, prop2, onAction }: ComponentProps) {
  // State
  const [state1, setState1] = useState<Type1>(initialValue);

  // Effects
  useEffect(() => {
    // Effect logic
  }, [dependencies]);

  // Handlers
  const handleAction = () => {
    // Handler logic
  };

  // Render
  return (
    <div>
      {/* JSX */}
    </div>
  );
}
```

### Type Checking

```bash
# Verificar tipos sin compilar
npm run typecheck
```

### Linting

```bash
# Ejecutar ESLint
npm run lint
```

### Testing Manual

Escenarios de prueba recomendados:

1. **Autenticación**:
   - Login exitoso
   - Login fallido
   - Registro nuevo usuario
   - Logout

2. **Pedidos**:
   - Crear pedido
   - Editar pedido
   - Cambiar estado
   - Eliminar pedido
   - Filtrar por estado

3. **Optimizador**:
   - Agregar cortes
   - Diferentes tamaños de placa
   - Múltiples cantidades
   - Rotación de piezas
   - Visualización correcta

4. **Inventario**:
   - Agregar placa
   - Editar placa
   - Cambiar estado
   - Filtros
   - Asignación a pedido

5. **Ejecución**:
   - Asignar material
   - Seguir instrucciones
   - Registrar piezas
   - Generar desperdicios

---

## Troubleshooting

### Problemas Comunes

#### Error: "Invalid API key"

**Causa**: Variables de entorno incorrectas o no cargadas.

**Solución**:
```bash
# Verificar .env
cat .env

# Reiniciar servidor de desarrollo
npm run dev
```

#### Error: "Row Level Security policy violation"

**Causa**: Políticas RLS bloqueando acceso.

**Solución**:
1. Verificar que el usuario esté autenticado
2. Revisar políticas en Supabase Dashboard
3. Asegurarse de que `user_id` coincida con `auth.uid()`

#### Build falla en Netlify

**Causa**: Variables de entorno no configuradas en Netlify.

**Solución**:
1. Ir a Site Settings → Environment Variables
2. Agregar todas las variables necesarias
3. Hacer redeploy

#### Optimizador no muestra cortes

**Causa**:
- Cortes demasiado grandes para la placa
- Grosor de disco demasiado grande
- Error en algoritmo

**Solución**:
1. Verificar dimensiones de placa
2. Reducir grosor de disco
3. Revisar consola del navegador para errores

#### Inventario no actualiza

**Causa**: Error en consulta o RLS.

**Solución**:
1. Abrir consola del navegador
2. Verificar errores de red
3. Revisar políticas RLS en Supabase
4. Refrescar la página

### Logs y Debugging

**Frontend**:
```typescript
// Habilitar logs detallados
console.log('Estado actual:', state);
console.table(array);
```

**Supabase**:
```typescript
// Ver queries en consola
const { data, error } = await supabase
  .from('table')
  .select('*');

console.log('Query result:', { data, error });
```

**Network**:
- Abrir DevTools → Network
- Filtrar por "supabase"
- Revisar requests/responses

### Performance

**Optimizaciones**:

1. **Memoización**:
```typescript
const memoizedValue = useMemo(() =>
  computeExpensiveValue(a, b),
  [a, b]
);
```

2. **Callbacks**:
```typescript
const memoizedCallback = useCallback(() => {
  doSomething(a, b);
}, [a, b]);
```

3. **Lazy Loading**:
```typescript
const Component = lazy(() => import('./Component'));
```

4. **Índices de Base de Datos**:
- Asegurarse de que existan índices para columnas frecuentemente consultadas
- Revisar query performance en Supabase Dashboard

---

## Mantenimiento

### Actualizaciones de Dependencias

```bash
# Ver dependencias desactualizadas
npm outdated

# Actualizar dependencias menores
npm update

# Actualizar dependencias mayores (con cuidado)
npm install package@latest
```

### Backups de Base de Datos

Supabase realiza backups automáticos, pero puedes hacer backups manuales:

```bash
# Exportar schema
supabase db dump > backup_schema.sql

# Exportar datos
supabase db dump --data-only > backup_data.sql
```

### Monitoreo

**Métricas a monitorear**:
- Tiempo de respuesta de queries
- Tasa de errores
- Uso de recursos (CPU, memoria)
- Número de usuarios activos
- Tamaño de base de datos

**Herramientas**:
- Supabase Dashboard → Logs
- Netlify Analytics
- Browser DevTools

---

## Roadmap y Mejoras Futuras

### Funcionalidades Planificadas

1. **Reportes y Analytics**:
   - Dashboard con gráficos
   - Reportes de ventas
   - Análisis de desperdicio
   - Exportar a PDF/Excel

2. **Integración con Hardware**:
   - Control de máquinas de corte CNC
   - Códigos G para corte automático
   - Sensores de inventario

3. **App Móvil**:
   - React Native
   - Sincronización offline
   - Notificaciones push

4. **Mejoras de Algoritmos**:
   - Machine Learning para predicción
   - Optimización multi-placa
   - Sugerencias inteligentes

5. **Colaboración**:
   - Múltiples usuarios simultáneos
   - Chat en tiempo real
   - Historial de cambios

---

## Contacto y Soporte

Para soporte técnico o consultas:

- **Documentación**: Ver README.md
- **Issues**: GitHub Issues
- **Email**: [tu-email@example.com]

---

**Última actualización**: Diciembre 2024
**Versión**: 1.0.0
**Autor**: [Tu Nombre]
