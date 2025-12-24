# Guía: Configurar PostgreSQL para Conexiones Remotas con SSL

## Contexto

Tu aplicación está intentando conectarse a:
- Host: `178.128.177.81`
- Puerto: `5432`
- Database: `VidrieriaTaller`
- User: `postgres`
- SSL: Habilitado

Actualmente el servidor rechaza conexiones. Esta guía te ayudará a solucionarlo.

## Paso 1: Conectarse al Servidor

```bash
ssh usuario@178.128.177.81
```

## Paso 2: Verificar PostgreSQL

```bash
# Ver estado
sudo systemctl status postgresql

# Ver versión instalada
psql --version

# Ver qué versiones hay instaladas
ls /etc/postgresql/
```

Anota la versión (ejemplo: 14, 15, 16)

## Paso 3: Configurar postgresql.conf

```bash
# Reemplaza 15 con tu versión
sudo nano /etc/postgresql/15/main/postgresql.conf
```

### Busca y modifica estas líneas:

```conf
# Conexiones de red
listen_addresses = '*'          # Era: listen_addresses = 'localhost'

# Puerto (verificar que sea 5432)
port = 5432

# SSL (debe estar habilitado)
ssl = on
ssl_cert_file = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
ssl_key_file = '/etc/ssl/private/ssl-cert-snakeoil.key'
```

**Guardar**: `Ctrl + O`, Enter, `Ctrl + X`

## Paso 4: Configurar pg_hba.conf

```bash
# Reemplaza 15 con tu versión
sudo nano /etc/postgresql/15/main/pg_hba.conf
```

### Al FINAL del archivo, agrega:

```conf
# Permitir conexiones SSL desde cualquier IP
hostssl all all 0.0.0.0/0 md5
```

**Nota**: Para mayor seguridad, puedes reemplazar `0.0.0.0/0` con tu IP específica.

**Guardar**: `Ctrl + O`, Enter, `Ctrl + X`

## Paso 5: Verificar Usuario y Base de Datos

```bash
# Conectarse a PostgreSQL
sudo -u postgres psql

# Verificar que existe la base de datos
\l

# Si no existe VidrieriaTaller, créala:
CREATE DATABASE VidrieriaTaller;

# Verificar usuario postgres tiene contraseña
# Si no tiene, establecerla:
ALTER USER postgres WITH PASSWORD 'IcKKdbbck2468';

# Salir
\q
```

## Paso 6: Configurar Firewall

```bash
# Ver reglas actuales
sudo ufw status

# Permitir PostgreSQL
sudo ufw allow 5432/tcp

# Si ufw no está habilitado:
sudo ufw enable

# Ver reglas nuevamente
sudo ufw status numbered
```

## Paso 7: Reiniciar PostgreSQL

```bash
# Reiniciar servicio
sudo systemctl restart postgresql

# Verificar que inició correctamente
sudo systemctl status postgresql

# Ver si está escuchando en el puerto
sudo netstat -tuln | grep 5432
# O si netstat no está instalado:
sudo ss -tuln | grep 5432
```

Deberías ver algo como:
```
tcp  0  0  0.0.0.0:5432  0.0.0.0:*  LISTEN
```

## Paso 8: Verificar Logs (Si hay problemas)

```bash
# Ver logs recientes
sudo tail -n 50 /var/log/postgresql/postgresql-15-main.log

# Ver logs en tiempo real
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

## Paso 9: Probar Conexión Desde Tu Máquina Local

Vuelve a tu proyecto y ejecuta:

```bash
npm run test:db
```

Deberías ver:
```
✅ Connection successful!
PostgreSQL version: PostgreSQL 15.x on ...
```

## Paso 10: Ejecutar Migración

Una vez que la conexión funcione:

```bash
npm run migrate
```

Esto creará todas las tablas necesarias.

## Troubleshooting

### Error: ECONNREFUSED
- PostgreSQL no está corriendo: `sudo systemctl start postgresql`
- Firewall bloqueando: Revisa paso 6
- `listen_addresses` no configurado: Revisa paso 3

### Error: Connection timed out
- Firewall del proveedor (DigitalOcean, AWS, etc.) puede estar bloqueando
- Revisa configuración de red del servidor en el panel de control

### Error: SSL connection required
- Verifica `ssl = on` en `postgresql.conf`
- Verifica línea `hostssl` en `pg_hba.conf`

### Error: Authentication failed
- Contraseña incorrecta
- Usuario no tiene permisos: `ALTER USER postgres WITH PASSWORD 'nueva_contraseña';`

### Error: Database does not exist
- Crear base de datos: `CREATE DATABASE VidrieriaTaller;`

## Verificación Final

Cuando todo funcione, deberías poder:

1. ✅ Conectarte desde tu app: `npm run test:db`
2. ✅ Ejecutar migración: `npm run migrate`
3. ✅ Iniciar backend: `npm run dev:server`
4. ✅ Iniciar frontend: `npm run dev`
5. ✅ Hacer login en http://localhost:5173

## Seguridad Adicional (Opcional)

### Restringir por IP

En lugar de permitir cualquier IP (`0.0.0.0/0`), especifica tu IP:

```conf
# pg_hba.conf
hostssl all all TU_IP/32 md5
```

### Crear Usuario Dedicado

En lugar de usar `postgres`, crea un usuario específico:

```sql
CREATE USER vidrieria_app WITH PASSWORD 'password_seguro';
GRANT ALL PRIVILEGES ON DATABASE VidrieriaTaller TO vidrieria_app;
```

Luego actualiza `.env`:
```
DB_USER=vidrieria_app
DB_PASSWORD=password_seguro
```

## Comandos de Referencia Rápida

```bash
# Ver estado
sudo systemctl status postgresql

# Reiniciar
sudo systemctl restart postgresql

# Ver conexiones activas
sudo -u postgres psql -c "SELECT * FROM pg_stat_activity;"

# Ver configuración actual
sudo -u postgres psql -c "SHOW listen_addresses;"
sudo -u postgres psql -c "SHOW ssl;"
sudo -u postgres psql -c "SHOW port;"

# Ver logs
sudo tail -f /var/log/postgresql/postgresql-*-main.log
```

¡Listo! Una vez completados estos pasos, tu aplicación podrá conectarse a PostgreSQL con SSL.
