extends Node3D

# Referencias a los nodos de personaje en la escena
@onready var player_16: CharacterBody3D = $Player
@onready var player_32: CharacterBody3D = $Player32 

@export var escena_menu_pausa: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")
var _menu_pausa: PauseMenu = null

func _ready() -> void:
	_setup_camera_switches()
	# Los controles (move_*, interact) se definen en Project Settings > Input Map
	# El juego empieza solo con el personaje de 16x16 activo
	player_32.hide() 
	player_32.process_mode = Node.PROCESS_MODE_DISABLED 

	if escena_menu_pausa:
		_menu_pausa = escena_menu_pausa.instantiate() as PauseMenu
		add_child(_menu_pausa)
	
	_procesar_transicion_entrada()

func _procesar_transicion_entrada() -> void:
	var gs = _obtener_game_state()
	if gs == null or not gs.hay_transicion_pendiente():
		return
	
	# Restaurar variante de personaje (16x16 o 32x32) si venía usando 32x32
	if gs.usar_personaje_32 and player_16 and player_32 and player_16.visible:
		cambiar_personaje(player_16, player_32)
	
	var active = get_active_player()
	
	# 1. Colocar al jugador en el punto de entrada
	var pos_destino: Vector3 = gs.consumir_posicion_spawn(self)
	if pos_destino != Vector3.ZERO and active != null:
		if active.is_inside_tree():
			active.global_position = pos_destino
		else:
			active.position = pos_destino
		active.reset_physics_interpolation()
	
	# 2. Activar la cámara de destino (ej: Camera6)
	var cam_nombre: String = gs.consumir_camara_spawn()
	if not cam_nombre.is_empty():
		var cam: Camera3D = get_node_or_null(cam_nombre) as Camera3D
		if cam == null:
			cam = find_child(cam_nombre, true, false) as Camera3D
		if cam:
			cam.make_current()
	
	# 3. Restaurar acompañante (Rata) si corresponde
	if gs.tiene_rata and active != null:
		_asegurar_rata(active)
	
	# 4. Fundido suave de entrada (fade in desde negro)
	_animar_fade_in(active)

func _asegurar_rata(jugador: CharacterBody3D) -> void:
	for c in jugador.get_children():
		if c.name.begins_with("Rat") or c.is_in_group("rat"):
			return
	var escena_rata: PackedScene = load("res://scenes/world/Entities/Rat.tscn")
	if escena_rata:
		var rata = escena_rata.instantiate()
		rata.name = "Rat"
		jugador.add_child(rata)
		rata.position = Vector3(0, 1.2, 0)

func _animar_fade_in(jugador: CharacterBody3D) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 120
	var rect := ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	add_child(canvas)
	
	if jugador and "is_interacting" in jugador:
		jugador.is_interacting = true
	
	var tw = create_tween()
	tw.tween_property(rect, "modulate:a", 0.0, 0.45)
	await tw.finished
	canvas.queue_free()
	
	if is_instance_valid(jugador) and "is_interacting" in jugador:
		jugador.is_interacting = false

# --- Sistema de cámaras ---
# Cada Area3D llamada "SwitchC_A_B" alterna entre Camera<A> y Camera<B> cuando el jugador la cruza.
func _setup_camera_switches() -> void:
	var cam_1: Camera3D = get_node_or_null("Camera1")
	if cam_1:
		cam_1.make_current()
	
	for zone in find_children("SwitchC_*", "Area3D", true, false):
		var parts: PackedStringArray = zone.name.split("_")
		if parts.size() != 3 or not parts[1].is_valid_int() or not parts[2].is_valid_int():
			push_warning("Nombre de zona de cámara inválido (usa SwitchC_A_B): " + zone.name)
			continue
		
		var cam_a: Camera3D = get_node_or_null("Camera" + parts[1])
		var cam_b: Camera3D = get_node_or_null("Camera" + parts[2])
		if cam_a == null or cam_b == null:
			push_warning("La zona %s referencia una cámara que no existe" % zone.name)
			continue
		
		var cb = _on_camera_switch_entered.bind(cam_a, cam_b)
		if not zone.body_entered.is_connected(cb):
			zone.body_entered.connect(cb)

# Alterna entre las dos cámaras de la zona (solo reacciona al jugador activo)
func _on_camera_switch_entered(body: Node3D, cam_a: Camera3D, cam_b: Camera3D) -> void:
	if body != get_active_player():
		return
	if cam_a.current:
		cam_b.make_current()
	elif cam_b.current:
		cam_a.make_current()

# Devuelve el nodo del jugador activo (16x16 o 32x32)
func get_active_player() -> CharacterBody3D:
	if player_16 and player_16.visible:
		return player_16
	return player_32

# Alterna entre el personaje de 16x16 y el de 32x32
func toggle_player_character() -> void:
	if player_16.visible:
		cambiar_personaje(player_16, player_32)
	else:
		cambiar_personaje(player_32, player_16)

# Función que apaga al personaje actual y enciende al nuevo
func cambiar_personaje(personaje_viejo: CharacterBody3D, personaje_nuevo: CharacterBody3D) -> void:
	# Teletransporta al nuevo exactamente a donde estaba parado el viejo
	personaje_nuevo.global_position = personaje_viejo.global_position
	
	# Mueve elementos anclados (como la Rata en la cabeza) del viejo al nuevo personaje
	for child in personaje_viejo.get_children():
		if child.name.begins_with("Rat") or child.is_in_group("rat"):
			child.reparent(personaje_nuevo)
			child.position = Vector3(0, 1.2, 0)
	
	# Apaga físicas y visibilidad del viejo
	personaje_viejo.hide()
	personaje_viejo.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Enciende físicas y visibilidad del nuevo
	personaje_nuevo.show()
	personaje_nuevo.process_mode = Node.PROCESS_MODE_INHERIT

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		var active = get_active_player()
		if active and "is_interacting" in active and active.is_interacting:
			return
		if _menu_pausa and not _menu_pausa.visible:
			get_viewport().set_input_as_handled()
			# Sincronizar si lleva la rata
			var tiene_rata: bool = false
			if active:
				for child in active.get_children():
					if child.name.begins_with("Rat") or child.is_in_group("rat"):
						tiene_rata = true
						break
			var gs = _obtener_game_state()
			if gs:
				gs.tiene_rata = tiene_rata
			_menu_pausa.abrir_menu()

func _obtener_game_state():
	var gs_script = load("res://scripts/core/game_state.gd")
	if gs_script and "instancia" in gs_script and gs_script.instancia != null:
		return gs_script.instancia
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var root = get_tree().root if is_inside_tree() else null
	if root and root.has_node("GameState"):
		return root.get_node("GameState")
	return null
