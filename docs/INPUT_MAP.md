# 🎮 Controles e Input Map (estándar del proyecto)

> **Regla de oro:** los controles se definen **UNA sola vez** en
> `Proyecto → Configuración del Proyecto → Mapa de Entrada (Input Map)`
> (se guardan en la sección `[input]` de `project.godot`).
> **Nunca** se crean acciones ni eventos desde código con `InputMap.add_action()`
> / `InputMap.action_add_event()` / `InputEventKey.new()` para el gameplay.

Así teclado y gamepad funcionan siempre sin código extra, y el día que se
implemente el remapeo desde Opciones solo hay que modificar estas mismas acciones.

---

## Acciones disponibles

| Acción | Uso | Teclado | Gamepad |
|---|---|---|---|
| `move_up` | Mover arriba | `W`, `↑` | Stick izq. ↑, D-pad ↑ |
| `move_down` | Mover abajo | `S`, `↓` | Stick izq. ↓, D-pad ↓ |
| `move_left` | Mover izquierda | `A`, `←` | Stick izq. ←, D-pad ← |
| `move_right` | Mover derecha | `D`, `→` | Stick izq. →, D-pad → |
| `interact` | Interactuar (puertas, cofres, arbustos, NPCs, empujar al jarrón embrujado, etc.) | `Z`, `E`, `Enter`, `Espacio` | Botón A (abajo) |
| `pause` | Abrir / Cerrar Menú de Pausa (Inventario, Stats, Opciones) | `Escape`, `P` | Botón Start (Menú) |
| `tab_prev` | Pestaña anterior en menús con tabs | `Q`, `Page Up` | Botón LB / L1 (Hombro Izq.) |
| `tab_next` | Pestaña siguiente en menús con tabs | `E`, `Page Down` | Botón RB / R1 (Hombro Der.) |


- Las teclas usan `physical_keycode` (posición física), por lo que WASD funciona
  igual en teclados QWERTY, AZERTY, etc.
- Los sticks tienen `deadzone` de `0.2`.
- **Menús / UI:** se usan las acciones integradas de Godot (`ui_accept`,
  `ui_cancel`, `ui_left`, `ui_right`, `ui_up`, `ui_down`, `ui_focus_next`, …).
  Ya traen teclado **y** gamepad por defecto. No se redefinen en `project.godot`
  salvo que sea necesario.
- **Excepción:** `ui_accept` está definida explícitamente en `project.godot`
  (`Z`, `E`, `Enter`, `Enter` numérico, `Espacio`, Botón A del gamepad) para garantizar que tanto `Z`/`E` como el
  gamepad puedan activar los botones de menús (principal, combate, diálogos).

> `ui_*` = interfaz y navegación de menús. `move_*` / `interact` = gameplay en el mundo.
> **No mezclar**: no uses `ui_accept` para interactuar en el mundo ni `interact` para menús.

---

## Cómo usarlas en código

### Movimiento (cada frame)

```gdscript
func _physics_process(delta):
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
```
`get_vector` ya maneja deadzone y normaliza entre teclado, stick y D-pad.

### Interacción puntual (un solo disparo)

Dentro de `_unhandled_input`, usar el **evento** (no `Input.is_action_just_pressed`):

```gdscript
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		interactuar()
```

### Consulta en `_process` / `_physics_process`

```gdscript
if Input.is_action_just_pressed("interact"):
	...
```

---

## ✅ Hacer / ❌ No hacer

| ✅ Hacer | ❌ No hacer |
|---|---|
| Usar los nombres de la tabla (`move_*`, `interact`) | Usar `KEY_Z`, `KEY_W`, `JOY_BUTTON_A`, etc. directamente en scripts |
| Añadir nuevas acciones desde el editor (Input Map) | Crear acciones con `InputMap.add_action()` en `_ready()` |
| Dar siempre teclado **y** gamepad a cada acción nueva | Añadir acciones solo con teclado |
| Reutilizar una acción existente si significa lo mismo | Duplicar acciones (`A`, `accion_z`, `interactuar2`…) |
| Comprobar en el editor que la acción aparece en Input Map | Chequear `ev is InputEventKey and ev.keycode == ...` para gameplay |

---

## Añadir una acción nueva

1. Abrir `Proyecto → Configuración del Proyecto → Mapa de Entrada`.
2. Escribir el nombre en **minúsculas con `snake_case`** (ej. `pause`, `cancel`, `attack`) y pulsar *Añadir*.
3. Asignar **al menos una tecla y un botón/eje de gamepad** (`+` → *Escuchar entrada*).
4. Usarla en código solo por nombre: `"pause"`.
5. **Documentarla en la tabla de este archivo.**

Acciones previstas a futuro (aún **no** creadas): `cancel`, `pause`, `menu`/`inventory`, `run`.

### Convenciones de botón de gamepad (layout Xbox)

| Botón | Índice Godot | Uso sugerido |
|---|---|---|
| A (abajo) | `JOY_BUTTON_A` (0) | `interact` / confirmar |
| B (derecha) | `JOY_BUTTON_B` (1) | `cancel` / volver |
| X (izquierda) | `JOY_BUTTON_X` (2) | acción secundaria |
| Y (arriba) | `JOY_BUTTON_Y` (3) | inventario / menú rápido |
| Start | `JOY_BUTTON_START` (6) | `pause` |
| D-pad | 11 ↑ · 12 ↓ · 13 ← · 14 → | movimiento / navegación |
| Stick izq. | Ejes 0 (X) y 1 (Y) | movimiento |

---

## Preparado para remapeo de controles (futuro)

Como todo vive en el `InputMap`, el remapeo en Opciones se hace sobre estas mismas acciones:

```gdscript
# Reemplazar el evento de teclado de una acción
func remapear_tecla(accion: String, nuevo_evento: InputEventKey) -> void:
	for ev in InputMap.action_get_events(accion):
		if ev is InputEventKey:
			InputMap.action_erase_event(accion, ev)
	InputMap.action_add_event(accion, nuevo_evento)

# Restaurar valores por defecto (los de project.godot)
InputMap.load_from_project_settings()
```

Recomendaciones para implementarlo:
- Guardar los eventos personalizados en `user://controls.cfg` (`ConfigFile`) y
  aplicarlos al iniciar el juego en un Autoload (ej. `InputSettings.gd`),
  **no** en las escenas de gameplay.
- Separar el remapeo de teclado y el de gamepad (borrar solo el tipo de evento que se está cambiando).
- Los scripts de gameplay **no cambian**: siguen usando `"interact"`, `"move_*"`, etc.

---

## Historial

- Se eliminó `_setup_input_map()` de `world.gd` (creaba `ui_accept` con Z/A en cada ejecución).
- Se eliminó la acción de prueba `A` de `project.godot`.
- `player.gd`, `door.gd` y `chest.gd` migrados a `move_*` / `interact`.
- `pot.gd` (jarrón embrujado) usa `interact` dentro de `_unhandled_input` para empujar al jarrón.
