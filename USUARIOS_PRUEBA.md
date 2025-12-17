# Usuarios de Prueba - Sistema de Optimización de Corte de Vidrios

Este documento contiene las credenciales de 5 usuarios de prueba con diferentes niveles de acceso.

## Credenciales de Acceso

### 1. Usuario Administrador
- **Email:** admin@vidrios.com
- **Contraseña:** Admin123!
- **Rol:** Administrador
- **Permisos:**
  - Acceso completo al sistema
  - Ve TODOS los pedidos de todos los usuarios
  - Puede gestionar cualquier pedido
  - Puede eliminar registros
  - Gestiona configuración del sistema
  - Gestiona catálogos de precios

### 2. Operador (Ex-Manager)
- **Email:** manager@vidrios.com
- **Contraseña:** Manager123!
- **Rol:** Operador
- **Permisos:**
  - Ve TODOS los pedidos del sistema (para poder trabajar en cualquiera)
  - Ve TODOS los clientes (para identificar pedidos)
  - Ve TODO el inventario de materiales
  - Puede crear y editar pedidos
  - Puede crear y editar clientes
  - Puede gestionar inventario
  - NO puede eliminar registros

### 3. Operador #1 (Ex-Usuario Básico)
- **Email:** usuario1@vidrios.com
- **Contraseña:** Usuario123!
- **Rol:** Operador
- **Permisos:**
  - Mismos permisos que el Operador arriba
  - Ve todos los pedidos del taller
  - Puede trabajar con cualquier pedido asignado

### 4. Operador #2 (Ex-Usuario Básico)
- **Email:** usuario2@vidrios.com
- **Contraseña:** Usuario123!
- **Rol:** Operador
- **Permisos:**
  - Mismos permisos que el Operador arriba
  - Ve todos los pedidos del taller
  - Puede trabajar con cualquier pedido asignado

### 5. Miguel Alcaino (Operador)
- **Email:** malcaino@vidrios.com
- **Contraseña:** Miguel123!
- **Rol:** Operador
- **Permisos:**
  - Mismos permisos que los operadores arriba
  - Ve todos los pedidos del taller
  - Puede trabajar con cualquier pedido asignado

## Sistema Actual

**IMPORTANTE:** El sistema ha sido actualizado a un modelo simplificado de roles:

### Estructura de Roles Actual

```
Administrador (admin@vidrios.com)
    └── Acceso completo: gestión total del sistema

Operadores (todos los demás usuarios)
    ├── manager@vidrios.com
    ├── usuario1@vidrios.com
    ├── usuario2@vidrios.com
    └── malcaino@vidrios.com

    └── Acceso compartido: ven TODOS los pedidos del taller para poder trabajarlos
```

### ¿Por qué este cambio?

En un taller de vidriería real, los operadores necesitan ver TODOS los pedidos para poder:
- Identificar qué pedidos deben trabajar
- Ver el estado de todos los trabajos en curso
- Asignar materiales de manera eficiente
- Optimizar el uso de placas de vidrio entre diferentes pedidos

## Pedidos de Ejemplo

El sistema incluye 20 pedidos de ejemplo distribuidos entre los usuarios:

- **Admin:** Varios pedidos corporativos
- **Operadores:** Varios pedidos residenciales y comerciales

**TODOS los usuarios pueden ver TODOS los pedidos**, pero solo el admin puede eliminarlos.

## Pruebas Recomendadas

1. **Como Operador:**
   - Inicia sesión como usuario1@vidrios.com o cualquier otro operador
   - Verifica que ves TODOS los 20 pedidos del sistema
   - Crea un nuevo pedido
   - Edita cualquier pedido existente
   - Intenta eliminar un pedido (debería fallar - solo admin puede hacerlo)
   - Gestiona el inventario de materiales
   - Crea clientes y visualiza todos los clientes del taller

2. **Como Administrador:**
   - Inicia sesión como admin@vidrios.com
   - Verifica que ves TODOS los pedidos
   - Puedes editar cualquier pedido
   - Puedes eliminar pedidos
   - Puedes gestionar el catálogo de precios
   - Puedes cambiar roles de usuarios
   - Acceso completo a toda la configuración del sistema
