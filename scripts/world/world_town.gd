extends Node3D

## Script controlador para World_Town.
## Gestiona el menú de pausa, la recepción de transiciones de escena desde World,
## y la persistencia de acompañantes y jugador.

@onready var player_32: CharacterBody3D = get_node_or_null("Player32") as CharacterBody3D
@export var escena_menu_pausa: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")
@export var escena_rata: PackedScene = preload("res://scenes/world/Entities/Rat.tscn")

var _menu_pausa: PauseMenu = null

func _ready() -> void:
	if escena_menu_pausa:
		_menu_pausa = escena_menu_pausa.instantiate() as PauseMenu
		_menu_pausa.name = "PauseMenu"
		add_child(_menu_pausa)
	
	_procesar_transicion_entrada()

## Devuelve el jugador activo de la ciudad
func get_active_player() -> CharacterBody3D:
	if player_32 == null:
		player_32 = find_child("Player32", true, false) as CharacterBody3D
	return player_32

func _procesar_transicion_entrada() -> void:
	var gs = _obtener_game_state()
	if gs == null or not gs.hay_transicion_pendiente():
		return
	
	var active = get_active_player()
	
	# 1. Colocar al jugador en el punto de entrada
	var pos_destino: Vector3 = gs.consumir_posicion_spawn(self)
	if pos_destino != Vector3.ZERO and active != null:
		if active.is_inside_tree():
			active.global_position = pos_destino
		else:
			active.position = pos_destino
		active.reset_physics_interpolation()
	
	# 2. Activar la cámara de entrada indicada
	var cam_nombre: String = gs.consumir_camara_spawn()
	if not cam_nombre.is_empty():
		var cam: Camera3D = find_child(cam_nombre, true, false) as Camera3D
		if cam:
			cam.make_current()
	
	# 3. Restaurar acompañante (Rata) si corresponde
	if gs.tiene_rata and active != null:
		_asegurar_rata(active)
	
	# 4. Suave cortina de entrada (fade in desde negro)
	_animar_fade_in(active)

func _asegurar_rata(jugador: CharacterBody3D) -> void:
	for c in jugador.get_children():
		if c.name.begins_with("Rat") or c.is_in_group("rat"):
			return
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		var active = get_active_player()
		if active and "is_interacting" in active and active.is_interacting:
			return
		if _menu_pausa and not _menu_pausa.visible:
			get_viewport().set_input_as_handled()
			var gs = _obtener_game_state()
			if gs:
				gs.tiene_rata = _tiene_rata(active)
			_menu_pausa.abrir_menu()

func _tiene_rata(jugador: Node) -> bool:
	if jugador:
		for child in jugador.get_children():
			if child.name.begins_with("Rat") or child.is_in_group("rat"):
				return true
	return false

func _obtener_game_state():
	var gs_script = load("res://scripts/core/game_state.gd")
	if gs_script and "instancia" in gs_script and gs_script.instancia != null:
		return gs_script.instancia
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var root_node: Node = null
	if is_inside_tree() and get_tree():
		root_node = get_tree().root
	elif Engine.get_main_loop() and "root" in Engine.get_main_loop():
		root_node = Engine.get_main_loop().root
	if root_node and root_node.has_node("GameState"):
		return root_node.get_node("GameState")
	var p = get_parent()
	while p != null:
		if p.has_node("GameState"):
			return p.get_node("GameState")
		if p.get_parent() == null:
			if p.name == "GameState":
				return p
			break
		p = p.get_parent()
	return null
