# Sistema de Menú de Pausa, Inventario y Estadísticas

Arquitectura inspirada en Godot Open RPG (`gdquest-demos/godot-open-rpg`), adaptada con estética y controles nórdicos para *Whispers of the North*.

---

## 1. Arquitectura General

```
                     ┌───────────────────┐
                     │   GameState       │  (Autoload global)
                     │ (Autoload / Core) │  - Nivel, EXP, Stats (BattlerStats)
                     └─────────┬─────────┘  - Rata compañera
                               │            - Inventario activo
                               ▼
    ┌──────────────────────────────────────────────┐
    │              Inventory (Resource)            │
    │  - items: Dictionary[InventoryItem, int]    │
    │  - Senales: item_cambiado,                   │
    │             inventario_actualizado          │
    └──────────────────────┬───────────────────────┘
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
  ┌──────────────────────┐    ┌──────────────────────────────────┐
  │ InventoryItem (Res)  │    │           PauseMenu              │
  │ - id, nombre, desc   │    │  (scenes/ui/PauseMenu.tscn)      │
  │ - icono, categoria   │◄───┤  - Pestaña 1: Inventario         │
  │ - curacion_hp, etc.  │    │  - Pestaña 2: Stats (Eric + Rata)│
  └──────────────────────┘    │  - Pestaña 3: Sistema            │
                              └──────────────────────────────────┘
```

---

## 2. Componentes

### 2.1 `InventoryItem` (`scripts/inventory/inventory_item.gd`)
Recurso ligero de datos:
- `id`: Identificador único (`String`).
- `nombre`: Nombre para la interfaz (`String`).
- `descripcion`: Descripción narrativa o de uso (`String`).
- `icono`: Textura 2D para la cuadrícula (`Texture2D`).
- `categoria`: `Categoria.OBJETO`, `Categoria.CONSUMIBLE`, `Categoria.CLAVE`.
- `cantidad_maxima`: Límite por stack (por defecto 99).
- `curacion_hp`: Puntos de salud que restaura si es consumible.

### 2.2 `Inventory` (`scripts/inventory/inventory.gd`)
Gestor reactivo desacoplado de la UI:
- `agregar(item: InventoryItem, cantidad: int = 1) -> bool`
- `quitar(item: InventoryItem, cantidad: int = 1) -> bool`
- `obtener_cantidad(item: InventoryItem) -> int`
- `obtener_item(id: String) -> InventoryItem`
- `obtener_lista_items(categoria: int = -1) -> Array[InventoryItem]`
- `guardar() -> Dictionary` y `restaurar(datos: Dictionary)`
- Emite `inventario_actualizado()` y `item_cambiado(item, cantidad)`.

### 2.3 `GameState` (`scripts/core/game_state.gd`)
Autoload global registrado en `project.godot`:
- Persiste los stats del protagonista Eric (`BattlerStats`), salud actual (`hp_actual`), nivel, experiencia (`exp_actual`, `exp_para_siguiente_nivel`), estado de compañeros (`tiene_rata`) y la instancia global del `inventario`.
- `actualizar_hp(nuevo_hp: int)` y `curar_hp(cantidad: int)` gestionan la salud persistente entre el supramundo, objetos consumibles y combates.
- `agregar_exp(cantidad: int)` gestiona subidas de nivel de forma reactiva emitiendo `nivel_subido(nuevo_nivel)`.

### 2.4 `PauseMenu` (`scenes/ui/PauseMenu.tscn` / `scripts/ui/pause_menu.gd`)
Interfaz gráfica completa con `process_mode = PROCESS_MODE_ALWAYS` y **altamente configurable desde el Inspector de Godot**:
- **Propiedades exportadas (@export_group)**:
  - *Encabezado del Menú*: título principal del menú (`texto_titulo_menu`, por defecto `"PAUSA"`) y pistas de atajos (`texto_pistas_menu`).
  - *Textos de Pestañas*: títulos de Inventario, Estadísticas y Sistema.
  - *Textos de Inventario*: mensajes de zurrón vacío, selección y texto del botón consumir.
  - *Textos de Estadísticas*: título del perfil (`texto_titulo_perfil`, respeta configuraciones como `"El Fuki"`), etiquetas de HP, Ataque, Defensa, Velocidad, y estado del compañero (`texto_companero_activo` y `texto_companero_descanso`).
  - *Textos de Sistema*: botones de Reanudar, Controles y Menú Principal.
  - *Visuales y Retratos*: textura de retrato de Eric y del compañero.
  - *Audio y Efectos*: streams de sonido para abrir, cerrar, cursor, confirmar y error.
- **Detección Automática de Acompañante**:
  - `_detectar_companero()` inspecciona si el jugador activo tiene a la rata anclada como hijo o en el grupo `"rat"`.
  - Muestra directamente el texto configurado (`texto_companero_activo` o `texto_companero_descanso`) y sincroniza con `GameState.tiene_rata`.
- **Pestaña Inventario y Consumo Ágil de Objetos**:
  - Cuadrícula responsiva de slots con navegación intuitiva por teclado/gamepad/ratón.
  - **Uso directo sin ratón**: Al navegar o seleccionar un ítem consumible (e.g. Queso Nórdico), interactuar de nuevo sobre el mismo slot (`ui_accept`, botón `interact`, `Enter`, `Espacio`, `E` o botón `A` del mando) consume el objeto al instante y restaura la salud sin necesidad de mover el cursor hasta el panel lateral.
  - El foco de la interfaz se retiene en el slot activo tras consumir, evitando desorientación o bloqueo del foco.
  - Panel lateral de detalles (icono, nombre, categoría, cantidad, descripción completa y botón Usar interactivo).
- **Pestaña Estadísticas**:
  - Retrato de Eric y título/perfil respetando fielmente el valor asignado en el Inspector visual.
  - Nivel, barra de EXP, barra de HP sincronizada en tiempo real con `GameState.hp_actual`.
  - Insignias de combate: Ataque, Defensa, Velocidad.
- **Pestaña Sistema**:
  - Reanudar juego, submenú de remapeo de Controles (cerrable con `ui_cancel`, botón Regresar o `pause`), y volver al menú principal.

---

## 3. Integración en el Mundo y Combate

- **Supramundo (`World.gd`)**:
  - El menú de pausa puede abrirse desde cualquier momento de la exploración (a menos que el jugador esté en medio de una interacción).
  - Al abrirse, congela el árbol del juego (`get_tree().paused = true`), detiene a los personajes y muestra el cursor.
  - Detecta automáticamente si la rata está en la cabeza del jugador.
- **Combate (`CombatArena.gd` y `EncuentroCombate.gd`)**:
  - Al iniciar el combate, el battler del jugador arranca con la salud persistente de `GameState.hp_actual`.
  - Durante el combate, el menú de acciones usa botones con `focus_mode = FOCUS_NONE` y debounce desacoplado para los ejes del stick del mando, permitiendo alternar suavemente entre Golpear y Huir sin dobles saltos.
  - Al terminar el combate (por Victoria, Derrota o Huida), la vida restante del jugador se sincroniza automáticamente de vuelta a `GameState.hp_actual`.

---

## 4. Controles y Navegación

Sigue estrictamente las reglas de `AGENTS.md` e `INPUT_MAP.md`:

| Acción | Teclado | Gamepad | Función |
| :--- | :--- | :--- | :--- |
| `pause` | `Escape`, `P` | `Joypad Start` | Abrir / Cerrar menú de pausa |
| `ui_cancel` | `Escape` | `Joypad B` | Cerrar submenú / menú de pausa / volver atrás |
| `ui_accept` / `interact` | `Enter`, `Space`, `Z` | `Joypad A` | Seleccionar / Usar objeto |
| `tab_prev` | `Q`, `Page Up` | `Joypad LB / L1` | Cambiar a pestaña anterior |
| `tab_next` | `E`, `Page Down` | `Joypad RB / R1` | Cambiar a pestaña siguiente |
| `ui_up`, `ui_down`, `ui_left`, `ui_right` | Flechas / WASD | D-Pad / Stick Izq. | Navegar entre casillas y botones |

---

## 5. Cómo Crear Nuevos Ítems

Puedes crear ítems directamente en GDScript o como archivos de recurso `.tres`:

```gdscript
var pocion = InventoryItem.new()
pocion.id = "pocion_nieve"
pocion.nombre = "Poción de Nieve"
pocion.descripcion = "Restaura 10 puntos de salud con hierbas del monte."
pocion.categoria = InventoryItem.Categoria.CONSUMIBLE
pocion.curacion_hp = 10
pocion.icono = preload("res://assets/sprites/items/pocion.png") # Opcional

GameState.inventario.agregar(pocion, 3)
```
