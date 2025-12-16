# Guía Rápida de Configuración de Producción

Esta guía te ayudará a configurar rápidamente tu entorno de producción. Para instrucciones detalladas, consulta [DEPLOYMENT.md](./DEPLOYMENT.md).

## Paso 1: Preparar Supabase (15 minutos)

### 1. Crear Proyecto
```
1. Ir a https://app.supabase.com
2. Clic en "New Project"
3. Nombre: taller-vidrieria-prod
4. Región: South America (São Paulo) o la más cercana
5. Generar contraseña fuerte
```

### 2. Aplicar Migraciones
```
1. Ir a SQL Editor en Supabase
2. Copiar contenido de cada archivo en supabase/migrations/
3. Ejecutar en orden (20251210... → 20251216...)
4. Verificar que no haya errores
```

### 3. Obtener Credenciales
```
Settings → API → Copiar:
- Project URL
- anon public key
```

### 4. Configurar Auth
```
Authentication → URL Configuration:
- Site URL: https://tu-sitio.netlify.app
- Redirect URLs: Agregar tu URL de producción
```

## Paso 2: Desplegar en Netlify (10 minutos)

### 1. Conectar Repo
```
1. Ir a https://app.netlify.com
2. "Add new site" → "Import project"
3. Conectar GitHub/GitLab/Bitbucket
4. Seleccionar repositorio
```

### 2. Configurar Variables de Entorno
```
Site settings → Environment variables → Add:

VITE_SUPABASE_URL = [tu URL de Supabase]
VITE_SUPABASE_ANON_KEY = [tu anon key de Supabase]
```

### 3. Desplegar
```
1. Clic en "Deploy site"
2. Esperar 2-3 minutos
3. Obtener URL: https://random-name.netlify.app
```

### 4. Actualizar URL en Supabase
```
Volver a Supabase:
Authentication → URL Configuration
- Actualizar Site URL con tu URL de Netlify
```

## Paso 3: Verificar (5 minutos)

### Checklist de Verificación
```
[ ] Abrir sitio en navegador
[ ] Registrar nuevo usuario
[ ] Iniciar sesión
[ ] Crear un cliente de prueba
[ ] Crear una orden de prueba
[ ] Verificar que los datos se guardan
```

## Paso 4: Crear Usuario Admin

### Vía Supabase Dashboard
```
1. Registrarte en la app
2. Ir a Supabase → Table Editor → user_profiles
3. Buscar tu email
4. Cambiar role de 'operator' a 'admin'
5. Recargar la app
```

## Variables de Entorno Requeridas

### Desarrollo (.env local)
```bash
VITE_SUPABASE_URL=https://aggxhhlqgqjmyruenkyo.supabase.co
VITE_SUPABASE_ANON_KEY=tu-key-de-desarrollo
```

### Producción (Netlify Environment Variables)
```bash
VITE_SUPABASE_URL=https://tu-proyecto-prod.supabase.co
VITE_SUPABASE_ANON_KEY=tu-key-de-produccion
```

## Comandos Útiles

### Desarrollo Local
```bash
# Instalar dependencias
npm install

# Iniciar servidor de desarrollo
npm run dev

# Construir para producción (prueba local)
npm run build
npm run preview
```

### Verificar Build Antes de Desplegar
```bash
# Construir proyecto
npm run build

# Si hay errores, corregir antes de desplegar
# Si no hay errores, estás listo para producción
```

## Próximos Pasos Post-Despliegue

### Configuración Adicional
- [ ] Configurar dominio personalizado en Netlify
- [ ] Configurar alertas de uso en Supabase
- [ ] Configurar respaldos automáticos
- [ ] Documentar proceso de onboarding de usuarios

### Seguridad
- [ ] Verificar que RLS está activo en todas las tablas
- [ ] Revisar políticas de acceso
- [ ] Confirmar que HTTPS está activo
- [ ] Verificar que no hay claves secretas expuestas

### Monitoreo
- [ ] Configurar Google Analytics (opcional)
- [ ] Revisar métricas en Netlify Analytics
- [ ] Configurar alertas en Supabase

## Solución Rápida de Problemas

### Error: "Missing Supabase environment variables"
```
→ Verificar variables en Netlify
→ Redesplegar sitio
```

### No puedo hacer login
```
→ Verificar URL en Supabase Auth Configuration
→ Agregar URL de Netlify a Redirect URLs
```

### Build falla
```
→ Ejecutar "npm run build" localmente
→ Revisar errores en consola
→ Verificar que todas las dependencias están en package.json
```

### No veo mis datos
```
→ Verificar políticas RLS en Supabase
→ Verificar rol de usuario en tabla user_profiles
→ Revisar logs en Supabase → Logs → Postgres Logs
```

## Recursos

- [Guía Completa de Despliegue](./DEPLOYMENT.md)
- [Documentación de Supabase](https://supabase.com/docs)
- [Documentación de Netlify](https://docs.netlify.com)

## Costos Estimados

### Plan Gratuito (Desarrollo/Proyectos Pequeños)
- Supabase Free Tier: $0/mes
  - 500MB de base de datos
  - 1GB de almacenamiento
  - 50,000 usuarios autenticados
- Netlify Free Tier: $0/mes
  - 100GB de ancho de banda
  - 300 minutos de build

### Plan Profesional (Recomendado para Producción)
- Supabase Pro: $25/mes
  - 8GB de base de datos
  - 100GB de almacenamiento
  - 100,000 usuarios autenticados
  - Respaldos por 30 días
- Netlify Pro: $19/mes
  - 1TB de ancho de banda
  - Builds ilimitados

## Contacto y Soporte

Para problemas técnicos:
1. Revisar logs en Netlify y Supabase
2. Consultar documentación oficial
3. Buscar en comunidad de Supabase/Netlify
4. Stack Overflow con tags: supabase, netlify, react
