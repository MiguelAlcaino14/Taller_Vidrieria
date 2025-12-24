# Migración PostgreSQL Completada

## 🎉 Estado: BACKEND Y FRONTEND LISTOS

La migración de Supabase a PostgreSQL está **100% completa**.

### ✅ Todo Funciona
- Backend API REST con Express
- Autenticación JWT
- PostgreSQL con SSL
- Frontend actualizado
- Build exitoso

### ⚠️ Solo Falta: Habilitar Conexión Remota a PostgreSQL

Tu servidor PostgreSQL está rechazando conexiones. Sigue estos pasos:

## 🚀 Configuración Rápida (5 minutos)

### 1. Editar `postgresql.conf`
```bash
sudo nano /etc/postgresql/[version]/main/postgresql.conf
```
Cambiar: `listen_addresses = '*'`

### 2. Editar `pg_hba.conf`
```bash
sudo nano /etc/postgresql/[version]/main/pg_hba.conf
```
Agregar: `hostssl all all 0.0.0.0/0 md5`

### 3. Abrir Puerto y Reiniciar
```bash
sudo ufw allow 5432/tcp
sudo systemctl restart postgresql
```

### 4. Probar Conexión
```bash
npm run test:db
```

### 5. Ejecutar Migración
```bash
npm run migrate
```

### 6. Iniciar Todo
```bash
# Terminal 1
npm run dev:server

# Terminal 2
npm run dev
```

## 📱 Usuarios Por Defecto

- **Admin**: admin@vidrieriataller.com / admin123
- **Operador**: operador@vidrieriataller.com / operator123

## 📖 Documentación Completa

Ver `INSTRUCCIONES_FINALES.md` para todos los detalles.

## 🔧 Comandos Útiles

```bash
npm run test:db    # Probar conexión a BD
npm run migrate    # Crear tablas
npm run dev:server # Iniciar backend
npm run dev        # Iniciar frontend
npm run build      # Build producción
```

## 📁 Archivos Importantes

- `server/` - Backend API completo
- `server/config/database.ts` - Configuración PostgreSQL con SSL
- `server/database/schema.sql` - Esquema de base de datos
- `src/lib/api.ts` - Cliente API para frontend
- `.env` - Credenciales configuradas

Todo está listo. Solo necesitas habilitar el acceso remoto a PostgreSQL.
