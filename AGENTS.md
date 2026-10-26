# Guía para asistentes de IA y colaboradores

Proyecto Godot 4 (GDScript). Lee esto antes de modificar código.

## Controles / Input (OBLIGATORIO)

- Todas las acciones de entrada viven en `project.godot` → `[input]`
  (Proyecto → Configuración del Proyecto → Mapa de Entrada).
- **No** crear acciones ni eventos desde código (`InputMap.add_action`,
  `InputMap.action_add_event`, `InputEventKey.new()`) ni leer teclas/botones
  crudos (`KEY_*`, `JOY_BUTTON_*`) en gameplay.
- Acciones existentes de gameplay: `move_up`, `move_down`, `move_left`,
  `move_right`, `interact` (teclado + gamepad ya configurados).
- Menús/UI: usar las acciones integradas `ui_*` de Godot.
- Movimiento: `Input.get_vector("move_left", "move_right", "move_up", "move_down")`.
- Interacción: `event.is_action_pressed("interact")` dentro de `_unhandled_input`.
- Si necesitas una acción nueva: añádela en el Input Map con teclado **y** gamepad,
  nombre en `snake_case`, y documéntala en [docs/INPUT_MAP.md](docs/INPUT_MAP.md).

Detalle completo, ejemplos y plan de remapeo: [docs/INPUT_MAP.md](docs/INPUT_MAP.md).

## Sistema de Combate RPG (Paper Mario)

- La orquestación de encuentros se realiza a través del nodo custom `EncuentroCombate` ([scripts/combat/encuentro_combate.gd](scripts/combat/encuentro_combate.gd)), configurable desde el Inspector visual de Godot.
- La arena de combate vive en [scenes/combat/CombatArena.tscn](scenes/combat/CombatArena.tscn) y se instancia aislada en altura (`Y = 200.0`).
- Para disparar un combate desde una entidad o `Area3D`, añadir `EncuentroCombate` como hijo y llamar `await encuentro.iniciar_combate(jugador, nodo_a_ocultar)` (o activar `auto_iniciar_en_area`).
- Guía completa de uso, arquitectura, creación de enemigos (`Battler`) y acciones (`BattlerAction`): [docs/SISTEMA_COMBATE.md](docs/SISTEMA_COMBATE.md).

## Sistema de Menú de Pausa, Inventario y Estadísticas

- Autoload `GameState` ([scripts/core/game_state.gd](scripts/core/game_state.gd)) gestiona la progresión, nivel, stats de Eric, compañero (rata) e inventario reactivo.
- Menú de pausa en [scenes/ui/PauseMenu.tscn](scenes/ui/PauseMenu.tscn) / [scripts/ui/pause_menu.gd](scripts/ui/pause_menu.gd), integrado en `World.tscn` mediante la acción `pause` (`Escape`, `P`, Gamepad `Start`).
- Los objetos heredan de `InventoryItem` ([scripts/inventory/inventory_item.gd](scripts/inventory/inventory_item.gd)) y son gestionados por `Inventory` ([scripts/inventory/inventory.gd](scripts/inventory/inventory.gd)).
- Guía completa de arquitectura y uso: [docs/MENU_PAUSA_E_INVENTARIO.md](docs/MENU_PAUSA_E_INVENTARIO.md).

## Sistema de Ítems, Pickups 3D y Pools del Mundo (Loot Tables)

- Los objetos del juego son recursos `InventoryItem` (.tres) guardados en `res://data/items/`, editables desde el Inspector visual de Godot (sprites, atributos, categorías, curación).
- `ItemDatabase` ([scripts/inventory/item_database.gd](scripts/inventory/item_database.gd)) auto-descubre e indexa cualquier nuevo `.tres` colocado en la carpeta sin tocar código.
- Los coleccionables 3D en el mundo usan `ItemPickup3D` ([scripts/world/item_pickup.gd](scripts/world/item_pickup.gd) / [scenes/world/Entities/ItemPickup.tscn](scenes/world/Entities/ItemPickup.tscn)) con visualización en tiempo real en el editor (`@tool`).
- Las tablas de botín aleatorias usan `ItemPool` ([scripts/inventory/item_pool.gd](scripts/inventory/item_pool.gd)), configurables en jarrones ([scripts/world/pot.gd](scripts/world/pot.gd)), cofres ([scripts/world/chest.gd](scripts/world/chest.gd)) y combates ([scripts/combat/encuentro_combate.gd](scripts/combat/encuentro_combate.gd)).
- Guía completa de creación, edición y colocación: [docs/ITEMS_Y_POOLS_DEL_MUNDO.md](docs/ITEMS_Y_POOLS_DEL_MUNDO.md).

## Sistema de Diálogo Dinámico (Dialogue Manager)

- Autoload `DialogueManager` y plugin activados en `project.godot`.
- La orquestación y detección de diálogos en el mundo 3D se gestiona con `InteraccionDialogo` ([scripts/dialogue/interaccion_dialogo.gd](scripts/dialogue/interaccion_dialogo.gd) / [scenes/dialogue/InteraccionDialogo.tscn](scenes/dialogue/InteraccionDialogo.tscn)), integrable como hijo de cualquier NPC, cartel, objeto o zona de disparo.
- Soporta tanto archivos `.dialogue` complejos como líneas rápidas configurables directamente desde el Inspector sin crear archivos.
- Globo de diálogo temático nórdico en [scenes/dialogue/NordicDialogueBalloon.tscn](scenes/dialogue/NordicDialogueBalloon.tscn).
- Congela a Eric durante la charla, orienta cinemáticamente a los personajes y muestra indicadores 3D animados `[E] Hablar`.
- Guía completa y ejemplos: [docs/SISTEMA_DIALOGO.md](docs/SISTEMA_DIALOGO.md).

## Sistema de Cámaras y Switches Autónomos

- Componente autónomo `CameraSwitch` ([scripts/world/camera_switch.gd](scripts/world/camera_switch.gd) / [scenes/world/Entities/CameraSwitch.tscn](scenes/world/Entities/CameraSwitch.tscn)) para alternar cámaras entre áreas del mundo sin scripts globales.
- Renderizado visual en editor 3D (`@tool`) con etiquetas flotantes `[ 📷 Cam1 ⇄ Cam2 ]`.
- Soporta auto-centrado y alineación entre cámaras en 1 clic desde el Inspector.
- Administrador en lote `CameraSwitchManager` ([scripts/world/camera_switch_manager.gd](scripts/world/camera_switch_manager.gd)) para instanciar y conectar pares de cámaras rápidamente.
- Guía completa de uso y modos: [docs/SISTEMA_CAMARAS_Y_SWITCHES.md](docs/SISTEMA_CAMARAS_Y_SWITCHES.md).

## Sistema de Transiciones y Enlace de Mundos (World Transitions)

- Componente autónomo `WorldTransition` ([scripts/world/world_transition.gd](scripts/world/world_transition.gd) / [scenes/world/Entities/WorldTransition.tscn](scenes/world/Entities/WorldTransition.tscn)) para enlazar escenas como `World` y `World_Town`.
- Sustituye marcadores de salida con efectos ambientales diegéticos (brisa de viento y partículas atmosféricas de sendero).
- Ejecuta fundido cinematográfico a negro, reproduce SFX y persiste la posición, cámara y acompañante (rata) a través de `GameState`.
- Controlador `world_town.gd` ([scripts/world/world_town.gd](scripts/world/world_town.gd)) en `World_Town.tscn` gestiona la recepción del jugador, la activación de cámara inicial y el menú de pausa unificado.


