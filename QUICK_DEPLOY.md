# Despliegue Rápido - Checklist

Use esta guía como checklist rápido. Para detalles completos, ver [PRODUCTION_SETUP.md](./PRODUCTION_SETUP.md).

## Pre-requisitos
- [ ] Cuenta de Supabase creada
- [ ] Cuenta de Netlify creada
- [ ] Repositorio Git configurado (GitHub/GitLab/Bitbucket)

## Parte 1: Supabase (15 min)

### Crear Proyecto
- [ ] Ir a https://app.supabase.com
- [ ] New Project → Nombre: `taller-vidrieria-prod`
- [ ] Seleccionar región más cercana
- [ ] Guardar contraseña de BD

### Aplicar Migraciones
- [ ] SQL Editor → Ejecutar todas las migraciones en orden
- [ ] Verificar que no hay errores

### Configurar Auth
- [ ] Authentication → URL Configuration
- [ ] Site URL: `https://tu-app.netlify.app` (actualizar después)
- [ ] Agregar a Redirect URLs

### Obtener Credenciales
- [ ] Settings → API
- [ ] Copiar Project URL
- [ ] Copiar anon public key

## Parte 2: Netlify (10 min)

### Conectar Repo
- [ ] https://app.netlify.com
- [ ] Add new site → Import project
- [ ] Conectar tu proveedor Git
- [ ] Seleccionar repositorio

### Variables de Entorno
- [ ] Site settings → Environment variables
- [ ] Agregar `VITE_SUPABASE_URL` = [URL de Supabase]
- [ ] Agregar `VITE_SUPABASE_ANON_KEY` = [Anon key]

### Desplegar
- [ ] Deploy site
- [ ] Esperar build (2-3 min)
- [ ] Copiar URL generada

### Actualizar Supabase
- [ ] Volver a Supabase
- [ ] Authentication → URL Configuration
- [ ] Actualizar Site URL con URL de Netlify
- [ ] Actualizar Redirect URLs

## Parte 3: Verificación (5 min)

### Tests Básicos
- [ ] Abrir sitio
- [ ] Registrar usuario
- [ ] Login funciona
- [ ] Crear cliente
- [ ] Crear orden
- [ ] Logout funciona

### Crear Admin
- [ ] Supabase → Table Editor → user_profiles
- [ ] Buscar tu usuario
- [ ] Cambiar role a 'admin'
- [ ] Recargar app

## Parte 4: Post-Despliegue (Opcional)

### Dominio Personalizado
- [ ] Netlify → Domain settings
- [ ] Add custom domain
- [ ] Configurar DNS
- [ ] Actualizar URL en Supabase Auth

### Monitoreo
- [ ] Configurar alertas en Supabase
- [ ] Revisar usage en ambas plataformas

### Respaldos
- [ ] Verificar configuración de backups en Supabase

## Comandos Útiles

```bash
# Verificar build local antes de desplegar
npm run build

# Ver preview del build
npm run preview

# Verificar tipos
npm run typecheck

# Linter
npm run lint
```

## URLs Importantes

- **Supabase Dashboard:** https://app.supabase.com
- **Netlify Dashboard:** https://app.netlify.com
- **Documentación Completa:** [DEPLOYMENT.md](./DEPLOYMENT.md)
- **Guía Detallada:** [PRODUCTION_SETUP.md](./PRODUCTION_SETUP.md)

## Problemas Comunes

### Build falla
```bash
# Probar localmente
npm run build
# Si funciona local, revisar variables en Netlify
```

### Login no funciona
```bash
# Verificar URL en Supabase Auth Configuration
# Debe coincidir con tu URL de Netlify
```

### No veo datos
```bash
# Verificar rol en user_profiles
# Debe ser 'admin' u 'operator'
```

## Tiempo Estimado Total: 30 minutos

1. Supabase setup: 15 min
2. Netlify setup: 10 min
3. Verificación: 5 min

## Próximos Pasos

Una vez desplegado:
1. Documenta las credenciales de admin
2. Configura usuarios adicionales
3. Personaliza el dominio (opcional)
4. Configura monitoreo
5. Planifica respaldos regulares

## Soporte

Ver [DEPLOYMENT.md](./DEPLOYMENT.md) para solución detallada de problemas.
