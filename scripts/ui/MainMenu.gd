extends Node2D

@export var velocidad_ruedas: float = 2.5
@export var velocidad_carretera: float = 80.0
@export var velocidad_bosque: float = 0.0
@export var velocidad_montanas: float = 0.0
@export var velocidad_nubes: float = 3.0

# Duración de la animación de transición menú ↔ opciones
const DURACION_TRANSICION: float = 0.45

# Posiciones X del menú principal
const MENU_X_VISIBLE: float = 0.0
const MENU_X_OCULTO: float = -500.0

# Posición X visible del panel de opciones
const OPCIONES_X_VISIBLE: float = 200.0

# FondoMenu es hijo directo del MainMenu (sin SubViewport)
@onready var fondo_menu = $FondoMenu

@onready var carretera = fondo_menu.get_node("Carretera")
@onready var bosques   = fondo_menu.get_node("Bosques")
@onready var montanas  = fondo_menu.get_node("Montanas")
@onready var nubes     = fondo_menu.get_node("Nubes")
@onready var auto      = fondo_menu.get_node("Auto")

@onready var menu         = $Menu
@onready var audio_player = $AudioStreamPlayer

# Referencia al panel y sus controles (se llenan en _ready)
var panel_opciones: Control
var slider_volumen: HSlider
var slider_efectos: HSlider
var check_pantalla: CheckButton
var opciones_res:   OptionButton

# Flags de estado
var _animando: bool = false
var _transicionando: bool = false

# Pantalla donde estaba la ventana antes de entrar a fullscreen
var _pantalla_antes_fs: int = 0

# ColorRect para el fade a negro (se crea en _ready)
var _fade_rect: ColorRect


# ─────────────────────────────────────────────
#  RESPONSIVIDAD
# ─────────────────────────────────────────────

func _opciones_x_oculto() -> float:
	return get_viewport().get_visible_rect().size.x + 100.0


func _ready() -> void:
	# ── Overlay de fadeout ──────────────────────────────────────────
	# ColorRect negro que cubre toda la pantalla; empieza invisible
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

	# ── Construir PanelOpciones en runtime ──────────────────────────
	var existente = get_node_or_null("PanelOpciones")
	if existente:
		panel_opciones = existente
		slider_volumen = panel_opciones.get_node("ListaOpciones/SliderVolumen")
		slider_efectos = panel_opciones.get_node("ListaOpciones/SliderEfectos")
		check_pantalla = panel_opciones.get_node("ListaOpciones/CheckPantalla")
		opciones_res   = panel_opciones.get_node("ListaOpciones/OpcionesResolucion")
		var btn_reg = panel_opciones.get_node_or_null("ListaOpciones/Regresar")
		if btn_reg and not btn_reg.pressed.is_connected(_on_regresar_pressed):
			btn_reg.pressed.connect(_on_regresar_pressed)
	else:
		_crear_panel_opciones()

	# Conectar señales del panel (con guard para no duplicar)
	if not slider_volumen.value_changed.is_connected(_on_slider_volumen_changed):
		slider_volumen.value_changed.connect(_on_slider_volumen_changed)
	if not slider_efectos.value_changed.is_connected(_on_slider_efectos_changed):
		slider_efectos.value_changed.connect(_on_slider_efectos_changed)
	if not check_pantalla.toggled.is_connected(_on_check_pantalla_toggled):
		check_pantalla.toggled.connect(_on_check_pantalla_toggled)
	if not opciones_res.item_selected.is_connected(_on_opciones_resolucion_item_selected):
		opciones_res.item_selected.connect(_on_opciones_resolucion_item_selected)

	# Conectar botón Opciones (guard por si ya lo conectó el .tscn)
	var btn_opciones = $Menu/ListaDeBotones/Opciones
	if not btn_opciones.pressed.is_connected(_on_opciones_pressed):
		btn_opciones.pressed.connect(_on_opciones_pressed)

	# Posiciones iniciales
	menu.position.x           = MENU_X_VISIBLE
	panel_opciones.position.x = _opciones_x_oculto()

	# Poblar resoluciones
	opciones_res.clear()
	opciones_res.add_item("1280 × 720")
	opciones_res.add_item("1920 × 1080")
	opciones_res.add_item("2560 × 1440")
	opciones_res.select(1)

	# Sincronizar volumen
	slider_volumen.value = db_to_linear(audio_player.volume_db)


# ─────────────────────────────────────────────
#  CREAR PANEL EN RUNTIME (fallback)
# ─────────────────────────────────────────────

func _crear_panel_opciones() -> void:
	panel_opciones = Control.new()
	panel_opciones.name = "PanelOpciones"
	panel_opciones.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel_opciones.size = Vector2(700, 1080)
	add_child(panel_opciones)

	var titulo = Label.new()
	titulo.name = "TituloOpciones"
	titulo.text = "Opciones"
	titulo.position = Vector2(20, 30)
	titulo.size = Vector2(400, 60)
	panel_opciones.add_child(titulo)

	var lista = VBoxContainer.new()
	lista.name = "ListaOpciones"
	lista.position = Vector2(20, 110)
	lista.size = Vector2(500, 500)
	panel_opciones.add_child(lista)

	var lbl_vol = Label.new(); lbl_vol.text = "Volumen de Música"
	lista.add_child(lbl_vol)

	slider_volumen = HSlider.new()
	slider_volumen.name = "SliderVolumen"
	slider_volumen.custom_minimum_size = Vector2(400, 40)
	slider_volumen.min_value = 0.0; slider_volumen.max_value = 1.0
	slider_volumen.step = 0.01; slider_volumen.value = 0.8
	lista.add_child(slider_volumen)

	var lbl_efx = Label.new(); lbl_efx.text = "Volumen de Efectos"
	lista.add_child(lbl_efx)

	slider_efectos = HSlider.new()
	slider_efectos.name = "SliderEfectos"
	slider_efectos.custom_minimum_size = Vector2(400, 40)
	slider_efectos.min_value = 0.0; slider_efectos.max_value = 1.0
	slider_efectos.step = 0.01; slider_efectos.value = 1.0
	lista.add_child(slider_efectos)

	var lbl_pant = Label.new(); lbl_pant.text = "Pantalla Completa"
	lista.add_child(lbl_pant)

	check_pantalla = CheckButton.new()
	check_pantalla.name = "CheckPantalla"; check_pantalla.text = "Activar"
	lista.add_child(check_pantalla)

	var lbl_res = Label.new(); lbl_res.text = "Resolución"
	lista.add_child(lbl_res)

	opciones_res = OptionButton.new()
	opciones_res.name = "OpcionesResolucion"
	opciones_res.custom_minimum_size = Vector2(300, 40)
	lista.add_child(opciones_res)

	var sep = Control.new()
	sep.custom_minimum_size = Vector2(0, 30)
	lista.add_child(sep)

	var btn_regresar = Button.new()
	btn_regresar.name = "Regresar"; btn_regresar.text = "< Regresar"
	btn_regresar.flat = true
	btn_regresar.custom_minimum_size = Vector2(200, 60)
	btn_regresar.pressed.connect(_on_regresar_pressed)
	lista.add_child(btn_regresar)


func _process(delta: float) -> void:
	carretera.scroll_offset.x -= velocidad_carretera * delta
	bosques.scroll_offset.x   -= velocidad_bosque   * delta
	montanas.scroll_offset.x  -= velocidad_montanas * delta
	nubes.scroll_offset.x     -= velocidad_nubes    * delta
	auto.get_node("LlantaIzq").rotation += velocidad_ruedas * delta
	auto.get_node("LlantaDer").rotation += velocidad_ruedas * delta


# ─────────────────────────────────────────────
#  ANIMACIÓN DE INICIO DE PARTIDA
# ─────────────────────────────────────────────

func _on_inicio_pressed() -> void:
	# Evitar doble disparo
	if _transicionando or _animando:
		return
	_transicionando = true

	# Deshabilitar todos los botones de interacción inmediatamente
	$Menu/ListaDeBotones/Inicio.disabled   = true
	$Menu/ListaDeBotones/Opciones.disabled = true
	$Menu/ListaDeBotones/Salir.disabled    = true

	# ── FASE 1: Menú se desliza hacia la izquierda ─────────────────
	var t_menu = create_tween()
	t_menu.set_ease(Tween.EASE_IN_OUT)
	t_menu.set_trans(Tween.TRANS_CUBIC)
	t_menu.tween_property(menu, "position:x", MENU_X_OCULTO, 0.6)

	# ── FASE 2: Aceleración del fondo ──────────────────────────────
	# La carretera y las ruedas aceleran de forma progresiva (ease-in)
	var t_accel = create_tween().set_parallel(true)
	t_accel.set_ease(Tween.EASE_IN)
	t_accel.set_trans(Tween.TRANS_QUAD)
	t_accel.tween_property(self, "velocidad_carretera", 650.0, 2.0)
	t_accel.tween_property(self, "velocidad_ruedas",    28.0, 2.0)
	t_accel.tween_property(self, "velocidad_nubes",     18.0, 2.0)

	# ── FASE 3: Carro sale por la derecha ──────────────────────────
	# Empieza a moverse 0.35s después del click para que la aceleración
	# del fondo ya sea visible antes de que el carro "arranque"
	var t_carro = create_tween()
	t_carro.tween_interval(0.35)
	t_carro.tween_property(auto, "position:x", 1400.0, 1.8)\
		.set_ease(Tween.EASE_IN)\
		.set_trans(Tween.TRANS_QUAD)

	# ── FASE 4: Fadeout a negro ────────────────────────────────────
	# Comienza cuando el carro ya casi ha salido (1.6s tras el click)
	var t_fade = create_tween()
	t_fade.tween_interval(1.6)
	t_fade.tween_property(_fade_rect, "modulate:a", 1.0, 0.9)\
		.set_ease(Tween.EASE_IN_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	t_fade.tween_callback(_ir_a_juego)


func _ir_a_juego() -> void:
	get_tree().change_scene_to_file("res://scenes/world/World.tscn")


# ─────────────────────────────────────────────
#  TRANSICIONES MENÚ ↔ OPCIONES
# ─────────────────────────────────────────────

func _ir_a_opciones() -> void:
	if _animando or _transicionando:
		return
	_animando = true

	var tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(menu, "position:x", MENU_X_OCULTO, DURACION_TRANSICION)
	tween.tween_property(panel_opciones, "position:x", OPCIONES_X_VISIBLE, DURACION_TRANSICION)

	await tween.finished
	_animando = false


func _ir_al_menu() -> void:
	if _animando or _transicionando:
		return
	_animando = true

	var tween = create_tween().set_parallel(true)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(menu, "position:x", MENU_X_VISIBLE, DURACION_TRANSICION)
	tween.tween_property(panel_opciones, "position:x", _opciones_x_oculto(), DURACION_TRANSICION)

	await tween.finished
	_animando = false


# ─────────────────────────────────────────────
#  SEÑALES DE BOTONES
# ─────────────────────────────────────────────

func _on_salir_pressed() -> void:
	get_tree().quit()


func _on_opciones_pressed() -> void:
	_ir_a_opciones()


func _on_regresar_pressed() -> void:
	_ir_al_menu()


# ─────────────────────────────────────────────
#  SEÑALES DE OPCIONES
# ─────────────────────────────────────────────

func _on_slider_volumen_changed(value: float) -> void:
	if value > 0.0:
		audio_player.volume_db = linear_to_db(value)
		audio_player.stream_paused = false
	else:
		audio_player.stream_paused = true


func _on_slider_efectos_changed(value: float) -> void:
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(max(value, 0.0001)))
		AudioServer.set_bus_mute(bus_idx, value <= 0.0)


func _on_check_pantalla_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_pantalla_antes_fs = DisplayServer.window_get_current_screen()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_current_screen(_pantalla_antes_fs)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		await get_tree().process_frame
		DisplayServer.window_set_current_screen(_pantalla_antes_fs)
		_aplicar_resolucion(opciones_res.selected)


func _on_opciones_resolucion_item_selected(index: int) -> void:
	var modo = DisplayServer.window_get_mode()
	if modo == DisplayServer.WINDOW_MODE_FULLSCREEN or modo == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		return
	_aplicar_resolucion(index)


func _aplicar_resolucion(index: int) -> void:
	var resoluciones: Array[Vector2i] = [
		Vector2i(1280, 720),
		Vector2i(1920, 1080),
		Vector2i(2560, 1440),
	]
	if index < 0 or index >= resoluciones.size():
		return

	var nueva_res: Vector2i = resoluciones[index]
	var pantalla_idx: int = DisplayServer.window_get_current_screen()
	var tamanio_pantalla: Vector2i = DisplayServer.screen_get_size(pantalla_idx)
	if nueva_res.x > tamanio_pantalla.x or nueva_res.y > tamanio_pantalla.y:
		push_warning("Resolución %s supera el monitor (%s). No se aplica." % [nueva_res, tamanio_pantalla])
		return

	get_window().size = nueva_res
	get_window().position = (tamanio_pantalla - nueva_res) / 2
