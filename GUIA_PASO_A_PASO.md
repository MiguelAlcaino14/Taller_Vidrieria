# Guía Interactiva Paso a Paso - Despliegue a Producción

Esta guía te llevará de la mano en todo el proceso. Marca cada casilla cuando completes el paso.

---

## FASE 1: PREPARACIÓN (5 minutos)

### Paso 1.1: Verificar que todo funciona localmente
```bash
npm run build
```

- [ ] El comando ejecutó sin errores
- [ ] Se creó la carpeta `dist/`

**¿Hay errores?** Si sí, detente aquí y avísame qué error aparece.

### Paso 1.2: Tener listos los servicios
- [ ] Tengo cuenta en Supabase (https://app.supabase.com)
- [ ] Tengo cuenta en Netlify (https://app.netlify.com)
- [ ] Mi código está en Git (GitHub, GitLab o Bitbucket)

**¿No tienes alguno?** Créalo ahora antes de continuar.

---

## FASE 2: CONFIGURAR SUPABASE (20 minutos)

### Paso 2.1: Crear el proyecto
1. Ve a https://app.supabase.com
2. Clic en **"New Project"**
3. Rellena:
   - **Organization:** Selecciona o crea una
   - **Name:** `taller-vidrieria-prod`
   - **Database Password:** Genera una y **GUÁRDALA** (la necesitarás)
   - **Region:** Selecciona **South America (São Paulo)** o la más cercana
   - **Pricing Plan:** Free está bien para empezar

4. Clic en **"Create new project"**
5. Espera 2-3 minutos mientras se crea

- [ ] El proyecto se creó exitosamente
- [ ] Guardé la contraseña en un lugar seguro

### Paso 2.2: Obtener las credenciales
1. Una vez creado el proyecto, ve a **Settings** (ícono de engranaje)
2. En el menú lateral, clic en **API**
3. Verás dos secciones importantes:

**Project URL:**
```
https://XXXXX.supabase.co
```

**Project API keys:**
- `anon` `public` - Esta es la que necesitas

Copia estos valores y pégalos aquí (los usaremos después):

```
Mi URL de Supabase: ___________________________________
Mi ANON KEY:       ___________________________________
```

- [ ] Copié mi URL
- [ ] Copié mi ANON KEY

### Paso 2.3: Aplicar las migraciones (la parte más importante)

Ahora vamos a crear toda la estructura de la base de datos.

1. En Supabase, ve a **SQL Editor** (ícono `</>` en el menú lateral)
2. Clic en **"New query"**

Vamos a ejecutar las migraciones **UNA POR UNA** en este orden:

#### Migración 1 de 21
1. Abre el archivo: `supabase/migrations/20251210150629_create_glass_cutting_projects.sql`
2. Copia TODO el contenido
3. Pégalo en el editor SQL de Supabase
4. Clic en **"Run"** (o Ctrl+Enter)
5. Deberías ver: **"Success. No rows returned"**

- [ ] Migración 1 ejecutada sin errores

#### Migración 2 de 21
1. Abre: `supabase/migrations/20251210151619_add_thickness_and_cutting_method.sql`
2. Copia, pega y ejecuta (Run)

- [ ] Migración 2 ejecutada sin errores

#### Migración 3 de 21
1. Abre: `supabase/migrations/20251211125355_add_user_roles_and_auth.sql`
2. Copia, pega y ejecuta

- [ ] Migración 3 ejecutada sin errores

#### Migración 4 de 21
1. Abre: `supabase/migrations/20251211125726_seed_demo_data.sql`
2. Copia, pega y ejecuta

- [ ] Migración 4 ejecutada sin errores

#### Migración 5 de 21
1. Abre: `supabase/migrations/20251211131456_create_customers_table.sql`
2. Copia, pega y ejecuta

- [ ] Migración 5 ejecutada sin errores

#### Migración 6 de 21
1. Abre: `supabase/migrations/20251211131529_transform_projects_to_orders.sql`
2. Copia, pega y ejecuta

- [ ] Migración 6 ejecutada sin errores

#### Migración 7 de 21
1. Abre: `supabase/migrations/20251211131624_create_order_items_and_materials_catalog.sql`
2. Copia, pega y ejecuta

- [ ] Migración 7 ejecutada sin errores

#### Migración 8 de 21
1. Abre: `supabase/migrations/20251211134723_fix_user_profiles_rls_recursion.sql`
2. Copia, pega y ejecuta

- [ ] Migración 8 ejecutada sin errores

#### Migración 9 de 21
1. Abre: `supabase/migrations/20251211134738_fix_customers_rls_recursion.sql`
2. Copia, pega y ejecuta

- [ ] Migración 9 ejecutada sin errores

#### Migración 10 de 21
1. Abre: `supabase/migrations/20251211160318_create_material_inventory_system.sql`
2. Copia, pega y ejecuta

- [ ] Migración 10 ejecutada sin errores

#### Migración 11 de 21
1. Abre: `supabase/migrations/20251211160346_update_orders_for_material_tracking.sql`
2. Copia, pega y ejecuta

- [ ] Migración 11 ejecutada sin errores

#### Migración 12 de 21
1. Abre: `supabase/migrations/20251215181017_fix_user_profiles_rls_final.sql`
2. Copia, pega y ejecuta

- [ ] Migración 12 ejecutada sin errores

#### Migración 13 de 21
1. Abre: `supabase/migrations/20251215181222_eliminate_user_profiles_recursion.sql`
2. Copia, pega y ejecuta

- [ ] Migración 13 ejecutada sin errores

#### Migración 14 de 21
1. Abre: `supabase/migrations/20251215181334_force_rls_bypass_complete.sql`
2. Copia, pega y ejecuta

- [ ] Migración 14 ejecutada sin errores

#### Migración 15 de 21
1. Abre: `supabase/migrations/20251216131341_add_svg_import_support.sql`
2. Copia, pega y ejecuta

- [ ] Migración 15 ejecutada sin errores

#### Migración 16 de 21
1. Abre: `supabase/migrations/20251216131533_create_order_documents_storage_bucket.sql`
2. Copia, pega y ejecuta

- [ ] Migración 16 ejecutada sin errores

#### Migración 17 de 21
1. Abre: `supabase/migrations/20251216140849_fix_security_and_performance_issues.sql`
2. Copia, pega y ejecuta

- [ ] Migración 17 ejecutada sin errores

#### Migración 18 de 21
1. Abre: `supabase/migrations/20251216141108_add_foreign_key_indexes.sql`
2. Copia, pega y ejecuta

- [ ] Migración 18 ejecutada sin errores

#### Migración 19 de 21
1. Abre: `supabase/migrations/20251216141209_consolidate_permissive_policies_fixed.sql`
2. Copia, pega y ejecuta

- [ ] Migración 19 ejecutada sin errores

#### Migración 20 de 21
1. Abre: `supabase/migrations/20251216142409_optimize_rls_policies_performance.sql`
2. Copia, pega y ejecuta

- [ ] Migración 20 ejecutada sin errores

#### Migración 21 de 21 (¡Última!)
1. Abre: `supabase/migrations/20251216142934_remove_unused_audit_indexes.sql`
2. Copia, pega y ejecuta

- [ ] Migración 21 ejecutada sin errores
- [ ] ¡TODAS las migraciones están aplicadas!

**¿Hubo algún error?** Avísame qué migración falló y qué error mostró.

### Paso 2.4: Verificar que las tablas se crearon
1. Ve a **Table Editor** en Supabase (ícono de tabla)
2. Deberías ver estas tablas:
   - `customers`
   - `orders`
   - `order_items`
   - `materials_catalog`
   - `material_inventory`
   - `user_profiles`

- [ ] Veo todas las tablas listadas arriba

### Paso 2.5: Configurar autenticación
1. Ve a **Authentication** (ícono de candado)
2. Clic en **URL Configuration**
3. Por ahora deja los valores por defecto
   (Los actualizaremos después de desplegar en Netlify)

- [ ] Vi la página de URL Configuration

---

## FASE 3: CONFIGURAR NETLIFY (15 minutos)

### Paso 3.1: Conectar tu repositorio
1. Ve a https://app.netlify.com
2. Clic en **"Add new site"**
3. Selecciona **"Import an existing project"**
4. Selecciona tu proveedor Git:
   - GitHub
   - GitLab
   - Bitbucket

5. **Autoriza** a Netlify si es la primera vez
6. Busca y selecciona tu repositorio del proyecto

- [ ] Mi repositorio está conectado

### Paso 3.2: Configurar el build
Netlify debería detectar automáticamente:
- **Build command:** `npm run build`
- **Publish directory:** `dist`
- **Base directory:** (dejar vacío)

- [ ] La configuración se detectó correctamente

### Paso 3.3: Agregar variables de entorno (¡IMPORTANTE!)

**ANTES** de hacer el deploy, necesitas agregar las variables:

1. En la página de configuración, busca **"Environment variables"**
2. Clic en **"Add environment variables"** o **"Add a variable"**

**Variable 1:**
- Key: `VITE_SUPABASE_URL`
- Value: (pega tu URL de Supabase que copiaste antes)
- Clic en **"Add variable"**

**Variable 2:**
- Key: `VITE_SUPABASE_ANON_KEY`
- Value: (pega tu ANON KEY que copiaste antes)
- Clic en **"Add variable"**

- [ ] Agregué `VITE_SUPABASE_URL`
- [ ] Agregué `VITE_SUPABASE_ANON_KEY`

### Paso 3.4: Desplegar
1. Clic en **"Deploy site"** o **"Deploy [nombre-del-proyecto]"**
2. Espera 2-4 minutos (verás los logs del build en tiempo real)
3. Deberías ver: **"Site is live"** con una URL como:
   ```
   https://random-name-123456.netlify.app
   ```

- [ ] El sitio se desplegó exitosamente
- [ ] Obtuve mi URL de Netlify

**Copia tu URL de Netlify aquí:**
```
Mi URL de Netlify: ___________________________________
```

**¿El build falló?** Avísame qué error apareció en los logs.

### Paso 3.5: Probar el sitio
1. Abre la URL de Netlify en tu navegador
2. Deberías ver la pantalla de login del Taller Vidrieria

- [ ] El sitio carga correctamente

---

## FASE 4: CONECTAR SUPABASE CON NETLIFY (5 minutos)

### Paso 4.1: Actualizar URLs en Supabase
Ahora que tienes tu URL de Netlify, necesitas decirle a Supabase que confíe en ella:

1. Vuelve a Supabase
2. Ve a **Authentication** → **URL Configuration**
3. En **Site URL**, pega tu URL de Netlify (ej: `https://tu-sitio.netlify.app`)
4. En **Redirect URLs**, clic en **"Add URL"** y pega:
   ```
   https://tu-sitio.netlify.app/**
   ```
   (nota el `/**` al final, es importante)

5. Clic en **"Save"**

- [ ] Actualicé Site URL
- [ ] Agregué Redirect URL
- [ ] Guardé los cambios

---

## FASE 5: PRUEBAS FINALES (10 minutos)

### Paso 5.1: Registrar tu primer usuario
1. Abre tu sitio en Netlify
2. Clic en **"Registrarse"** o **"Sign Up"**
3. Ingresa:
   - Email: (tu email real)
   - Password: (una contraseña segura)
   - Confirmar password
4. Clic en **"Registrarse"**

- [ ] Me registré exitosamente
- [ ] Puedo ver la interfaz de la aplicación

**¿No funciona el registro?** Revisa que hayas configurado bien las URLs en Supabase.

### Paso 5.2: Convertirte en Administrador
Por defecto, los nuevos usuarios son "operadores". Necesitas hacerte admin:

1. Ve a Supabase
2. Ve a **Table Editor**
3. Selecciona la tabla **`user_profiles`**
4. Busca la fila con tu email
5. Haz doble clic en la columna **`role`**
6. Cámbialo de `operator` a `admin`
7. Presiona Enter o clic en el check verde
8. Vuelve a tu sitio y recarga la página (F5)

- [ ] Cambié mi rol a admin
- [ ] Recargar la página
- [ ] Ahora veo opciones de administrador

### Paso 5.3: Crear un cliente de prueba
1. Clic en **"Clientes"** o **"Customers"**
2. Clic en **"Nuevo Cliente"** o **"Add Customer"**
3. Rellena:
   - Nombre: "Cliente Prueba"
   - Email: "prueba@test.com"
   - Teléfono: "123456789"
4. Clic en **"Guardar"** o **"Save"**

- [ ] El cliente se creó exitosamente

### Paso 5.4: Crear una orden de prueba
1. Ve a **"Órdenes"** o **"Orders"**
2. Clic en **"Nueva Orden"** o **"New Order"**
3. Rellena los datos básicos de una orden
4. Guarda la orden

- [ ] La orden se creó exitosamente

### Paso 5.5: Prueba final de persistencia
1. Cierra sesión (logout)
2. Vuelve a iniciar sesión
3. Verifica que:
   - [ ] El cliente sigue ahí
   - [ ] La orden sigue ahí
   - [ ] Todo se guardó correctamente

---

## ¡FELICITACIONES! 🎉

Si llegaste hasta aquí y todas las casillas están marcadas, tu aplicación está 100% funcional en producción.

### Información importante para guardar:

**Supabase:**
- URL: ___________________________________
- Dashboard: https://app.supabase.com

**Netlify:**
- URL del sitio: ___________________________________
- Dashboard: https://app.netlify.com

**Credenciales de Admin:**
- Email: ___________________________________
- Password: (la que creaste)

---

## BONUS: Dominio Personalizado (Opcional)

Si quieres usar tu propio dominio (ej: `vidrieria.com`):

### Paso 6.1: Configurar en Netlify
1. En Netlify, ve a **Domain settings**
2. Clic en **"Add custom domain"**
3. Ingresa tu dominio
4. Sigue las instrucciones para configurar DNS

### Paso 6.2: Actualizar en Supabase
1. Ve a Supabase → Authentication → URL Configuration
2. Actualiza **Site URL** con tu nuevo dominio
3. Actualiza **Redirect URLs** con tu nuevo dominio

---

## ¿Problemas? Checklist de solución

### El sitio no carga
- [ ] Verificar que el build en Netlify terminó sin errores
- [ ] Revisar los logs de deploy en Netlify

### No puedo registrarme/login
- [ ] Verificar que las URLs están configuradas en Supabase Auth
- [ ] Verificar que las variables de entorno están en Netlify
- [ ] Revisar la consola del navegador (F12) para ver errores

### No veo datos/tablas vacías
- [ ] Verificar que TODAS las migraciones se aplicaron
- [ ] Verificar que tu usuario tiene rol 'admin' o 'operator'
- [ ] Revisar en Supabase → Logs si hay errores de permisos

### Build falla en Netlify
- [ ] Verificar que `npm run build` funciona localmente
- [ ] Revisar los logs de error en Netlify
- [ ] Verificar que todas las dependencias están en package.json

---

## Próximos pasos recomendados

1. **Crear más usuarios**: Invita a tu equipo
2. **Cargar datos reales**: Empieza con clientes y materiales
3. **Configurar respaldos**: Supabase hace respaldos automáticos, pero verifica la configuración
4. **Monitoreo**: Revisa el uso en Supabase y Netlify semanalmente
5. **Documentar procesos**: Escribe tus propios procedimientos de uso

---

## Contacto

Si en algún paso te atascas o algo no funciona:
1. Anota exactamente en qué paso estás
2. Copia el error exacto que ves
3. Hazme saber y te ayudo

**¡Éxito con tu proyecto!**
