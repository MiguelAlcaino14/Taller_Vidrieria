# Usuarios de Prueba - Sistema de Optimización de Corte de Vidrios

Este documento contiene las credenciales de 3 usuarios de prueba con diferentes niveles de acceso.

## Credenciales de Acceso

### 1. Usuario Administrador
- **Email:** admin@vidrios.com
- **Contraseña:** Admin123!
- **Rol:** Administrador
- **Permisos:**
  - Ve TODOS los proyectos del sistema
  - Puede gestionar cualquier proyecto
  - Puede ver perfiles de todos los usuarios

### 2. Usuario Manager
- **Email:** manager@vidrios.com
- **Contraseña:** Manager123!
- **Rol:** Manager
- **Permisos:**
  - Ve sus propios proyectos
  - Ve proyectos de los usuarios asignados a su cargo
  - Gestiona a 2 usuarios básicos

### 3. Usuario Básico #1
- **Email:** usuario1@vidrios.com
- **Contraseña:** Usuario123!
- **Rol:** Usuario
- **Permisos:**
  - Solo ve sus propios proyectos
  - No puede ver proyectos de otros usuarios

### 4. Usuario Básico #2
- **Email:** usuario2@vidrios.com
- **Contraseña:** Usuario123!
- **Rol:** Usuario
- **Permisos:**
  - Solo ve sus propios proyectos
  - No puede ver proyectos de otros usuarios

### 5. Miguel Alcaino
- **Email:** malcaino@vidrios.com
- **Contraseña:** Miguel123!
- **Rol:** Usuario
- **Permisos:**
  - Solo ve sus propios proyectos
  - No puede ver proyectos de otros usuarios

## Instrucciones para Crear los Usuarios

Para probar el sistema, debes crear estos 4 usuarios manualmente:

1. Abre la aplicación y haz clic en "Iniciar Sesión"
2. Selecciona "¿No tienes cuenta? Regístrate"
3. Crea cada usuario con los datos correspondientes:
   - Para Admin: Nombre "Administrador Sistema", email "admin@vidrios.com", contraseña "Admin123!"
   - Para Manager: Nombre "Manager Regional", email "manager@vidrios.com", contraseña "Manager123!"
   - Para Usuario1: Nombre "Juan Pérez", email "usuario1@vidrios.com", contraseña "Usuario123!"
   - Para Usuario2: Nombre "María González", email "usuario2@vidrios.com", contraseña "Usuario123!"

4. Después de crear los usuarios, ejecuta la migración SQL que asigna los roles y relaciones

## Estructura de Roles

```
Administrador (admin@vidrios.com)
    └── Ve TODOS los proyectos

Manager (manager@vidrios.com)
    ├── Juan Pérez (usuario1@vidrios.com)
    └── María González (usuario2@vidrios.com)
```

## Proyectos de Ejemplo

Una vez creados los usuarios y ejecutada la migración, cada usuario tendrá proyectos de ejemplo:

- **Admin:** 2 proyectos (Proyecto Corporativo A, Proyecto Corporativo B)
- **Manager:** 2 proyectos (Proyecto Comercial Norte, Proyecto Residencial Sur)
- **Usuario1 (Juan):** 2 proyectos (Proyecto Casa Particular, Ventanas Comedor)
- **Usuario2 (María):** 2 proyectos (Espejos Baño Principal, Puertas de Vidrio)

## Pruebas Recomendadas

1. **Como Usuario Básico:**
   - Inicia sesión como usuario1@vidrios.com
   - Verifica que solo ves tus 2 proyectos
   - Intenta cargar proyectos - solo deberías ver los tuyos

2. **Como Manager:**
   - Inicia sesión como manager@vidrios.com
   - Verifica que ves tus proyectos + los de Juan y María
   - Nota los badges que indican el propietario de cada proyecto

3. **Como Administrador:**
   - Inicia sesión como admin@vidrios.com
   - Verifica que ves TODOS los proyectos de todos los usuarios
   - Puedes gestionar cualquier proyecto del sistema
