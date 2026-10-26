# Sistema de Cámaras y Switches Autónomos (Whispers of the North)

Este documento detalla el sistema moderno de conmutación de cámaras entre áreas, plazas y calles del juego (por ejemplo en `World_Town` o `World`), reemplazando la necesidad de escribir scripts de escena tediosos o nombrar strings manualmente a ciegas.

---

## 1. Problema Anterior vs. Solución Moderna

### El Sistema Anterior (`World.tscn`)
- Requería crear manualmente un `Area3D`, añadirle un `CollisionShape3D`, y nombrarlo estrictamente `SwitchC_1_2`.
- `world.gd` leía los nombres mediante `split("_")` asumiendo que las cámaras estaban directamente en la raíz como `World/Camera1`.
- Si las cámaras se organizaban dentro de un nodo contenedor `Cameras/` (como en `World_Town`), el sistema se rompía.
- Los switches eran invisibles en el editor 3D: no se podía saber qué cámaras conectaba cada uno sin revisar el árbol de nodos.

### La Solución Moderna (`CameraSwitch` y `CameraSwitchManager`)
- **Visual e Inmediato (`@tool`):** 
  - **Color Debug Magenta Neón (`#FF1493`):** Máximo contraste frente a la nieve, árboles y cielo, imposible de perder de vista.
  - **Volumen Translúcido 3D (Por Defecto):** Muestra una barrera/caja translúcida en el suelo para ver con precisión el ancho exacto que cubre el trigger en la calle.
  - **Etiqueta 3D Opcional (`mostrar_etiqueta_editor`):** Desactivada por defecto para no saturar la vista con texto. Si la activas, tiene tamaño fijo (`fixed_size`) para no encogerse.
  - Al arrancar el juego se oculta automáticamente todo (cero impacto de rendimiento).
- **Auto-resolución Inteligente:** Encuentra cámaras tanto dentro de carpetas como `Cameras/`, `Camaras/`, o en la raíz, buscando `Camera1`, `Camera_1` o `Cam1`.
- **Auto-centrado y Alineación en 1 Clic:** Desde el Inspector, con un solo clic teletransporta el switch al punto medio exacto entre las dos cámaras conectadas y lo rota perpendicular a la calle/sendero.
- **Generación en Lote (`CameraSwitchManager`):** Permite conectar pares de cámaras en lote (`(1, 2)`, `(2, 3)`, etc.) y crearlos todos con sus tamaños y posiciones en segundos.
- **Protección anti-flicker:** Incorpora un cooldown inteligente para evitar que la cámara parpadee rápidamente si el jugador camina de un lado a otro sobre la línea de transición.

---

## 2. Archivos del Sistema

| Archivo | Tipo | Propósito |
| :--- | :--- | :--- |
| [scripts/world/camera_switch.gd](file:///c:/Users/luisa/OneDrive/Desktop/whispers%20of%20the%20north/scripts/world/camera_switch.gd) | Script (`@tool`) | Lógica autónoma de detección, cambio de cámara, auto-alineación y renderizado en editor. |
| [scenes/world/Entities/CameraSwitch.tscn](file:///c:/Users/luisa/OneDrive/Desktop/whispers%20of%20the%20north/scenes/world/Entities/CameraSwitch.tscn) | Escena / Prefab | Componente listo para arrastrar y soltar en cualquier mapa 3D. |
| [scripts/world/camera_switch_manager.gd](file:///c:/Users/luisa/OneDrive/Desktop/whispers%20of%20the%20north/scripts/world/camera_switch_manager.gd) | Script (`@tool`) | Nodo contenedor y generador rápido de switches en lote y setup de cámara inicial. |

---

## 3. Modos de Funcionamiento

1. **`ALTERNAR_A_B` (Por Defecto):**
   - Comportamiento clásico tipo Paper Mario. Si la cámara activa es A, cambia a B. Si la activa es B, cambia a A.
   - Si ninguna de las dos es la actual, activa automáticamente la más cercana al switch.
2. **`DIRECCIONAL`:**
   - Evalúa el vector de movimiento del jugador respecto a la orientación local del switch.
   - Si cruza hacia adelante (+Z hacia B), activa la Cámara B. Si cruza hacia atrás (-Z hacia A), activa la Cámara A. Ideal para puertas estrechas o túneles.
3. **`ZONA_FIJA`:**
   - Al entrar al volumen, fuerza la activación de una cámara fija específica (ideal para miradores, interiores o secretos).

---

## 4. Guía Paso a Paso para Usarlo

### Método A: Arrastrar el Prefab (Individual)
1. En el panel de **Archivos**, busca `res://scenes/world/Entities/CameraSwitch.tscn`.
2. Arrástralo a la escena dentro del mundo (por ejemplo como hijo de un nodo `Switches`).
3. En el **Inspector**:
   - En **Cámara A Num** pon el número de la primera cámara (ej: `1`).
   - En **Cámara B Num** pon el número de la segunda cámara (ej: `2`).
   - Haz clic en **Centrar Entre Cámaras**: el switch se moverá instantáneamente a mitad de camino entre Camera1 y Camera2.
   - Haz clic en **Alinear Con Cámaras**: el switch rotará para atravesar perpendicularmente el camino entre ambas.
   - Modifica **Tamaño Trigger** si el ancho de la calle lo requiere.
4. En el viewport 3D verás la etiqueta `[ 📷 Cam1 ⇄ Cam2 ]`.

### Método B: Duplicar Rápido (`Ctrl + D`)
1. Duplica cualquier `CameraSwitch` existente (`Ctrl + D`).
2. Renómbralo, por ejemplo, `Switch_2_3`.
3. El script detectará automáticamente los números `2` y `3` del nombre del nodo.
4. Haz clic en **Centrar Entre Cámaras** y ¡listo!

### Método C: Generación con `CameraSwitchManager`
1. Añade un `Node3D` a tu escena y nómbralo `Switches`.
2. Asígnale el script [scripts/world/camera_switch_manager.gd](file:///c:/Users/luisa/OneDrive/Desktop/whispers%20of%20the%20north/scripts/world/camera_switch_manager.gd).
3. En el Inspector:
   - En **Nuevo Switch Par**, pon `(X: 1, Y: 2)` y marca **Crear Switch Ahora**. Se creará y posicionará al instante.
   - O añade tus pares a la lista **Lista Pares Lote** (ej: `[(1,2), (2,3), (1,4), (4,5)]`) y activa **Generar Lote Completo**.

---

## 5. Cómo Previsualizar las Cámaras al Mover el Switch

Tienes tres formas prácticas y fluidas para ver cómo ven las cámaras el switch:

### Técnica 1: Multivista Nativa de Godot (La Mejor y en Tiempo Real)
En la barra superior del Viewport 3D de Godot:
1. Haz clic en el menú **Vista (View) → 2 Vistas** (o presiona `Ctrl + 2`).
2. En la vista principal (arriba), mantén la cámara libre del editor para seleccionar y mover el switch con las flechas del gizmo 3D.
3. En la segunda vista (abajo), haz clic en el menú desplegable de su esquina superior izquierda: **Cámara → Camera1** (o activa la casilla *Vista Previa / Preview* de la cámara).
4. **¡Listo!** Mientras arrastras el volumen del switch en la vista de arriba, verás en tiempo real en la pantalla de abajo exactamente cuándo entra y sale del campo de visión de la cámara.
*(También puedes usar **Vista → 3 Vistas** para tener Cámara 1 en una esquina, Cámara 2 en otra, y la vista libre arriba).*

### Técnica 2: Botones de Salto en el Inspector (1 Clic)
Al seleccionar cualquier `CameraSwitch`, en el Inspector bajo **Previsualización de Cámaras (Editor)**:
- **Mirar Como Cámara A:** Coloca instantáneamente la cámara del editor en la posición, rotación y FOV exactos de la Cámara A.
- **Mirar Como Cámara B:** Lo mismo para la Cámara B.

### Técnica 3: Líneas Guía 3D
- Activa la casilla **Mostrar Líneas A Cámaras** en el Inspector.
- Aparecerán dos rayos 3D de color (Azul hacia Cam A, Amarillo hacia Cam B) conectando el switch directamente con ambas cámaras para ver su ángulo y distancia mientras lo mueves.

---

## 6. Redimensionado Interactivo con Puntos Rojos (Gizmo Handles)

Para cambiar el tamaño del switch directamente en la vista 3D:

1. **Puntos Rojos en el Viewport 3D (Plugin Activado):**
   - Al seleccionar cualquier `CameraSwitch` en la escena, aparecerán automáticamente **puntos rojos de control** en las caras del volumen (+X, -X, +Y, +Z, -Z).
   - Simplemente haz clic y arrastra cualquiera de los puntos rojos con el ratón para ensanchar o estrechar la barrera por la calle.
   - Esto modifica el tamaño real del trigger y de la colisión sin deformar la escala del nodo.

2. **Si usas la herramienta Escalar de Godot (`S`):**
   - Si prefieres usar la herramienta de escalar tradicional de Godot (`S`), el script detecta automáticamente cualquier escala aplicada, la absorbe en `tamano_trigger` y resetea la escala a `(1, 1, 1)`. De este modo, la física nunca se rompe ni genera advertencias de distorsión.
   - También puedes pulsar el botón **Normalizar Escala Ahora** en el Inspector en cualquier momento.

3. **Independencia Total de Instancias (`resource_local_to_scene`):**
   - El recurso de forma de colisión (`BoxShape3D`) tiene activado `resource_local_to_scene = true` y auto-duplicación defensiva.
   - Modificar el tamaño, arrastrar los puntos rojos o escalar un switch en una calle jamás afectará a los otros switches de la escena. Cada calle, pasaje o plaza conserva sus propias dimensiones únicas.

