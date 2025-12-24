# Migración de Supabase a PostgreSQL Externo

## Estado Actual

Se ha completado la mayor parte de la migración para reemplazar Supabase con tu base de datos PostgreSQL externa:

### ✅ Completado

1. **Backend API con Express**
   - Servidor API REST en `server/index.ts`
   - Configuración de PostgreSQL con SSL en `server/config/database.ts`
   - Rutas de autenticación (login, registro, logout)
   - Rutas para customers, orders, materials
   - Middleware de autenticación JWT
   - Sistema de roles (admin/operator)

2. **Autenticación JWT**
   - Sistema de tokens JWT reemplazando Supabase Auth
   - AuthContext actualizado para usar API REST
   - Cliente API genérico en `src/lib/api.ts`

3. **Esquema de Base de Datos**
   - Script SQL completo en `server/database/schema.sql`
   - Script de migración en `server/database/migrate.ts`
   - Usuarios por defecto incluidos

### ⚠️ Problema Actual: Conexión a Base de Datos

El servidor PostgreSQL en `178.128.177.81:5432` está rechazando conexiones. Necesitas:

1. **Verificar que PostgreSQL esté ejecutándose**
   ```bash
   systemctl status postgresql
   ```

2. **Verificar que PostgreSQL acepta conexiones remotas**

   Edita `/etc/postgresql/[version]/main/postgresql.conf`:
   ```
   listen_addresses = '*'
   ```

3. **Configurar pg_hba.conf para permitir tu IP**

   Edita `/etc/postgresql/[version]/main/pg_hba.conf`:
   ```
   # Permitir conexiones con SSL
   hostssl all all 0.0.0.0/0 md5
   ```

4. **Reiniciar PostgreSQL**
   ```bash
   systemctl restart postgresql
   ```

5. **Verificar firewall**
   ```bash
   ufw allow 5432/tcp
   ```

### 🔄 Pasos Siguientes

Una vez que la base de datos esté accesible:

1. **Ejecutar migración**
   ```bash
   npm run migrate
   ```

   Esto creará:
   - Tablas: user_profiles, customers, orders, order_items, materials_catalog, material_inventory
   - Usuarios por defecto:
     - Admin: admin@vidrieriataller.com / admin123
     - Operador: operador@vidrieriataller.com / operator123

2. **Actualizar componentes restantes**
   - Reemplazar llamadas de Supabase por llamadas a la API REST
   - Actualizar referencias de `profile` a `user`
   - Eliminar importaciones de `@supabase/supabase-js`

3. **Iniciar servidores**
   ```bash
   # Terminal 1: Servidor backend
   npm run dev:server

   # Terminal 2: Servidor frontend
   npm run dev
   ```

4. **Eliminar dependencias de Supabase**
   ```bash
   npm uninstall @supabase/supabase-js
   ```

## Archivos Creados

### Backend
- `server/index.ts` - Servidor Express principal
- `server/config/database.ts` - Configuración PostgreSQL con SSL
- `server/middleware/auth.ts` - Middleware de autenticación JWT
- `server/routes/auth.ts` - Rutas de autenticación
- `server/routes/customers.ts` - CRUD de clientes
- `server/routes/orders.ts` - CRUD de pedidos
- `server/routes/materials.ts` - CRUD de materiales e inventario
- `server/database/schema.sql` - Esquema completo de BD
- `server/database/migrate.ts` - Script de migración
- `server/database/test-connection.ts` - Test de conexión a BD

### Frontend
- `src/lib/api.ts` - Cliente API REST con gestión de tokens
- `src/contexts/AuthContext.tsx` - Actualizado para usar JWT

### Configuración
- `.env` - Variables de entorno actualizadas
- `tsconfig.server.json` - TypeScript config para backend
- `package.json` - Dependencias actualizadas (express, pg, bcryptjs, jsonwebtoken)

## Probar Conexión

```bash
npm run test:connection
```

Agrega este script a package.json:
```json
"test:connection": "npx tsx server/database/test-connection.ts"
```

## Credenciales Configuradas

```
Host: 178.128.177.81
Port: 5432
Usuario: postgres
Base de datos: VidrieriaTaller
SSL: Habilitado
```

## Siguiente Fase

Una vez que resuelvas el problema de conexión, avísame y continuaré con:
- Actualización de todos los componentes React
- Eliminación completa de código de Supabase
- Pruebas de integración
- Build final
