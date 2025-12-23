# Taller Vidrieria - Sistema de Gestión de Cortes de Vidrio

Sistema completo para talleres de vidrieria que permite gestionar órdenes, optimizar cortes de vidrio, administrar inventario de materiales y realizar seguimiento de clientes.

## Características Principales

- Gestión de órdenes de trabajo
- Optimización de cortes de vidrio con múltiples algoritmos
- Control de inventario de materiales (placas y láminas)
- Gestión de clientes
- Importación de diseños desde archivos SVG
- Sistema de roles (Administrador/Operador)
- Seguimiento de desperdicios y aprovechamiento de materiales
- Visualización en tiempo real del proceso de corte

## Stack Tecnológico

- **Frontend:** React 18 + TypeScript + Vite
- **UI:** Tailwind CSS + Lucide React Icons
- **Base de Datos:** Supabase (PostgreSQL)
- **Autenticación:** Supabase Auth
- **Storage:** Supabase Storage
- **Despliegue:** Netlify

## Requisitos Previos

- Node.js 18 o superior
- npm o yarn
- Cuenta de Supabase
- Cuenta de Netlify (solo para producción)

## Instalación Local

1. Clonar el repositorio:
```bash
git clone <tu-repositorio>
cd taller-vidrieria
```

2. Instalar dependencias:
```bash
npm install
```

3. Configurar variables de entorno:
```bash
cp .env.example .env
```

4. Editar `.env` con tus credenciales de Supabase:
```bash
VITE_SUPABASE_URL=tu-url-de-supabase
VITE_SUPABASE_ANON_KEY=tu-anon-key
```

5. Iniciar servidor de desarrollo:
```bash
npm run dev
```

## Scripts Disponibles

```bash
npm run dev        # Inicia servidor de desarrollo
npm run build      # Construye para producción
npm run preview    # Vista previa del build de producción
npm run lint       # Ejecuta ESLint
npm run typecheck  # Verifica tipos de TypeScript
```

## Despliegue a Producción

### Configuración de Variables de Entorno en Netlify

**IMPORTANTE:** Si ves una página en blanco después del despliegue, necesitas configurar las variables de entorno.

1. Ve a tu sitio en Netlify
2. Navega a: **Site settings** > **Environment variables**
3. Agrega las siguientes variables:
   - `VITE_SUPABASE_URL` = `https://qydplrdlzfskkogosewa.supabase.co`
   - `VITE_SUPABASE_ANON_KEY` = `[copia la clave del archivo .env local]`
4. Guarda los cambios
5. Ve a **Deploys** y haz clic en **Trigger deploy** > **Deploy site**
6. Espera a que se complete el nuevo despliegue

### Guía Rápida
Ver [PRODUCTION_SETUP.md](./PRODUCTION_SETUP.md) para una guía rápida de 30 minutos.

### Guía Completa
Ver [DEPLOYMENT.md](./DEPLOYMENT.md) para instrucciones detalladas y solución de problemas.

## Estructura del Proyecto

```
taller-vidrieria/
├── src/
│   ├── components/          # Componentes React
│   │   ├── Dashboard.tsx
│   │   ├── OrderBoard.tsx
│   │   ├── InventoryManagement.tsx
│   │   └── ...
│   ├── contexts/            # Contextos de React
│   │   └── AuthContext.tsx
│   ├── hooks/               # Hooks personalizados
│   │   └── useOrders.ts
│   ├── lib/                 # Configuración de librerías
│   │   └── supabase.ts
│   ├── utils/               # Utilidades y algoritmos
│   │   ├── algorithms/      # Algoritmos de optimización
│   │   ├── packing.ts
│   │   └── ...
│   ├── App.tsx
│   └── main.tsx
├── supabase/
│   ├── migrations/          # Migraciones de base de datos
│   └── functions/           # Edge Functions
├── public/
├── .env.example             # Plantilla de variables de entorno
├── netlify.toml             # Configuración de Netlify
├── DEPLOYMENT.md            # Guía completa de despliegue
└── PRODUCTION_SETUP.md      # Guía rápida de configuración
```

## Algoritmos de Optimización

El sistema incluye múltiples algoritmos de optimización de cortes:

- **Guillotine:** Cortes rectilíneos simples
- **MaxRects:** Optimización de espacios rectangulares
- **Skyline:** Algoritmo de línea de horizonte
- **Pattern Guillotine:** Patrones de corte guillotina

## Roles y Permisos

### Administrador
- Gestión completa de órdenes
- Administración de inventario
- Gestión de clientes
- Configuración del sistema
- Acceso a todas las funcionalidades

### Operador
- Visualizar órdenes
- Ejecutar cortes
- Ver inventario
- Acceso limitado a funcionalidades de gestión

## Base de Datos

El proyecto utiliza Supabase con PostgreSQL. Las migraciones se encuentran en `supabase/migrations/` y deben aplicarse en orden cronológico.

### Tablas Principales

- `user_profiles` - Perfiles de usuario y roles
- `customers` - Clientes del taller
- `orders` - Órdenes de trabajo
- `order_items` - Piezas de cada orden
- `materials_catalog` - Catálogo de materiales disponibles
- `material_sheets` - Inventario de placas/láminas
- `sheet_usage` - Registro de uso de materiales

## Seguridad

El proyecto implementa Row Level Security (RLS) en todas las tablas:

- Los usuarios solo pueden acceder a sus propios datos
- Los administradores tienen acceso completo
- Las políticas RLS protegen contra accesos no autorizados
- Todas las conexiones usan HTTPS

## Variables de Entorno

### Desarrollo
```bash
VITE_SUPABASE_URL=https://tu-proyecto-dev.supabase.co
VITE_SUPABASE_ANON_KEY=tu-anon-key-dev
```

### Producción
Las variables se configuran en Netlify:
- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

**IMPORTANTE:** Nunca hagas commit del archivo `.env` con credenciales reales.

## Soporte

Para problemas o preguntas:

1. Revisa la documentación de despliegue
2. Consulta los logs en Supabase y Netlify
3. Revisa issues existentes en el repositorio
4. Crea un nuevo issue con detalles del problema

## Licencia

[Especificar tu licencia aquí]

## Contribuciones

[Especificar cómo contribuir al proyecto]
