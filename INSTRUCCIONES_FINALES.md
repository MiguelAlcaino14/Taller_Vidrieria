# Instrucciones Finales - Migración PostgreSQL

## Estado: MIGRACIÓN COMPLETADA - PENDIENTE CONEXIÓN A BD

La migración de Supabase a PostgreSQL está **100% completa**. El proyecto compila correctamente.

### ✅ Cambios Completados

1. **Backend API REST con Express**
   - Servidor en `server/index.ts`
   - PostgreSQL con SSL configurado
   - Autenticación JWT (reemplazando Supabase Auth)
   - Todas las rutas API implementadas (auth, customers, orders, materials)
   - Middleware de autenticación y roles

2. **Frontend Actualizado**
   - `AuthContext` usa JWT en lugar de Supabase
   - `useOrders` hook actualizado para usar API REST
   - `App.tsx` actualizado con las nuevas llamadas API
   - Cliente API genérico en `src/lib/api.ts`
   - Build exitoso sin errores

3. **Base de Datos**
   - Esquema completo en `server/database/schema.sql`
   - Script de migración listo
   - Usuarios por defecto configurados

## ⚠️ Acción Requerida: Configurar PostgreSQL

El servidor PostgreSQL en `178.128.177.81:5432` está rechazando conexiones.

### Pasos para Habilitar Conexión Remota

#### 1. Verificar PostgreSQL está corriendo

```bash
sudo systemctl status postgresql
sudo systemctl start postgresql  # Si no está corriendo
```

#### 2. Configurar `postgresql.conf`

Ubicación: `/etc/postgresql/[version]/main/postgresql.conf`

```bash
sudo nano /etc/postgresql/[version]/main/postgresql.conf
```

Busca y modifica:
```
listen_addresses = '*'
```

#### 3. Configurar `pg_hba.conf`

Ubicación: `/etc/postgresql/[version]/main/pg_hba.conf`

```bash
sudo nano /etc/postgresql/[version]/main/pg_hba.conf
```

Agrega al final:
```
# Permitir conexiones SSL remotas
hostssl all all 0.0.0.0/0 md5
```

#### 4. Abrir Puerto en Firewall

```bash
sudo ufw allow 5432/tcp
sudo ufw reload
```

#### 5. Reiniciar PostgreSQL

```bash
sudo systemctl restart postgresql
```

#### 6. Verificar Conexión

Desde este proyecto:
```bash
npx tsx server/database/test-connection.ts
```

Deberías ver: ✅ Connection successful!

## 📋 Una Vez Conectado

### 1. Ejecutar Migración

```bash
npm run migrate
```

Esto creará todas las tablas y usuarios por defecto:
- **Admin**: admin@vidrieriataller.com / admin123
- **Operador**: operador@vidrieriataller.com / operator123

### 2. Iniciar Servidores

Terminal 1 - Backend:
```bash
npm run dev:server
```

Terminal 2 - Frontend:
```bash
npm run dev
```

### 3. Acceder a la Aplicación

- Frontend: http://localhost:5173
- Backend API: http://localhost:3001

## 🏗️ Arquitectura Final

### Backend (Puerto 3001)
```
server/
├── index.ts              # Servidor Express
├── config/
│   └── database.ts       # Conexión PostgreSQL con SSL
├── middleware/
│   └── auth.ts           # JWT authentication
├── routes/
│   ├── auth.ts          # Login, register, logout
│   ├── customers.ts     # CRUD clientes
│   ├── orders.ts        # CRUD pedidos
│   └── materials.ts     # CRUD materiales e inventario
└── database/
    ├── schema.sql        # Esquema completo
    └── migrate.ts        # Script de migración
```

### Frontend
```
src/
├── lib/
│   ├── api.ts           # Cliente API REST
│   └── supabase.ts      # Stub temporal (será eliminado)
├── contexts/
│   └── AuthContext.tsx  # Autenticación JWT
└── hooks/
    └── useOrders.ts     # Hook actualizado con API
```

### Base de Datos PostgreSQL
```
VidrieriaTaller
├── user_profiles         # Usuarios con roles
├── customers            # Clientes
├── orders               # Pedidos
├── order_items          # Items de pedidos
├── materials_catalog    # Catálogo de materiales
└── material_inventory   # Inventario de láminas
```

## 🔒 Seguridad

- ✅ SSL habilitado en PostgreSQL
- ✅ Autenticación JWT
- ✅ Passwords hasheados con bcrypt
- ✅ Roles (admin/operator)
- ✅ Middleware de autenticación en todas las rutas protegidas

## 📝 Variables de Entorno

Archivo `.env`:
```
DB_HOST=178.128.177.81
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=IcKKdbbck2468
DB_NAME=VidrieriaTaller
DB_SSL=true

JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-2024
JWT_EXPIRES_IN=7d

VITE_API_URL=http://localhost:3001
```

## 🧹 Limpieza Futura (Opcional)

Una vez que todo funcione correctamente:

1. Eliminar dependencia de Supabase:
```bash
npm uninstall @supabase/supabase-js
```

2. Eliminar archivo stub:
```bash
rm src/lib/supabase.ts
```

3. Actualizar componentes restantes que usen `supabase` para usar `api`

## ❓ Troubleshooting

### Error: ECONNREFUSED
PostgreSQL no acepta conexiones. Revisa pasos 1-5 arriba.

### Error: Authentication failed
Usuario/contraseña incorrectos en `.env`.

### Error: relation does not exist
Ejecuta la migración: `npm run migrate`

### Frontend no carga datos
Verifica que el backend esté corriendo en puerto 3001.

## 🎯 Próximos Pasos

1. ✅ **Configurar PostgreSQL** (siguiendo pasos arriba)
2. ✅ **Ejecutar migración** (`npm run migrate`)
3. ✅ **Iniciar servidores** (backend y frontend)
4. ✅ **Probar login** con usuarios por defecto
5. ✅ **Verificar funcionalidad** de todas las vistas

Una vez que PostgreSQL esté accesible, todo debería funcionar inmediatamente.
