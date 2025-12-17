# Manual de Usuario - Sistema de Gestión de Vidriería

## Índice
1. [Introducción](#introducción)
2. [Inicio de Sesión](#inicio-de-sesión)
3. [Dashboard](#dashboard)
4. [Gestión de Clientes](#gestión-de-clientes)
5. [Gestión de Pedidos](#gestión-de-pedidos)
6. [Optimizador de Cortes](#optimizador-de-cortes)
7. [Gestión de Inventario](#gestión-de-inventario)
8. [Ejecución de Cortes](#ejecución-de-cortes)
9. [Preguntas Frecuentes](#preguntas-frecuentes)

---

## Introducción

El Sistema de Gestión de Vidriería es una herramienta completa diseñada para talleres de vidrio que permite:

- **Gestionar clientes** y su información de contacto
- **Crear y administrar pedidos** con seguimiento detallado
- **Optimizar cortes de vidrio** para reducir desperdicio
- **Controlar inventario** de materiales (placas y láminas)
- **Ejecutar cortes** con instrucciones paso a paso
- **Importar diseños** desde archivos SVG

El sistema está diseñado para ser intuitivo y fácil de usar, incluso para usuarios sin experiencia técnica.

---

## Inicio de Sesión

### Acceder al Sistema

1. Abra la aplicación en su navegador web
2. Haga clic en el botón **"Iniciar Sesión"** en la esquina superior derecha
3. Ingrese su correo electrónico y contraseña
4. Haga clic en **"Ingresar"**

### Recuperar Contraseña

Si olvidó su contraseña:

1. En la ventana de inicio de sesión, haga clic en **"¿Olvidaste tu contraseña?"**
2. Ingrese su correo electrónico
3. Recibirá un enlace para restablecer su contraseña
4. Siga las instrucciones en el correo electrónico

### Roles de Usuario

El sistema cuenta con dos tipos de usuarios:

- **Administrador**: Acceso completo a todas las funciones
- **Operador**: Acceso limitado a visualización y ejecución de cortes

---

## Dashboard

El Dashboard es la pantalla principal que muestra un resumen de su taller:

### Información Mostrada

- **Pedidos Activos**: Número total de pedidos en proceso
- **Pedidos del Día**: Pedidos creados o actualizados hoy
- **Utilización de Material**: Promedio de aprovechamiento de materiales
- **Inventario Bajo**: Alertas de materiales con poco stock

### Navegación Rápida

Desde el Dashboard puede acceder rápidamente a:

- Crear nuevo pedido
- Ver lista de clientes
- Revisar pedidos recientes
- Verificar inventario

---

## Gestión de Clientes

### Ver Lista de Clientes

1. Haga clic en la pestaña **"Clientes"** en el menú superior
2. Verá una lista con todos sus clientes
3. Use la barra de búsqueda para encontrar clientes específicos

### Agregar Nuevo Cliente

1. En la página de Clientes, haga clic en **"+ Agregar Cliente"**
2. Complete el formulario:
   - **Nombre**: Nombre completo o razón social
   - **Tipo**: Individual o Empresa
   - **Teléfono**: Número de contacto
   - **Email**: Correo electrónico
   - **Dirección**: Dirección completa
   - **Notas**: Información adicional (opcional)
3. Haga clic en **"Guardar Cliente"**

### Editar Cliente

1. En la lista de clientes, haga clic en el ícono de lápiz junto al cliente
2. Modifique la información necesaria
3. Haga clic en **"Guardar Cambios"**

### Eliminar Cliente

1. Haga clic en el ícono de basurero junto al cliente
2. Confirme la eliminación

**Nota**: No puede eliminar clientes que tienen pedidos asociados.

---

## Gestión de Pedidos

### Ver Pedidos

1. Haga clic en la pestaña **"Pedidos"** en el menú superior
2. Los pedidos se muestran organizados por estado:
   - **Cotizado**: Pedidos en espera de aprobación
   - **Aprobado**: Pedidos confirmados por el cliente
   - **En Producción**: Pedidos en proceso de corte
   - **Listo**: Pedidos terminados esperando entrega
   - **Entregado**: Pedidos completados
   - **Cancelado**: Pedidos anulados

### Crear Nuevo Pedido

1. Haga clic en **"+ Nuevo Pedido"**
2. Será redirigido al **Optimizador de Cortes**
3. Configure las dimensiones de la placa y los cortes necesarios
4. Guarde el pedido con un nombre descriptivo

### Cambiar Estado de Pedido

Los pedidos avanzan automáticamente según el flujo de trabajo:

1. **Cotizado** → Crear cotización inicial
2. **Aprobado** → Cliente acepta la cotización
3. **En Producción** → Se asigna material y comienza el corte
4. **Listo** → Cortes completados y verificados
5. **Entregado** → Cliente recibe el pedido

Para cambiar el estado:
- Haga clic en el botón de estado del pedido
- Seleccione el nuevo estado
- Confirme el cambio

### Ver Detalles de Pedido

1. Haga clic en cualquier pedido para ver sus detalles:
   - Información del cliente
   - Lista de cortes requeridos
   - Dimensiones de la placa
   - Material asignado
   - Estado de producción
   - Costos y totales

### Editar Pedido

1. Haga clic en el ícono de lápiz en el pedido
2. Será redirigido al optimizador con los datos del pedido
3. Realice los cambios necesarios
4. Guarde los cambios

### Importar desde SVG

Si tiene un diseño en formato SVG:

1. En la pantalla de pedidos, haga clic en **"Importar SVG"**
2. Seleccione el archivo SVG desde su computadora
3. El sistema detectará automáticamente las dimensiones de los cortes
4. Revise y ajuste si es necesario
5. Guarde el pedido

---

## Optimizador de Cortes

El optimizador es el corazón del sistema. Calcula la mejor forma de cortar las piezas para minimizar desperdicios.

### Configurar Dimensiones de la Placa

1. En el panel izquierdo, ingrese:
   - **Ancho de Placa (cm)**: Ancho total disponible
   - **Alto de Placa (cm)**: Alto total disponible
   - **Grosor del Disco (mm)**: Grosor de la herramienta de corte (generalmente 3-5mm)
   - **Grosor del Vidrio (mm)**: Espesor del material
   - **Método de Corte**: Manual o Máquina

### Agregar Cortes

1. Complete los campos:
   - **Ancho (cm)**: Ancho de la pieza
   - **Alto (cm)**: Alto de la pieza
   - **Cantidad**: Número de piezas iguales
   - **Etiqueta**: Nombre descriptivo (opcional)

2. Haga clic en **"Agregar Corte"**

3. La pieza aparecerá en la lista de cortes

### Visualización del Resultado

El panel derecho muestra:

- **Vista gráfica**: Disposición visual de los cortes en la placa
- **Utilización**: Porcentaje de aprovechamiento del material
- **Líneas de corte**: Guías visuales para realizar los cortes
- **Instrucciones paso a paso**: Secuencia ordenada de cortes
- **Desperdicios**: Áreas sobrantes que pueden reutilizarse

### Colores en la Visualización

- **Verde**: Cortes posicionados correctamente
- **Amarillo**: Áreas de desperdicio aprovechables
- **Rojo**: Áreas muy pequeñas, difíciles de reutilizar
- **Líneas azules**: Cortes horizontales
- **Líneas naranjas**: Cortes verticales

### Guardar Proyecto

1. Haga clic en **"Guardar Proyecto"**
2. Ingrese un nombre descriptivo
3. El proyecto se guarda automáticamente

### Cargar Proyecto

1. Haga clic en **"Cargar Proyecto"**
2. Seleccione el proyecto de la lista
3. Los datos se cargan automáticamente

### Limpiar Todo

Para empezar de nuevo:
1. Haga clic en **"Limpiar Todo"**
2. Confirme la acción
3. Todos los cortes se eliminarán

---

## Gestión de Inventario

### Ver Inventario

1. Haga clic en la pestaña **"Inventario"** en el menú superior
2. Verá todas las placas disponibles organizadas por:
   - Material (Vidrio, Espejo, Aluminio)
   - Grosor
   - Estado (Disponible, Reservado, Usado, Dañado)

### Agregar Nueva Placa

1. Haga clic en **"+ Agregar Placa"**
2. Complete el formulario:
   - **Tipo de Material**: Vidrio, Espejo o Aluminio
   - **Grosor (mm)**: Espesor de la placa
   - **Ancho (cm)**: Ancho total
   - **Alto (cm)**: Alto total
   - **Fecha de Compra**: Fecha de adquisición
   - **Costo de Compra**: Precio pagado
   - **Proveedor**: Nombre del proveedor
   - **Notas**: Información adicional (opcional)
3. Haga clic en **"Guardar Placa"**

### Editar Placa

1. Haga clic en el ícono de lápiz junto a la placa
2. Modifique la información necesaria
3. Guarde los cambios

### Marcar Placa como Dañada

Si una placa se daña:
1. Edite la placa
2. Cambie el estado a **"Dañada"**
3. Agregue notas explicando el daño
4. La placa no estará disponible para nuevos cortes

### Filtros de Inventario

Use los filtros para encontrar placas específicas:
- **Por tipo de material**
- **Por grosor**
- **Por estado**
- **Por rango de tamaño**

---

## Ejecución de Cortes

### Asignar Material a Pedido

Antes de cortar, debe asignar material:

1. En la lista de pedidos, encuentre el pedido con estado **"Aprobado"**
2. Haga clic en **"Asignar Material"**
3. El sistema sugerirá las mejores placas disponibles
4. Revise la propuesta:
   - Placas recomendadas
   - Utilización estimada
   - Costo de material
5. Haga clic en **"Confirmar Asignación"**
6. El pedido cambia a estado **"En Producción"**

### Iniciar Corte

1. En un pedido en estado **"En Producción"**, haga clic en **"Iniciar Corte"**
2. Verá la pantalla de ejecución con:
   - Visualización gráfica de los cortes
   - Lista de instrucciones paso a paso
   - Controles para marcar piezas completadas

### Seguir Instrucciones de Corte

Las instrucciones aparecen en orden:

**Ejemplo:**
```
Paso 1: Corte horizontal a 50cm desde arriba
  → Resultado: 2 piezas

Paso 2: Corte vertical a 30cm desde la izquierda en pieza superior
  → Resultado: 2 piezas

Paso 3: Corte horizontal a 25cm desde arriba en pieza inferior derecha
  → Resultado: 2 piezas
```

Para cada paso:
1. Lea la instrucción cuidadosamente
2. Realice el corte físico
3. Marque el paso como completado
4. Continue con el siguiente paso

### Registrar Piezas Fallidas

Si una pieza se rompe durante el corte:

1. En el formulario de ejecución, indique:
   - Número de piezas exitosas
   - Número de piezas fallidas
2. Agregue notas sobre qué sucedió (opcional)

### Completar Corte

1. Cuando termine todos los cortes, haga clic en **"Finalizar Corte"**
2. El sistema registrará:
   - Piezas producidas
   - Material utilizado
   - Desperdicios generados (se agregan automáticamente al inventario)
3. El pedido cambia a estado **"Listo"**

### Gestión de Desperdicios

Los desperdicios aprovechables se guardan automáticamente como nuevas placas con:
- Origen: "Desperdicio"
- Dimensiones calculadas
- Referencia al pedido original

Estos desperdicios aparecerán en el inventario y podrán usarse en futuros pedidos.

---

## Preguntas Frecuentes

### ¿Cómo calcula el sistema la optimización?

El sistema usa múltiples algoritmos avanzados (Guillotine, MaxRects, Skyline) y selecciona automáticamente el mejor resultado basándose en:
- Mayor utilización del material
- Menor número de cortes
- Menor desperdicio

### ¿Puedo modificar un pedido después de crearlo?

Sí, puede editar pedidos que estén en estado **"Cotizado"** o **"Aprobado"**. Una vez en producción, los cambios son limitados para mantener la integridad del proceso.

### ¿Qué pasa si me equivoco al cortar?

Registre las piezas fallidas en el formulario de ejecución. El sistema llevará un registro y ajustará el inventario de material utilizado.

### ¿Cómo puedo ver mi historial de pedidos?

En la pestaña "Pedidos", use los filtros para ver pedidos por estado, fecha o cliente. Puede filtrar por "Entregados" para ver el historial completo.

### ¿El sistema funciona sin internet?

No, el sistema requiere conexión a internet para funcionar ya que los datos se almacenan en la nube de forma segura.

### ¿Puedo usar el sistema en mi teléfono o tablet?

Sí, el sistema es completamente responsivo y funciona en dispositivos móviles, tablets y computadoras de escritorio.

### ¿Cómo puedo exportar mis datos?

Actualmente, puede imprimir los detalles de pedidos y visualizaciones. Las funciones de exportación a Excel/PDF estarán disponibles en futuras versiones.

### ¿Quién puede ver mis datos?

Sus datos están protegidos y solo son accesibles para:
- Usted y los usuarios de su cuenta
- El sistema implementa seguridad a nivel de fila (RLS) para proteger su información

### ¿Con qué frecuencia se respaldan mis datos?

Los datos se guardan automáticamente en la nube de Supabase, que realiza respaldos continuos. No necesita preocuparse por perder información.

### ¿Puedo importar mi inventario existente?

Sí, puede agregar su inventario actual manualmente usando la función "Agregar Placa" o contactar con soporte para ayuda con importación masiva.

---

## Soporte Técnico

Si tiene problemas o preguntas:

1. Revise este manual primero
2. Consulte la sección de Preguntas Frecuentes
3. Contacte a su administrador del sistema
4. Para soporte técnico adicional, contacte al desarrollador

---

**Última actualización**: Diciembre 2024
**Versión del Manual**: 1.0
