# Próximos Pasos: Configurar PostgreSQL Remoto

## Estado Actual

✅ Código de la aplicación configurado correctamente
✅ Credenciales de conexión en `.env` están bien
✅ Script de diagnóstico mejorado y funcionando
❌ **Servidor PostgreSQL no acepta conexiones remotas**

## Diagnóstico

El script de prueba confirma que:
- No se puede alcanzar el servidor en `178.128.177.81:5432`
- El puerto está bloqueado o el servidor no está escuchando en todas las interfaces
- Necesitas configurar el servidor PostgreSQL remoto

## Acción Requerida: Configurar el Servidor

Debes conectarte por SSH a tu servidor y seguir estos pasos:

### 1. Conectarse al Servidor

```bash
ssh tu_usuario@178.128.177.81
```

### 2. Verificar Estado de PostgreSQL

```bash
# Ver si está corriendo
sudo systemctl status postgresql

# Si no está corriendo, iniciarlo
sudo systemctl start postgresql

# Ver versión instalada
ls /etc/postgresql/
```

Anota la versión (ejemplo: 14, 15, 16) para los siguientes pasos.

### 3. Configurar postgresql.conf

Reemplaza `15` con tu versión de PostgreSQL:

```bash
sudo nano /etc/postgresql/15/main/postgresql.conf
```

Busca y modifica estas líneas:

```conf
listen_addresses = '*'          # Cambiar de 'localhost' a '*'
port = 5432                     # Verificar que sea 5432
ssl = on                        # Debe estar en 'on'
```

Guarda con `Ctrl + O`, Enter, `Ctrl + X`

### 4. Configurar pg_hba.conf

```bash
sudo nano /etc/postgresql/15/main/pg_hba.conf
```

Al FINAL del archivo, agrega:

```conf
# Permitir conexiones SSL desde cualquier IP
hostssl all all 0.0.0.0/0 md5
```

Guarda con `Ctrl + O`, Enter, `Ctrl + X`

### 5. Verificar Base de Datos y Usuario

```bash
sudo -u postgres psql

# Dentro de psql:
\l                                              # Ver bases de datos
CREATE DATABASE VidrieriaTaller;                # Si no existe
ALTER USER postgres WITH PASSWORD 'IcKKdbbck2468';
\q                                              # Salir
```

### 6. Configurar Firewall del Servidor

```bash
# Ver estado del firewall
sudo ufw status

# Permitir PostgreSQL
sudo ufw allow 5432/tcp

# Si ufw no está activo
sudo ufw enable

# Verificar reglas
sudo ufw status numbered
```

### 7. Verificar Cloud Provider Firewall

**IMPORTANTE**: Si tu servidor está en DigitalOcean, AWS, Azure, u otro proveedor:

1. Entra al panel de control del proveedor
2. Busca la sección de "Firewalls" o "Security Groups"
3. Agrega una regla de entrada (inbound):
   - Protocolo: TCP
   - Puerto: 5432
   - Origen: Tu IP o `0.0.0.0/0` (para permitir desde cualquier IP)

### 8. Reiniciar PostgreSQL

```bash
sudo systemctl restart postgresql

# Verificar que inició bien
sudo systemctl status postgresql

# Verificar que escucha en todas las interfaces
sudo ss -tuln | grep 5432
```

Debes ver: `0.0.0.0:5432` (no `127.0.0.1:5432`)

### 9. Ver Logs Si Hay Problemas

```bash
sudo tail -50 /var/log/postgresql/postgresql-15-main.log
```

## Probar la Conexión Desde Tu Computadora

Una vez que hayas completado los pasos anteriores, vuelve a tu proyecto local y ejecuta:

```bash
npm run test:db
```

Si todo está configurado correctamente, deberías ver:

```
✅ Port is open and reachable
✅ PostgreSQL connection successful!
📊 PostgreSQL version: PostgreSQL 15.x on...
💾 Database size: 8416 kB
📋 Tables in database: 0
✨ All checks passed! Your PostgreSQL server is ready.

⚠️  No tables found. Run migration to create schema:
   npm run migrate
```

## Ejecutar la Migración

Cuando la conexión funcione:

```bash
npm run migrate
```

Esto creará todas las tablas necesarias para la aplicación.

## Iniciar la Aplicación

Finalmente, inicia el backend y frontend:

```bash
# Terminal 1 - Backend
npm run dev:server

# Terminal 2 - Frontend
npm run dev
```

Accede a http://localhost:5173 y usa estas credenciales:
- Admin: `admin@vidrieriataller.com` / `admin123`
- Operador: `operador@vidrieriataller.com` / `operator123`

## Solución de Problemas Comunes

### Error: ECONNREFUSED después de configuración
- Reinicia PostgreSQL: `sudo systemctl restart postgresql`
- Revisa logs: `sudo tail -50 /var/log/postgresql/postgresql-*-main.log`

### Error: Authentication failed
- Verifica la contraseña: `ALTER USER postgres WITH PASSWORD 'IcKKdbbck2468';`

### Error: Database does not exist
- Créala: `CREATE DATABASE VidrieriaTaller;`

### Puerto sigue bloqueado
- Revisa el firewall del proveedor cloud (DigitalOcean/AWS/Azure)
- Este suele ser el problema más común

## Comandos de Referencia Rápida

```bash
# Estado de PostgreSQL
sudo systemctl status postgresql

# Reiniciar PostgreSQL
sudo systemctl restart postgresql

# Ver configuración actual
sudo -u postgres psql -c "SHOW listen_addresses;"
sudo -u postgres psql -c "SHOW ssl;"
sudo -u postgres psql -c "SHOW port;"

# Ver logs en tiempo real
sudo tail -f /var/log/postgresql/postgresql-*-main.log

# Ver conexiones activas
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"
```

## Recursos

- Ver guía completa: `CONFIGURAR_POSTGRESQL.md`
- Documentación técnica: `DOCUMENTACION_TECNICA.md`
- Manual de usuario: `MANUAL_DE_USUARIO.md`

---

**Nota de Seguridad**: Considera restringir el acceso por IP en lugar de usar `0.0.0.0/0` en producción. También puedes crear un usuario dedicado en lugar de usar el usuario `postgres`.
