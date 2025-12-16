# Guía de Despliegue a Producción

Esta guía te llevará paso a paso para desplegar tu aplicación de Taller Vidrieria a producción usando Supabase y Netlify.

## Requisitos Previos

- Cuenta de Supabase (https://supabase.com)
- Cuenta de Netlify (https://netlify.com)
- Repositorio Git (GitHub, GitLab o Bitbucket)
- Node.js 18+ instalado localmente

## Parte 1: Configuración de Supabase

### 1.1 Crear Proyecto de Producción

1. Accede a https://app.supabase.com
2. Haz clic en "New Project"
3. Configura tu proyecto:
   - Nombre: `taller-vidrieria-prod`
   - Contraseña de base de datos: Genera una segura y guárdala
   - Región: Elige la más cercana a tus usuarios
   - Plan: Selecciona según tus necesidades (Free tier es suficiente para empezar)

### 1.2 Aplicar Migraciones

Una vez creado el proyecto, necesitas aplicar todas las migraciones:

1. Ve a SQL Editor en el dashboard de Supabase
2. Ejecuta las migraciones en orden cronológico desde la carpeta `supabase/migrations/`
3. Comienza con `20251210150629_create_glass_cutting_projects.sql`
4. Continúa en orden secuencial hasta la última migración

**Orden de migraciones:**
```
1. 20251210150629_create_glass_cutting_projects.sql
2. 20251210151619_add_thickness_and_cutting_method.sql
3. 20251211125355_add_user_roles_and_auth.sql
4. 20251211125726_seed_demo_data.sql
5. 20251211131456_create_customers_table.sql
6. 20251211131529_transform_projects_to_orders.sql
7. 20251211131624_create_order_items_and_materials_catalog.sql
8. 20251211134723_fix_user_profiles_rls_recursion.sql
9. 20251211134738_fix_customers_rls_recursion.sql
10. 20251211160318_create_material_inventory_system.sql
11. 20251211160346_update_orders_for_material_tracking.sql
12. 20251215181017_fix_user_profiles_rls_final.sql
13. 20251215181222_eliminate_user_profiles_recursion.sql
14. 20251215181334_force_rls_bypass_complete.sql
15. 20251216131341_add_svg_import_support.sql
16. 20251216131533_create_order_documents_storage_bucket.sql
17. 20251216140849_fix_security_and_performance_issues.sql
18. 20251216141108_add_foreign_key_indexes.sql
19. 20251216141209_consolidate_permissive_policies_fixed.sql
20. 20251216142409_optimize_rls_policies_performance.sql
21. 20251216142934_remove_unused_audit_indexes.sql
```

### 1.3 Configurar Autenticación

1. Ve a `Authentication` → `Providers`
2. Configura Email Provider:
   - Habilita "Enable Email provider"
   - Deshabilita "Confirm email" (o habilita según tu necesidad)
3. Ve a `Authentication` → `URL Configuration`:
   - Site URL: Tu URL de producción (ej: `https://taller-vidrieria.netlify.app`)
   - Redirect URLs: Agrega tu URL de producción

### 1.4 Configurar Storage

1. Ve a `Storage` → `Policies`
2. Verifica que el bucket `order-documents` tiene las políticas correctas
3. Las políticas deberían permitir:
   - Usuarios autenticados pueden subir archivos
   - Usuarios autenticados pueden leer sus propios archivos

### 1.5 Obtener Credenciales

1. Ve a `Settings` → `API`
2. Copia estos valores (los necesitarás para Netlify):
   - Project URL (VITE_SUPABASE_URL)
   - anon public key (VITE_SUPABASE_ANON_KEY)

## Parte 2: Configuración de Netlify

### 2.1 Conectar Repositorio

1. Accede a https://app.netlify.com
2. Haz clic en "Add new site" → "Import an existing project"
3. Conecta tu proveedor Git (GitHub, GitLab, Bitbucket)
4. Selecciona tu repositorio

### 2.2 Configurar Build

Netlify detectará automáticamente la configuración desde `netlify.toml`. Verifica:

- Build command: `npm run build`
- Publish directory: `dist`

### 2.3 Configurar Variables de Entorno

En la configuración del sitio, ve a "Environment variables":

1. Agrega `VITE_SUPABASE_URL`:
   - Key: `VITE_SUPABASE_URL`
   - Value: Tu URL de Supabase de producción

2. Agrega `VITE_SUPABASE_ANON_KEY`:
   - Key: `VITE_SUPABASE_ANON_KEY`
   - Value: Tu anon key de Supabase de producción

### 2.4 Desplegar

1. Haz clic en "Deploy site"
2. Netlify construirá y desplegará tu aplicación
3. Una vez completado, obtendrás una URL como `https://random-name.netlify.app`

### 2.5 Configurar Dominio Personalizado (Opcional)

1. Ve a "Domain settings"
2. Haz clic en "Add custom domain"
3. Sigue las instrucciones para configurar tu DNS
4. Netlify configurará automáticamente el certificado SSL

**IMPORTANTE:** Si configuras un dominio personalizado, actualiza la URL en:
- Supabase → Authentication → URL Configuration
- Supabase → Authentication → Redirect URLs

## Parte 3: Verificación Post-Despliegue

### 3.1 Pruebas de Funcionalidad

Prueba las siguientes funcionalidades en producción:

- [ ] Registro de nuevo usuario
- [ ] Inicio de sesión
- [ ] Recuperación de contraseña
- [ ] Crear cliente
- [ ] Crear orden
- [ ] Gestionar inventario de materiales
- [ ] Importar archivo SVG
- [ ] Asignar materiales a orden
- [ ] Ejecutar corte

### 3.2 Verificar Seguridad

- [ ] Las políticas RLS están activas en todas las tablas
- [ ] Los usuarios solo pueden ver sus propios datos
- [ ] Las claves secretas no están expuestas en el código del frontend
- [ ] HTTPS está activo (certificado SSL válido)

### 3.3 Crear Usuario Administrador

Para crear tu primer usuario administrador:

1. Regístrate normalmente en la aplicación
2. Ve a Supabase → Table Editor → `user_profiles`
3. Encuentra tu usuario y cambia el campo `role` de `'operator'` a `'admin'`
4. Recarga la aplicación

## Parte 4: Mantenimiento

### 4.1 Aplicar Nuevas Migraciones

Cuando tengas nuevas migraciones:

1. Ve a Supabase → SQL Editor
2. Copia y pega el contenido de la nueva migración
3. Ejecuta la migración

### 4.2 Monitoreo

Configura alertas en:

- **Supabase:**
  - Ve a Settings → Usage para monitorear:
    - Número de usuarios autenticados
    - Consultas a la base de datos
    - Almacenamiento usado

- **Netlify:**
  - Ve a Analytics para monitorear:
    - Tráfico del sitio
    - Tiempo de carga
    - Errores de build

### 4.3 Respaldos

Supabase hace respaldos automáticos según tu plan:
- Free tier: 7 días de respaldos
- Pro tier: 30 días de respaldos

Para respaldos manuales adicionales:
1. Ve a Database → Backups
2. Haz clic en "Create backup"

### 4.4 Actualizaciones

Para desplegar actualizaciones:

1. Haz cambios en tu código local
2. Haz commit y push a tu repositorio
3. Netlify automáticamente detectará los cambios y redesplegar

## Solución de Problemas Comunes

### Error: "Missing Supabase environment variables"

**Causa:** Las variables de entorno no están configuradas en Netlify.

**Solución:**
1. Ve a Site settings → Environment variables en Netlify
2. Verifica que `VITE_SUPABASE_URL` y `VITE_SUPABASE_ANON_KEY` estén configuradas
3. Redesplega el sitio

### Error: "Failed to fetch" al hacer login

**Causa:** La URL del sitio no está configurada en Supabase Auth.

**Solución:**
1. Ve a Authentication → URL Configuration en Supabase
2. Agrega tu URL de Netlify en "Redirect URLs"
3. Actualiza el "Site URL"

### Build falla en Netlify

**Causa:** Dependencias faltantes o error de compilación.

**Solución:**
1. Revisa los logs de build en Netlify
2. Prueba el build localmente con `npm run build`
3. Asegúrate de que todas las dependencias estén en `package.json`

### RLS impide acceso a datos

**Causa:** Las políticas de Row Level Security están muy restrictivas.

**Solución:**
1. Revisa las políticas en Supabase → Authentication → Policies
2. Verifica que los usuarios tengan el rol correcto en `user_profiles`
3. Revisa los logs de Postgres en Supabase para ver qué consultas fallan

## Mejores Prácticas

1. **Usa entornos separados:** Mantén proyectos de Supabase distintos para desarrollo y producción
2. **No commits de .env:** Nunca hagas commit del archivo `.env` con credenciales reales
3. **Prueba localmente primero:** Siempre prueba los cambios localmente antes de desplegar
4. **Versionado de migraciones:** Nunca modifiques migraciones ya aplicadas, crea nuevas
5. **Monitoreo regular:** Revisa regularmente el uso de recursos en Supabase y Netlify
6. **Respaldos regulares:** Configura respaldos automáticos y verifica que funcionen
7. **Documentación:** Mantén documentado cualquier cambio importante en la configuración

## Recursos Adicionales

- [Documentación de Supabase](https://supabase.com/docs)
- [Documentación de Netlify](https://docs.netlify.com)
- [Guía de Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Guía de Edge Functions](https://supabase.com/docs/guides/functions)

## Soporte

Si encuentras problemas:

1. Revisa los logs en Netlify (Deploy logs)
2. Revisa los logs en Supabase (Logs → Postgres Logs)
3. Consulta la documentación oficial
4. Busca en Stack Overflow o GitHub Issues
