class_name PauseMenu
extends CanvasLayer

## Menú de Pausa modular con Inventario y Pantalla de Estadísticas.
## Basado en la arquitectura desacoplada de Godot Open RPG y diseñado para Whispers of the North.
## Se ejecuta con PROCESS_MODE_ALWAYS para funcionar mientras el juego está congelado (get_tree().paused = true).

signal menu_abierto()
signal menu_cerrado()

enum Pestana { INVENTARIO, STATS, SISTEMA }

# ===========================================================================
# PROPIEDADES CONFIGURABLES DESDE EL EDITOR VISUAL (INSPECTOR)
# ===========================================================================

@export_group("Encabezado del Menú")
## Título principal mostrado en la cabecera del menú de pausa (nodo Label 'Titulo')
@export var texto_titulo_menu: String = "PAUSA"
## Texto de atajos de teclado mostrado en la cabecera (nodo Label 'PistasTeclado')
@export var texto_pistas_menu: String = "[Q / E] Cambiar pestaña  |  [Esc / Start] Cerrar"

@export_group("Textos de Pestañas")
@export var texto_tab_inventario: String = "Inventario"
@export var texto_tab_stats: String = "Estadísticas"
@export var texto_tab_sistema: String = "Sistema"

@export_group("Textos de Inventario")
@export var texto_inventario_vacio: String = "El zurrón está vacío."
@export var texto_sin_seleccion: String = "Selecciona un objeto para ver sus detalles."
@export var texto_boton_usar: String = "Consumir"

@export_group("Textos de Estadísticas")
@export var texto_titulo_perfil: String = "Explorador del Norte"
@export var texto_etiqueta_hp: String = "SALUD (HP)"
@export var texto_etiqueta_ataque: String = "⚔️  Ataque:"
@export var texto_etiqueta_defensa: String = "🛡️  Defensa:"
@export var texto_etiqueta_velocidad: String = "👟  Velocidad:"
@export var texto_etiqueta_companero: String = "🐾  Acompañante:"
@export var texto_companero_activo: String = "Rata Traviesa 🐀 (Acompañando)"
@export var texto_companero_descanso: String = "Ninguno (Descansando)"

@export_group("Textos de Sistema")
@export var texto_btn_reanudar: String = "Reanudar"
@export var texto_btn_controles: String = "Controles"
@export var texto_btn_salir_menu: String = "Volver al Menú Principal"

@export_group("Visuales y Retratos")
@export var retrato_protagonista: Texture2D = preload("res://assets/sprites/ui/icon.png")
@export var icono_companero: Texture2D = preload("res://assets/sprites/environment/items/Rat.png")

@export_group("Audio y Efectos")
@export var sfx_abrir: AudioStream = preload("res://assets/audio/sfx/snd_dooropen.wav")
@export var sfx_cerrar: AudioStream = preload("res://assets/audio/sfx/snd_doorclose.wav")
@export var sfx_cursor: AudioStream = preload("res://assets/audio/sfx/snd_item.wav")
@export var sfx_confirmar: AudioStream = preload("res://assets/audio/sfx/snd_bell_bounce_short.wav")
@export var sfx_error: AudioStream = null

# Nodos de Interfaz
@onready var panel_fondo: Control = $FondoOscuro
@onready var contenedor_principal: Control = $ContenedorPrincipal
@onready var lbl_header_titulo: Label = $ContenedorPrincipal/Margen/VBox/Header/Titulo
@onready var lbl_header_pistas: Label = $ContenedorPrincipal/Margen/VBox/Header/PistasTeclado

# Pestañas
@onready var btn_tab_inventario: Button = $ContenedorPrincipal/Margen/VBox/BarraPestanas/BtnInventario
@onready var btn_tab_stats: Button = $ContenedorPrincipal/Margen/VBox/BarraPestanas/BtnStats
@onready var btn_tab_sistema: Button = $ContenedorPrincipal/Margen/VBox/BarraPestanas/BtnSistema

@onready var vista_inventario: Control = $ContenedorPrincipal/Margen/VBox/Vistas/VistaInventario
@onready var vista_stats: Control = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats
@onready var vista_sistema: Control = $ContenedorPrincipal/Margen/VBox/Vistas/VistaSistema

# Elementos de Inventario
@onready var grid_items: GridContainer = $ContenedorPrincipal/Margen/VBox/Vistas/VistaInventario/HBox/PanelSlots/Scroll/GridItems
@onready var lbl_vacio: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaInventario/HBox/PanelSlots/LabelVacio
@onready var detalle_icono: TextureRect = $ContenedorPrincipal/Margen/VBox/Vistas/VistaInventario/HBox/PanelDetalle/VBox/IconoGrande
@onready var detalle_nombre: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaInventario/HBox/PanelDetalle/VBox/LabelNombre
@onready var detalle_categoria: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaInventario/HBox/PanelDetalle/VBox/LabelCategoria
@onready var detalle_desc: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaInventario/HBox/PanelDetalle/VBox/LabelDescripcion
@onready var detalle_btn_usar: Button = $ContenedorPrincipal/Margen/VBox/Vistas/VistaInventario/HBox/PanelDetalle/VBox/BtnUsar

# Elementos de Stats
@onready var stats_retrato: TextureRect = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelPerfil/VBox/Retrato
@onready var stats_nombre: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelPerfil/VBox/LabelNombre
@onready var stats_titulo: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelPerfil/VBox/LabelTitulo
@onready var stats_nivel: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelPerfil/VBox/LabelNivel
@onready var stats_barra_exp: ProgressBar = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelPerfil/VBox/BarraEXP
@onready var stats_txt_exp: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelPerfil/VBox/LabelEXP
@onready var stats_lbl_salud: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/LabelSalud
@onready var stats_barra_hp: ProgressBar = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/BarraHP
@onready var stats_txt_hp: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/LabelHP
@onready var stats_lbl_ataque: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/GridStats/LblAtaque
@onready var stats_val_ataque: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/GridStats/ValAtaque
@onready var stats_lbl_defensa: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/GridStats/LblDefensa
@onready var stats_val_defensa: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/GridStats/ValDefensa
@onready var stats_lbl_velocidad: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/GridStats/LblVelocidad
@onready var stats_val_velocidad: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/GridStats/ValVelocidad
@onready var stats_lbl_acompanante: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/GridStats/LblAcompanante
@onready var stats_val_acompanante: Label = $ContenedorPrincipal/Margen/VBox/Vistas/VistaStats/HBox/PanelStatsValores/VBox/GridStats/ValAcompanante

# Elementos de Sistema
@onready var btn_reanudar: Button = $ContenedorPrincipal/Margen/VBox/Vistas/VistaSistema/VBox/BtnReanudar
@onready var btn_controles: Button = $ContenedorPrincipal/Margen/VBox/Vistas/VistaSistema/VBox/BtnControles
@onready var btn_salir_menu: Button = $ContenedorPrincipal/Margen/VBox/Vistas/VistaSistema/VBox/BtnSalirMenu

var pestana_actual: Pestana = Pestana.INVENTARIO
var _item_seleccionado_id: String = ""
var _indice_slot_enfocado: int = 0
var _botones_slots: Array[Button] = []
var _escena_controles = preload("res://scenes/ui/ControlsMenu.tscn")
var _panel_controles_activo: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	hide()
	
	_aplicar_textos_configurados()
	
	# Conexión de pestañas
	if not btn_tab_inventario.pressed.is_connected(func(): cambiar_pestana(Pestana.INVENTARIO)):
		btn_tab_inventario.pressed.connect(func(): cambiar_pestana(Pestana.INVENTARIO))
	if not btn_tab_stats.pressed.is_connected(func(): cambiar_pestana(Pestana.STATS)):
		btn_tab_stats.pressed.connect(func(): cambiar_pestana(Pestana.STATS))
	if not btn_tab_sistema.pressed.is_connected(func(): cambiar_pestana(Pestana.SISTEMA)):
		btn_tab_sistema.pressed.connect(func(): cambiar_pestana(Pestana.SISTEMA))
	
	# Conexión botones de sistema
	if not btn_reanudar.pressed.is_connected(cerrar_menu):
		btn_reanudar.pressed.connect(cerrar_menu)
	if not btn_controles.pressed.is_connected(_abrir_menu_controles):
		btn_controles.pressed.connect(_abrir_menu_controles)
	if not btn_salir_menu.pressed.is_connected(_ir_al_menu_principal):
		btn_salir_menu.pressed.connect(_ir_al_menu_principal)
	
	if not detalle_btn_usar.pressed.is_connected(_usar_item_seleccionado):
		detalle_btn_usar.pressed.connect(_usar_item_seleccionado)
	
	# Escuchar cambios de GameState si está disponible
	var game_state = _obtener_game_state()
	if game_state:
		if not game_state.inventario_modificado.is_connected(_actualizar_vista_inventario):
			game_state.inventario_modificado.connect(_actualizar_vista_inventario)
		if not game_state.stats_modificadas.is_connected(_actualizar_vista_stats):
			game_state.stats_modificadas.connect(_actualizar_vista_stats)

func _aplicar_textos_configurados() -> void:
	if lbl_header_titulo and not texto_titulo_menu.is_empty():
		lbl_header_titulo.text = texto_titulo_menu
	if lbl_header_pistas and not texto_pistas_menu.is_empty():
		lbl_header_pistas.text = texto_pistas_menu
	
	btn_tab_inventario.text = texto_tab_inventario
	btn_tab_stats.text = texto_tab_stats
	btn_tab_sistema.text = texto_tab_sistema
	
	lbl_vacio.text = texto_inventario_vacio
	detalle_desc.text = texto_sin_seleccion
	detalle_btn_usar.text = texto_boton_usar
	
	if stats_retrato and retrato_protagonista:
		stats_retrato.texture = retrato_protagonista
	if stats_titulo and not texto_titulo_perfil.is_empty():
		stats_titulo.text = texto_titulo_perfil
	if stats_lbl_salud: stats_lbl_salud.text = texto_etiqueta_hp
	if stats_lbl_ataque: stats_lbl_ataque.text = texto_etiqueta_ataque
	if stats_lbl_defensa: stats_lbl_defensa.text = texto_etiqueta_defensa
	if stats_lbl_velocidad: stats_lbl_velocidad.text = texto_etiqueta_velocidad
	if stats_lbl_acompanante: stats_lbl_acompanante.text = texto_etiqueta_companero
	
	btn_reanudar.text = texto_btn_reanudar
	btn_controles.text = texto_btn_controles
	btn_salir_menu.text = texto_btn_salir_menu

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		if event.is_action_pressed("pause") and not event.is_echo():
			var cur_scene = get_tree().current_scene
			if cur_scene and cur_scene.has_method("get_active_player"):
				var active = cur_scene.get_active_player()
				if active and "is_interacting" in active and active.is_interacting:
					return
			get_viewport().set_input_as_handled()
			abrir_menu()
		return
	
	# Si el submenú de controles está abierto, el botón cancelar o pausa cierra primero dicho submenú:
	if _panel_controles_activo and is_instance_valid(_panel_controles_activo):
		if (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")) and not event.is_echo():
			get_viewport().set_input_as_handled()
			_cerrar_menu_controles()
			return
		return
	
	# Si el menú de pausa principal está visible:
	if (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")) and not event.is_echo():
		get_viewport().set_input_as_handled()
		cerrar_menu()
		return
	
	# En la pestaña de inventario, presionar interact consumiría el ítem seleccionado
	if pestana_actual == Pestana.INVENTARIO and event.is_action_pressed("interact") and not event.is_echo():
		var foco = get_viewport().gui_get_focus_owner()
		if foco is Button and foco in _botones_slots:
			get_viewport().set_input_as_handled()
			_usar_item_seleccionado()
			return
	
	# Cambio de pestaña con teclas Q / E, Page Up / Page Down o Bumpers del gamepad (LB / RB)
	if (event.is_action_pressed("tab_prev") or event.is_action_pressed("ui_page_up")) and not event.is_echo():
		get_viewport().set_input_as_handled()
		var ant: int = (int(pestana_actual) - 1 + 3) % 3
		cambiar_pestana(ant as Pestana)
	elif (event.is_action_pressed("tab_next") or event.is_action_pressed("ui_page_down")) and not event.is_echo():
		get_viewport().set_input_as_handled()
		var sig: int = (int(pestana_actual) + 1) % 3
		cambiar_pestana(sig as Pestana)

## Abre el menú de pausa y congela el árbol de juego
func abrir_menu() -> void:
	if visible:
		return
	_detectar_companero()
	_reproducir_sonido(sfx_abrir)
	show()
	var t := get_tree() if is_inside_tree() else null
	if t != null:
		t.paused = true
	cambiar_pestana(Pestana.INVENTARIO)
	menu_abierto.emit()

## Cierra el menú y reanuda el juego
func cerrar_menu() -> void:
	if not visible:
		return
	if _panel_controles_activo and is_instance_valid(_panel_controles_activo):
		_cerrar_menu_controles()
	_reproducir_sonido(sfx_cerrar)
	hide()
	var t := get_tree() if is_inside_tree() else null
	if t != null:
		t.paused = false
	menu_cerrado.emit()

## Cambia entre Inventario, Stats y Sistema
func cambiar_pestana(nueva_pestana: Pestana) -> void:
	pestana_actual = nueva_pestana
	_reproducir_sonido(sfx_cursor)
	
	vista_inventario.visible = (pestana_actual == Pestana.INVENTARIO)
	vista_stats.visible = (pestana_actual == Pestana.STATS)
	vista_sistema.visible = (pestana_actual == Pestana.SISTEMA)
	
	_actualizar_estilo_pestanas()
	
	match pestana_actual:
		Pestana.INVENTARIO:
			_actualizar_vista_inventario()
			if not _botones_slots.is_empty() and is_inside_tree():
				_botones_slots[0].grab_focus()
		Pestana.STATS:
			_actualizar_vista_stats()
			if is_inside_tree():
				btn_tab_stats.grab_focus()
		Pestana.SISTEMA:
			if is_inside_tree():
				btn_reanudar.grab_focus()

func _actualizar_estilo_pestanas() -> void:
	var tabs = [btn_tab_inventario, btn_tab_stats, btn_tab_sistema]
	for i in range(tabs.size()):
		var btn: Button = tabs[i]
		if i == int(pestana_actual):
			btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		else:
			btn.remove_theme_color_override("font_color")

# ---------------------------------------------------------------------------
# Vista de Inventario
# ---------------------------------------------------------------------------

func _actualizar_vista_inventario() -> void:
	for c in grid_items.get_children():
		c.queue_free()
	_botones_slots.clear()
	
	var game_state = _obtener_game_state()
	var inventario: Inventory = game_state.inventario if game_state else null
	
	if inventario == null or inventario.esta_vacio():
		lbl_vacio.show()
		_limpiar_detalle()
		if visible and pestana_actual == Pestana.INVENTARIO and is_inside_tree():
			btn_tab_inventario.grab_focus()
		return
	
	lbl_vacio.hide()
	var lista_items: Array = inventario.obtener_lista_items()
	
	for i in range(lista_items.size()):
		var registro = lista_items[i]
		var item: InventoryItem = registro.get("item")
		var cant: int = registro.get("cantidad", 1)
		if item == null:
			continue
		
		var slot_btn: Button = Button.new()
		slot_btn.custom_minimum_size = Vector2(72, 72)
		slot_btn.focus_mode = Control.FOCUS_ALL
		slot_btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Contenedor interno del slot
		var margen: MarginContainer = MarginContainer.new()
		margen.set_anchors_preset(Control.PRESET_FULL_RECT)
		margen.add_theme_constant_override("margin_left", 6)
		margen.add_theme_constant_override("margin_top", 6)
		margen.add_theme_constant_override("margin_right", 6)
		margen.add_theme_constant_override("margin_bottom", 6)
		slot_btn.add_child(margen)
		
		var tex_rect: TextureRect = TextureRect.new()
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture = item.icono
		margen.add_child(tex_rect)
		
		if cant > 1:
			var lbl_cant: Label = Label.new()
			lbl_cant.text = str(cant)
			lbl_cant.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			lbl_cant.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			lbl_cant.set_anchors_preset(Control.PRESET_FULL_RECT)
			lbl_cant.add_theme_font_size_override("font_size", 12)
			lbl_cant.add_theme_color_override("font_outline_color", Color.BLACK)
			lbl_cant.add_theme_constant_override("outline_size", 4)
			margen.add_child(lbl_cant)
		
		# Conectar selección y uso: seleccionar al entrar/enfocar, y consumir al interactuar de nuevo
		var item_ref: InventoryItem = item
		var slot_idx: int = i
		slot_btn.focus_entered.connect(func():
			_indice_slot_enfocado = slot_idx
			_mostrar_detalle_item(item_ref)
		)
		slot_btn.mouse_entered.connect(func():
			_indice_slot_enfocado = slot_idx
			_mostrar_detalle_item(item_ref)
		)
		slot_btn.pressed.connect(func():
			_on_slot_presionado(item_ref, slot_idx)
		)
		
		grid_items.add_child(slot_btn)
		_botones_slots.append(slot_btn)
	
	if not _botones_slots.is_empty():
		var idx_a_enfocar: int = clamp(_indice_slot_enfocado, 0, _botones_slots.size() - 1)
		_indice_slot_enfocado = idx_a_enfocar
		if visible and pestana_actual == Pestana.INVENTARIO:
			_botones_slots[idx_a_enfocar].grab_focus()
		var item_a_mostrar: InventoryItem = lista_items[idx_a_enfocar].get("item")
		_mostrar_detalle_item(item_a_mostrar)

func _on_slot_presionado(item: InventoryItem, slot_idx: int) -> void:
	if item == null:
		return
	
	# Si este ítem ya es el seleccionado actualmente (o ya tiene el foco): interactuar de nuevo lo consume
	if _item_seleccionado_id == item.id:
		if item.puede_usarse():
			_consumir_item(item)
		else:
			_reproducir_sonido(sfx_cursor)
	else:
		# Primer clic o selección
		_indice_slot_enfocado = slot_idx
		_mostrar_detalle_item(item)
		_reproducir_sonido(sfx_cursor)

func _mostrar_detalle_item(item: InventoryItem) -> void:
	if item == null:
		_limpiar_detalle()
		return
	_item_seleccionado_id = item.id
	detalle_icono.texture = item.icono
	detalle_nombre.text = item.nombre
	detalle_categoria.text = "[" + item.obtener_nombre_categoria() + "]"
	detalle_desc.text = item.descripcion
	
	if item.puede_usarse():
		detalle_btn_usar.show()
		detalle_btn_usar.text = "%s (+%d HP) [Interactuar]" % [texto_boton_usar, item.curacion_hp]
	else:
		detalle_btn_usar.hide()

func _limpiar_detalle() -> void:
	_item_seleccionado_id = ""
	detalle_icono.texture = null
	detalle_nombre.text = "Selecciona un objeto"
	detalle_categoria.text = ""
	detalle_desc.text = ""
	detalle_btn_usar.hide()

func _usar_item_seleccionado() -> void:
	if _item_seleccionado_id.is_empty():
		return
	var game_state = _obtener_game_state()
	if not game_state:
		return
	var item: InventoryItem = game_state.inventario.obtener_item(_item_seleccionado_id)
	if item and item.puede_usarse():
		_consumir_item(item)

func _consumir_item(item: InventoryItem) -> void:
	if item == null or not item.puede_usarse():
		return
	var game_state = _obtener_game_state()
	if not game_state:
		return
	
	var curado: int = item.curacion_hp
	if game_state.usar_item(item.id):
		_reproducir_sonido(sfx_confirmar if sfx_confirmar else sfx_cursor)
		
		# Feedback temporal en el botón de consumir
		if detalle_btn_usar and is_instance_valid(detalle_btn_usar):
			detalle_btn_usar.text = "¡Consumido! (+%d HP)" % curado
		
		_actualizar_vista_inventario()
		_actualizar_vista_stats()


# ---------------------------------------------------------------------------
# Vista de Estadísticas (Stats)
# ---------------------------------------------------------------------------

## Detecta si el acompañante (rata) se encuentra con el jugador o registrado en GameState
func _detectar_companero() -> bool:
	var tiene: bool = false
	var current_scene = get_tree().current_scene if is_inside_tree() else null

	# 1. Comprobar si la escena actual expone el jugador activo (ej: World.gd)
	if current_scene and current_scene.has_method("get_active_player"):
		var active = current_scene.get_active_player()
		if active and is_instance_valid(active):
			for child in active.get_children():
				if is_instance_valid(child) and (child.name.begins_with("Rat") or child.is_in_group("rat")):
					tiene = true
					break

	# 2. Comprobar si algún nodo en el grupo 'rat' está emparentado a un personaje/jugador
	if not tiene and is_inside_tree():
		var ratas = get_tree().get_nodes_in_group("rat")
		for r in ratas:
			if is_instance_valid(r):
				var padre = r.get_parent()
				if padre != null and (padre is CharacterBody3D or padre.name.to_lower().contains("player") or padre.name.to_lower().contains("eric")):
					tiene = true
					break

	# 3. Sincronizar bidireccionalmente con GameState
	var game_state = _obtener_game_state()
	if game_state:
		if tiene:
			game_state.tiene_rata = true
		elif current_scene and current_scene.has_method("get_active_player"):
			game_state.tiene_rata = false
		else:
			tiene = game_state.tiene_rata

	return tiene

func _actualizar_vista_stats() -> void:
	var game_state = _obtener_game_state()
	
	var nom: String = game_state.nombre_jugador if (game_state and not game_state.nombre_jugador.is_empty()) else "Eric"
	# Priorizar la configuración del título establecida en el nodo principal (ej: "El Fuki")
	var tit: String = texto_titulo_perfil
	if tit.is_empty():
		tit = game_state.titulo_jugador if (game_state and not game_state.titulo_jugador.is_empty()) else "Explorador del Norte"
	var niv: int = game_state.nivel if game_state else 1
	var exp_act: int = game_state.exp_actual if game_state else 0
	var exp_sig: int = game_state.exp_para_siguiente_nivel if game_state else 50
	var tiene_comp: bool = _detectar_companero()
	
	stats_nombre.text = nom
	stats_titulo.text = tit
	stats_nivel.text = "Nivel %d" % niv
	
	stats_barra_exp.max_value = exp_sig
	stats_barra_exp.value = exp_act
	stats_txt_exp.text = "%d / %d EXP" % [exp_act, exp_sig]
	
	var st: BattlerStats = game_state.stats if game_state else null
	if st:
		var hp_mostrado: int = game_state.hp_actual if game_state else st.max_hp
		stats_barra_hp.max_value = st.max_hp
		stats_barra_hp.value = hp_mostrado
		stats_txt_hp.text = "%d / %d HP" % [hp_mostrado, st.max_hp]
		stats_val_ataque.text = str(st.ataque)
		stats_val_defensa.text = str(st.defensa)
		stats_val_velocidad.text = str(st.velocidad)
	
	stats_val_acompanante.text = texto_companero_activo if tiene_comp else texto_companero_descanso

# ---------------------------------------------------------------------------
# Vista de Sistema
# ---------------------------------------------------------------------------

func _abrir_menu_controles() -> void:
	if _panel_controles_activo and is_instance_valid(_panel_controles_activo):
		return
	var controles = _escena_controles.instantiate()
	_panel_controles_activo = controles
	add_child(controles)
	if controles.has_method("preparar"):
		controles.preparar()
	if controles.has_signal("regresar_pedido"):
		controles.regresar_pedido.connect(_cerrar_menu_controles)
	elif controles.has_signal("cerrar_solicitado"):
		controles.cerrar_solicitado.connect(_cerrar_menu_controles)
	elif controles.has_signal("tree_exited"):
		controles.tree_exited.connect(func():
			if btn_controles and is_inside_tree():
				btn_controles.grab_focus()
		)

func _cerrar_menu_controles() -> void:
	if _panel_controles_activo and is_instance_valid(_panel_controles_activo):
		_panel_controles_activo.queue_free()
		_panel_controles_activo = null
	if btn_controles and is_inside_tree():
		btn_controles.grab_focus()

func _ir_al_menu_principal() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

# ---------------------------------------------------------------------------
# Auxiliares
# ---------------------------------------------------------------------------

func _obtener_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var root: Node = null
	if is_inside_tree() and get_tree():
		root = get_tree().root
	elif Engine.get_main_loop() and "root" in Engine.get_main_loop():
		root = Engine.get_main_loop().root
	else:
		var p = get_parent()
		while p != null:
			if p.has_node("GameState"):
				return p.get_node("GameState")
			if p.get_parent() == null:
				root = p
				break
			p = p.get_parent()
	
	if root and root.has_node("GameState"):
		return root.get_node("GameState")
	return null

func _reproducir_sonido(stream: AudioStream) -> void:
	if stream == null or not is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
