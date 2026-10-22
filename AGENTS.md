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

