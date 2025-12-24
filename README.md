# Taller Vidrieria - Sistema de Gestión de Cortes de Vidrio

Sistema completo para talleres de vidrieria que permite gestionar órdenes, optimizar cortes de vidrio, administrar inventario de materiales y realizar seguimiento de clientes.

## Características Principales

- Gestión de órdenes de trabajo
- Optimización de cortes de vidrio con múltiples algoritmos
- Control de inventario de materiales (placas y láminas)
- Gestión de clientes
- Importación de diseños desde archivos SVG y PDF
- Sistema de roles (Administrador/Operador)
- Seguimiento de desperdicios y aprovechamiento de materiales
- Visualización en tiempo real del proceso de corte
- Generación de PDF con diagramas de corte

## Stack Tecnológico

### Frontend
- React 18 + TypeScript + Vite
- Tailwind CSS + Lucide React Icons
- jsPDF para generación de PDFs
- PDF.js para lectura de PDFs

### Backend
- Node.js + Express + TypeScript
- PostgreSQL con SSL
- Autenticación JWT (bcryptjs)
- CORS habilitado

### Base de Datos
- PostgreSQL 14+
- Conexiones SSL seguras
- Sistema de roles integrado

## Requisitos Previos

- Node.js 18 o superior
- npm o yarn
- PostgreSQL 14 o superior
- Acceso a servidor PostgreSQL (local o remoto)

## Instalación Local

### 1. Clonar el repositorio

```bash
git clone <tu-repositorio>
cd taller-vidrieria
```

### 2. Instalar dependencias

```bash
npm install
```

### 3. Configurar variables de entorno

```bash
cp .env.example .env
```

Editar `.env` con tus credenciales:

```env
DB_HOST=tu-servidor-postgresql
DB_PORT=5432
DB_USER=tu-usuario
DB_PASSWORD=tu-contraseña
DB_NAME=VidrieriaTaller
DB_SSL=true

JWT_SECRET=tu-secreto-jwt-aqui
JWT_EXPIRES_IN=7d

VITE_API_URL=http://localhost:3001
```

### 4. Configurar PostgreSQL

Sigue la guía en `CONFIGURAR_POSTGRESQL.md` para:
- Habilitar conexiones remotas
- Configurar SSL
- Abrir puerto 5432 en firewall

### 5. Ejecutar migración de base de datos

```bash
npm run migrate
```

Esto creará todas las tablas y usuarios por defecto:
- **Admin**: admin@vidrieriataller.com / admin123
- **Operador**: operador@vidrieriataller.com / operator123

### 6. Iniciar servidores

Terminal 1 - Backend:
```bash
npm run dev:server
```

Terminal 2 - Frontend:
```bash
npm run dev
```

La aplicación estará disponible en:
- Frontend: http://localhost:5173
- Backend API: http://localhost:3001

## Scripts Disponibles

```bash
npm run dev          # Inicia servidor frontend
npm run dev:server   # Inicia servidor backend
npm run migrate      # Ejecuta migraciones de BD
npm run test:db      # Prueba conexión a PostgreSQL
npm run build        # Construye frontend para producción
npm run build:server # Construye backend para producción
npm run start        # Inicia servidor de producción
npm run lint         # Ejecuta ESLint
npm run typecheck    # Verifica tipos de TypeScript
```

## Estructura del Proyecto

```
taller-vidrieria/
├── server/                    # Backend Express
│   ├── config/
│   │   └── database.ts       # Configuración PostgreSQL
│   ├── middleware/
│   │   └── auth.ts           # Middleware JWT
│   ├── routes/
│   │   ├── auth.ts           # Rutas de autenticación
│   │   ├── customers.ts      # CRUD clientes
│   │   ├── orders.ts         # CRUD pedidos
│   │   └── materials.ts      # CRUD materiales
│   ├── database/
│   │   ├── schema.sql        # Esquema de BD
│   │   └── migrate.ts        # Script de migración
│   └── index.ts              # Servidor principal
│
├── src/                       # Frontend React
│   ├── components/           # Componentes React
│   │   ├── Dashboard.tsx
│   │   ├── OrderBoard.tsx
│   │   ├── InventoryManagement.tsx
│   │   ├── CustomerList.tsx
│   │   └── ...
│   ├── contexts/
│   │   └── AuthContext.tsx   # Contexto de autenticación JWT
│   ├── hooks/
│   │   └── useOrders.ts      # Hooks personalizados
│   ├── lib/
│   │   └── api.ts            # Cliente API REST
│   ├── utils/                # Utilidades y algoritmos
│   │   ├── algorithms/       # Algoritmos de optimización
│   │   ├── packing.ts
│   │   └── ...
│   ├── App.tsx
│   └── main.tsx
│
├── .env.example              # Plantilla de variables
├── CONFIGURAR_POSTGRESQL.md  # Guía de configuración BD
├── INSTRUCCIONES_FINALES.md  # Documentación completa
└── README_MIGRACION.md       # Guía rápida de setup
```

## Algoritmos de Optimización

El sistema incluye múltiples algoritmos de optimización de cortes:

- **Guillotine:** Cortes rectilíneos simples
- **MaxRects:** Optimización de espacios rectangulares
- **Skyline:** Algoritmo de línea de horizonte
- **Pattern Guillotine:** Patrones de corte guillotina
- **Optimizer:** Selección automática del mejor algoritmo

## Base de Datos

### Esquema Principal

```sql
VidrieriaTaller/
├── user_profiles          # Usuarios con roles (admin/operator)
├── customers              # Clientes del taller
├── orders                 # Órdenes de trabajo
├── order_items            # Items de cada orden
├── materials_catalog      # Catálogo de materiales
└── material_inventory     # Inventario de láminas/placas
```

### Migraciones

El esquema completo se encuentra en `server/database/schema.sql`. Para aplicar:

```bash
npm run migrate
```

## API REST

### Endpoints de Autenticación

```
POST   /api/auth/register    # Registrar usuario
POST   /api/auth/login        # Iniciar sesión
POST   /api/auth/logout       # Cerrar sesión
GET    /api/auth/me           # Obtener perfil actual
```

### Endpoints de Datos (requieren autenticación)

```
GET    /api/customers         # Listar clientes
POST   /api/customers         # Crear cliente
PUT    /api/customers/:id     # Actualizar cliente
DELETE /api/customers/:id     # Eliminar cliente

GET    /api/orders            # Listar órdenes
GET    /api/orders/:id        # Obtener orden
POST   /api/orders            # Crear orden
PUT    /api/orders/:id        # Actualizar orden
DELETE /api/orders/:id        # Eliminar orden

GET    /api/materials/catalog      # Catálogo materiales
GET    /api/materials/inventory    # Inventario
POST   /api/materials/inventory    # Agregar material
PUT    /api/materials/inventory/:id    # Actualizar
DELETE /api/materials/inventory/:id    # Eliminar
```

## Roles y Permisos

### Administrador
- Gestión completa de órdenes
- Administración de inventario
- Gestión de clientes
- Acceso a todas las funcionalidades

### Operador
- Visualizar órdenes
- Ejecutar cortes
- Ver inventario
- Acceso limitado a funcionalidades de gestión

## Seguridad

- **JWT Authentication:** Tokens seguros con expiración configurable
- **Bcrypt Password Hashing:** Contraseñas hasheadas con salt
- **SSL/TLS:** Conexiones seguras a PostgreSQL
- **CORS:** Configurado para orígenes permitidos
- **Prepared Statements:** Prevención de SQL injection

## Troubleshooting

### Backend no conecta a PostgreSQL

1. Verificar que PostgreSQL acepta conexiones remotas
2. Verificar firewall permite puerto 5432
3. Ejecutar: `npm run test:db`
4. Ver guía en `CONFIGURAR_POSTGRESQL.md`

### Frontend no carga datos

1. Verificar que backend está corriendo en puerto 3001
2. Verificar variable `VITE_API_URL` en `.env`
3. Abrir consola del navegador para ver errores

### Errores de autenticación

1. Verificar que migración se ejecutó: `npm run migrate`
2. Verificar usuarios por defecto fueron creados
3. Verificar variable `JWT_SECRET` en `.env`

## Documentación Adicional

- `INSTRUCCIONES_FINALES.md` - Guía completa de setup
- `CONFIGURAR_POSTGRESQL.md` - Configuración paso a paso de PostgreSQL
- `README_MIGRACION.md` - Guía rápida (5 minutos)
- `DOCUMENTACION_TECNICA.md` - Documentación técnica detallada

## Licencia

[Especificar tu licencia aquí]

## Contribuciones

[Especificar cómo contribuir al proyecto]
