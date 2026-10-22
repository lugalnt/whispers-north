extends Control

## Menú de remapeo de controles dividido en Teclado y JoyCon.
## Usa el addon ControlsRemap para guardar/restaurar los bindings.
## Cada fila muestra: [Nombre acción]  [Badge tecla actual]  [Btn Cambiar]  [Btn ↺]

const BRIDGE_FONT_PATH = "res://assets/fonts/BridgeParapet.ttf"

# Acciones de gameplay que el jugador puede reasignar.
# Deben coincidir con las entradas en project.godot → [input]
const ACCIONES: Array[StringName] = [
	&"move_up",
	&"move_down",
	&"move_left",
	&"move_right",
	&"interact",
]

# Nombres amigables para mostrar al jugador
const NOMBRES_ACCION: Dictionary = {
	"move_up":    "Mover Arriba",
	"move_down":  "Mover Abajo",
	"move_left":  "Mover Izquierda",
	"move_right": "Mover Derecha",
	"interact":   "Interactuar",
}

# Icono de cada acción (se muestra antes del nombre)
const ICONOS_ACCION: Dictionary = {
	"move_up":    "↑",
	"move_down":  "↓",
	"move_left":  "←",
	"move_right": "→",
	"interact":   "✦",
}

# Nombres de botones de joypad según JoyButton enum de Godot
const NOMBRES_JOYBUTTON: Dictionary = {
	0:  "A / Cruz",
	1:  "B / Círculo",
	2:  "X / Cuadrado",
	3:  "Y / Triángulo",
	4:  "L1",
	5:  "R1",
	6:  "L2",
	7:  "R2",
	8:  "L3 (Stick)",
	9:  "R3 (Stick)",
	10: "Select / Share",
	11: "Start / Opciones",
	12: "D-Pad ↑",
	13: "D-Pad ↓",
	14: "D-Pad ←",
	15: "D-Pad →",
}

# Colores del sistema de UI
const COLOR_ACCION        := Color(0.92, 0.88, 0.78)
const COLOR_BADGE_BG      := Color(0.18, 0.14, 0.30, 1.0)
const COLOR_BADGE_BORDER  := Color(0.55, 0.40, 0.80, 0.85)
const COLOR_BADGE_TEXT    := Color(1.0,  0.95, 0.70, 1.0)
const COLOR_ESCUCHA_BG    := Color(0.45, 0.20, 0.10, 1.0)
const COLOR_ESCUCHA_BORDER:= Color(1.0,  0.55, 0.15, 1.0)
const COLOR_ESCUCHA_TEXT  := Color(1.0,  0.80, 0.30, 1.0)
const COLOR_OK            := Color(0.55, 1.0,  0.65, 1.0)
const COLOR_WARN          := Color(1.0,  0.75, 0.25, 1.0)
const COLOR_ERROR         := Color(1.0,  0.45, 0.35, 1.0)

signal regresar_pedido

@onready var _tab_container:   TabContainer = $PanelFondo/VBox/TabContainer
@onready var _btn_regresar:    Button       = $PanelFondo/VBox/BotonesPie/BtnRegresar
@onready var _btn_restablecer: Button       = $PanelFondo/VBox/BotonesPie/BtnRestablecer
@onready var _btn_guardar:     Button       = $PanelFondo/VBox/BotonesPie/BtnGuardar
@onready var _lista_teclado:   VBoxContainer = $PanelFondo/VBox/TabContainer/Teclado/ListaTeclado
@onready var _lista_joycon:    VBoxContainer = $PanelFondo/VBox/TabContainer/JoyCon/ListaJoycon
@onready var _label_estado:    Label         = $PanelFondo/VBox/LabelEstado

var _remap: ControlsRemap
var _escuchando:    bool       = false
var _accion_actual: StringName = &""
var _tipo_actual:   String     = ""   # "keyboard" o "joypad"
var _boton_activo:  Button     = null  # botón "Cambiar" activo
var _badge_activo:  Panel      = null  # badge de la fila activa

var _font: FontFile = null

# Tween para la animación de parpadeo
var _tween_parpadeo: Tween = null


func _ready() -> void:
	_font = load(BRIDGE_FONT_PATH)

	# Crear el recurso de remapeo.
	# El setter de prefix carga la action_list desde ProjectSettings y llama _load_defaults().
	# Luego sobreescribimos _action_list con las acciones del juego y recargamos defaults.
	_remap = ControlsRemap.new("")
	_remap._action_list = ACCIONES
	_remap._load_defaults()

	_construir_lista_teclado()
	_construir_lista_joycon()

	_btn_regresar.pressed.connect(_on_regresar)
	_btn_restablecer.pressed.connect(_on_restablecer)
	_btn_guardar.pressed.connect(_on_guardar)

	_label_estado.text = ""

	# Foco inicial en el primer tab
	_tab_container.current_tab = 0


# -------------------------------------------------
#  CONSTRUCCIÓN DE LISTAS
# -------------------------------------------------

func _construir_lista_teclado() -> void:
	for accion in ACCIONES:
		var fila := _crear_fila(accion, "keyboard")
		_lista_teclado.add_child(fila)


func _construir_lista_joycon() -> void:
	for accion in ACCIONES:
		var fila := _crear_fila(accion, "joypad")
		_lista_joycon.add_child(fila)


func _crear_fila(accion: StringName, tipo: String) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.name = "Fila_%s_%s" % [accion, tipo]
	fila.add_theme_constant_override("separation", 10)

	# ── 1. Ícono + nombre de la acción ──────────────────────────────────────
	var lbl := Label.new()
	var icono: String = ICONOS_ACCION.get(accion, "•")
	lbl.text = "%s  %s" % [icono, NOMBRES_ACCION.get(accion, accion)]
	lbl.custom_minimum_size = Vector2(150, 0)
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if _font:
		lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", COLOR_ACCION)
	fila.add_child(lbl)

	# ── 2. Badge con la tecla/botón actual ──────────────────────────────────
	var badge := _crear_badge(accion, tipo)
	fila.add_child(badge)

	# ── 3. Botón "Cambiar" ──────────────────────────────────────────────────
	var btn := Button.new()
	btn.name    = "Btn_%s_%s" % [accion, tipo]
	btn.text    = "Cambiar"
	btn.tooltip_text = "Haz clic y luego presiona la nueva %s" % ("tecla" if tipo == "keyboard" else "botón de gamepad")
	btn.custom_minimum_size = Vector2(100, 40)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if _font:
		btn.add_theme_font_override("font", _font)
	btn.add_theme_font_size_override("font_size", 15)
	btn.set_meta("accion", accion)
	btn.set_meta("tipo", tipo)
	btn.set_meta("badge", badge)
	btn.pressed.connect(_on_btn_reasignar.bind(btn))
	fila.add_child(btn)

	# ── 4. Botón reset individual ───────────────────────────────────────────
	var btn_reset := Button.new()
	btn_reset.text         = "↺"
	btn_reset.custom_minimum_size = Vector2(40, 40)
	btn_reset.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_reset.tooltip_text = "Restablecer \"%s\" al valor por defecto" % NOMBRES_ACCION.get(accion, accion)
	if _font:
		btn_reset.add_theme_font_override("font", _font)
	btn_reset.add_theme_font_size_override("font_size", 16)
	btn_reset.pressed.connect(_on_reset_individual.bind(accion, tipo, badge))
	fila.add_child(btn_reset)

	return fila


# Crea el panel "badge" que muestra la tecla/botón asignada visualmente.
func _crear_badge(accion: StringName, tipo: String) -> Panel:
	var panel := Panel.new()
	panel.name = "Badge_%s_%s" % [accion, tipo]
	panel.custom_minimum_size = Vector2(150, 40)
	panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var sb := StyleBoxFlat.new()
	sb.bg_color     = COLOR_BADGE_BG
	sb.border_color = COLOR_BADGE_BORDER
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left     = 6
	sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_left  = 6
	sb.corner_radius_bottom_right = 6
	sb.corner_detail    = 6
	sb.content_margin_left   = 8.0
	sb.content_margin_right  = 8.0
	sb.content_margin_top    = 4.0
	sb.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.name = "LblBadge"
	lbl.text = _obtener_texto_binding(accion, tipo)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	# Panel no es un Container: anclamos la etiqueta para que ocupe todo el badge
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.offset_left  = 6.0
	lbl.offset_right = -6.0
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.clip_text    = true
	if _font:
		lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", COLOR_BADGE_TEXT)
	panel.add_child(lbl)

	return panel


# Aplica o quita el estilo "escuchando" al badge.
func _badge_set_escuchando(badge: Panel, activo: bool) -> void:
	var sb := badge.get_theme_stylebox("panel") as StyleBoxFlat
	if not sb:
		return
	var lbl := badge.get_node_or_null("LblBadge") as Label
	if activo:
		sb.bg_color     = COLOR_ESCUCHA_BG
		sb.border_color = COLOR_ESCUCHA_BORDER
		if lbl:
			lbl.add_theme_color_override("font_color", COLOR_ESCUCHA_TEXT)
	else:
		sb.bg_color     = COLOR_BADGE_BG
		sb.border_color = COLOR_BADGE_BORDER
		if lbl:
			lbl.add_theme_color_override("font_color", COLOR_BADGE_TEXT)


# Devuelve el Label interno del badge.
func _badge_label(badge: Panel) -> Label:
	return badge.get_node_or_null("LblBadge") as Label


func _obtener_texto_binding(accion: StringName, tipo: String) -> String:
	if tipo == "keyboard":
		var ev := _remap.get_action_key(accion)
		if ev:
			return OS.get_keycode_string(ev.physical_keycode) if ev.physical_keycode != 0 else OS.get_keycode_string(ev.keycode)
		return "—"
	else:
		var ev := _remap.get_action_button(accion)
		if ev:
			return NOMBRES_JOYBUTTON.get(ev.button_index, "Botón %d" % ev.button_index)
		return "—"


# -------------------------------------------------
#  ESCUCHA DE NUEVA TECLA / BOTÓN
# -------------------------------------------------

func _on_btn_reasignar(btn: Button) -> void:
	if _escuchando:
		_cancelar_escucha()

	_accion_actual = btn.get_meta("accion")
	_tipo_actual   = btn.get_meta("tipo")
	_boton_activo  = btn
	_badge_activo  = btn.get_meta("badge") as Panel
	_escuchando    = true

	# Actualizar badge a modo "escucha"
	_badge_set_escuchando(_badge_activo, true)
	var lbl_badge := _badge_label(_badge_activo)
	if lbl_badge:
		lbl_badge.text = "Presiona…"

	btn.text = "Cancelar"
	btn.modulate = Color(1.0, 0.75, 0.3, 1.0)

	_set_estado(
		"⌨  Presiona una %s para asignarla   (Esc = cancelar)" % ("tecla" if _tipo_actual == "keyboard" else "botón de gamepad"),
		COLOR_WARN
	)
	_iniciar_parpadeo(_badge_activo)


func _input(event: InputEvent) -> void:
	if not visible or not is_inside_tree():
		return

	if not _escuchando:
		var es_cancelar: bool = (event is InputEventAction and event.action == &"ui_cancel") or event.is_action_pressed("ui_cancel")
		var es_tab_prev: bool = (event is InputEventAction and event.action == &"tab_prev") or event.is_action_pressed("tab_prev") or event.is_action_pressed("ui_page_up")
		var es_tab_next: bool = (event is InputEventAction and event.action == &"tab_next") or event.is_action_pressed("tab_next") or event.is_action_pressed("ui_page_down")

		if es_cancelar and event.is_pressed() and not event.is_echo():
			if get_viewport():
				get_viewport().set_input_as_handled()
			_on_regresar()
			return
		elif es_tab_prev and event.is_pressed() and not event.is_echo():
			if get_viewport():
				get_viewport().set_input_as_handled()
			var n_tabs: int = _tab_container.get_tab_count()
			if n_tabs > 0:
				_tab_container.current_tab = (_tab_container.current_tab - 1 + n_tabs) % n_tabs
			return
		elif es_tab_next and event.is_pressed() and not event.is_echo():
			if get_viewport():
				get_viewport().set_input_as_handled()
			var n_tabs: int = _tab_container.get_tab_count()
			if n_tabs > 0:
				_tab_container.current_tab = (_tab_container.current_tab + 1) % n_tabs
			return
		return

	if event.is_action("ui_cancel") and event.is_pressed():
		_cancelar_escucha()
		get_viewport().set_input_as_handled()
		return

	if _tipo_actual == "keyboard" and event is InputEventKey:
		if not event.is_pressed() or event.is_echo():
			return
		get_viewport().set_input_as_handled()
		_aplicar_tecla(event as InputEventKey)

	elif _tipo_actual == "joypad" and event is InputEventJoypadButton:
		if not event.is_pressed():
			return
		get_viewport().set_input_as_handled()
		_aplicar_boton_joypad(event as InputEventJoypadButton)


func _aplicar_tecla(ev: InputEventKey) -> void:
	_remap.set_action_key(_accion_actual, ev)
	var texto: String = OS.get_keycode_string(ev.physical_keycode) if ev.physical_keycode != 0 else OS.get_keycode_string(ev.keycode)
	_finalizar_reasignacion(texto)


func _aplicar_boton_joypad(ev: InputEventJoypadButton) -> void:
	_remap.set_action_button(_accion_actual, ev)
	_finalizar_reasignacion(NOMBRES_JOYBUTTON.get(ev.button_index, "Botón %d" % ev.button_index))


func _finalizar_reasignacion(texto: String) -> void:
	if _badge_activo:
		var lbl := _badge_label(_badge_activo)
		if lbl:
			lbl.text = texto
	_cancelar_escucha()
	_revisar_duplicados()


func _cancelar_escucha() -> void:
	_detener_parpadeo()

	if _badge_activo:
		_badge_set_escuchando(_badge_activo, false)
		var lbl := _badge_label(_badge_activo)
		if lbl and lbl.text == "Presiona…":
			lbl.text = _obtener_texto_binding(_accion_actual, _tipo_actual)
		_badge_activo = null

	if _boton_activo:
		_boton_activo.text    = "Cambiar"
		_boton_activo.modulate = Color.WHITE
		_boton_activo = null

	_escuchando    = false
	_accion_actual = &""
	_tipo_actual   = ""


# -------------------------------------------------
#  PARPADEO DEL BADGE DURANTE ESCUCHA
# -------------------------------------------------

func _iniciar_parpadeo(badge: Panel) -> void:
	_detener_parpadeo()
	_tween_parpadeo = create_tween().set_loops()
	_tween_parpadeo.tween_property(badge, "modulate:a", 0.3, 0.45)
	_tween_parpadeo.tween_property(badge, "modulate:a", 1.0, 0.45)


func _detener_parpadeo() -> void:
	if _tween_parpadeo and _tween_parpadeo.is_valid():
		_tween_parpadeo.kill()
	_tween_parpadeo = null
	if _badge_activo:
		_badge_activo.modulate.a = 1.0


# -------------------------------------------------
#  DUPLICADOS
# -------------------------------------------------

func _revisar_duplicados() -> void:
	var dupes := _remap.find_duplicates()
	if dupes.is_empty():
		_set_estado("✔  Sin conflictos. Puedes guardar.", COLOR_OK)
	else:
		var nombres := dupes.map(func(a): return NOMBRES_ACCION.get(a, a))
		_set_estado("⚠  Conflicto en: %s" % ", ".join(nombres), COLOR_ERROR)


# -------------------------------------------------
#  RESET INDIVIDUAL
# -------------------------------------------------

func _on_reset_individual(accion: StringName, tipo: String, badge: Panel) -> void:
	_remap.restore_action_default(accion)
	var lbl := _badge_label(badge)
	if lbl:
		lbl.text = _obtener_texto_binding(accion, tipo)
	_set_estado("↺  \"%s\" restablecida al valor por defecto." % NOMBRES_ACCION.get(accion, accion), COLOR_OK)


# -------------------------------------------------
#  BOTONES DE PIE
# -------------------------------------------------

func _on_restablecer() -> void:
	_remap.restore_default_controls()
	_refrescar_todos_los_badges()
	_set_estado("↺  Todos los controles restablecidos.", COLOR_OK)


func _on_guardar() -> void:
	var dupes := _remap.find_duplicates()
	if not dupes.is_empty():
		var nombres := dupes.map(func(a): return NOMBRES_ACCION.get(a, a))
		_set_estado("⚠  Corrige los conflictos antes de guardar: %s" % ", ".join(nombres), COLOR_ERROR)
		return
	_remap.create_remap()
	_set_estado("✔  Controles guardados correctamente.", COLOR_OK)


func _on_regresar() -> void:
	if _escuchando:
		_cancelar_escucha()
	regresar_pedido.emit()


# -------------------------------------------------
#  UTILIDADES
# -------------------------------------------------

func _set_estado(texto: String, color: Color) -> void:
	_label_estado.text = texto
	_label_estado.add_theme_color_override("font_color", color)


func _refrescar_todos_los_badges() -> void:
	for accion in ACCIONES:
		for tipo in ["keyboard", "joypad"]:
			var lista: VBoxContainer = _lista_teclado if tipo == "keyboard" else _lista_joycon
			var fila := lista.get_node_or_null("Fila_%s_%s" % [accion, tipo])
			if not fila:
				continue
			var badge := fila.get_node_or_null("Badge_%s_%s" % [accion, tipo]) as Panel
			if not badge:
				continue
			var lbl := _badge_label(badge)
			if lbl:
				lbl.text = _obtener_texto_binding(accion, tipo)


## Llamar desde MainMenu o PauseMenu al mostrar este panel.
func preparar() -> void:
	_label_estado.text = ""
	_refrescar_todos_los_badges()
	if _btn_regresar and is_inside_tree():
		_btn_regresar.grab_focus()
