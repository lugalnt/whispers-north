class_name ZonaMundo
extends Node3D

## Controlador común de las zonas del recorrido (Casa, Pueblo, Cueva, Bosque y ruinas).
##
## Reúne la integración que antes vivía solo en world_town.gd:
##   - Instancia el menú de pausa y lo abre con la acción `pause`.
##   - Recibe las transiciones de WorldTransition: coloca al jugador en el marcador
##     de destino, activa la cámara indicada, restaura la rata y hace el fundido.
##   - Arranque sin transición (Nueva partida o F6): usa marcador/cámara iniciales.
## La vecindad (World.tscn) mantiene su script propio (world.gd) por su sistema
## antiguo de cámaras SwitchC_* y sus dos variantes de personaje.

@export var escena_menu_pausa: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")
@export var escena_rata: PackedScene = preload("res://scenes/world/Entities/Rat.tscn")
## Nombre del nodo jugador de la zona.
@export var nombre_nodo_jugador: String = "Player32"

@export_group("Arranque sin transición")
## Marcador (Node3D) donde colocar al jugador si la escena se carga sin transición
## pendiente (Nueva partida, F6). Vacío = conservar la posición guardada en la escena.
@export var marcador_inicial: String = ""
## Cámara que se activa si la escena se carga sin transición pendiente. Vacío = la de la escena.
@export var camara_inicial: String = ""

@export_group("Fundido de entrada")
@export var duracion_fundido_entrada: float = 0.45

var player_32: CharacterBody3D = null
var _menu_pausa: PauseMenu = null

func _ready() -> void:
	add_child(preload("res://scripts/world/world_presentation.gd").new())
	player_32 = get_node_or_null(nombre_nodo_jugador) as CharacterBody3D
	if escena_menu_pausa:
		_menu_pausa = escena_menu_pausa.instantiate() as PauseMenu
		_menu_pausa.name = "PauseMenu"
		add_child(_menu_pausa)

	var gs = _obtener_game_state()
	if gs != null:
		gs.zona_actual = scene_file_path
	if gs != null and gs.hay_transicion_pendiente():
		_procesar_transicion_entrada()
	else:
		_aplicar_arranque_sin_transicion()

## Devuelve el jugador activo de la zona
func get_active_player() -> CharacterBody3D:
	if player_32 == null or not is_instance_valid(player_32):
		player_32 = find_child(nombre_nodo_jugador, true, false) as CharacterBody3D
	return player_32

func _aplicar_arranque_sin_transicion() -> void:
	var active := get_active_player()
	if not marcador_inicial.is_empty() and active != null:
		var marcador := find_child(marcador_inicial, true, false) as Node3D
		if marcador != null:
			_colocar_jugador(active, marcador.global_position)
		else:
			push_warning("ZonaMundo: no existe el marcador inicial '%s'" % marcador_inicial)
	if not camara_inicial.is_empty():
		_activar_camara(camara_inicial)
	elif get_viewport() and get_viewport().get_camera_3d() == null:
		var cam_defecto: Camera3D = find_child("Camera1", true, false) as Camera3D
		if cam_defecto:
			cam_defecto.make_current()

func _procesar_transicion_entrada() -> void:
	var gs = _obtener_game_state()
	var active := get_active_player()
	var marcador_nombre: String = gs.spawn_nombre_marcador

	# 1. Colocar al jugador en el punto de entrada
	var pos_destino: Vector3 = gs.consumir_posicion_spawn(self)
	if active != null:
		if find_child(marcador_nombre, true, false) != null:
			_colocar_jugador(active, pos_destino)
		else:
			push_warning("ZonaMundo: marcador de llegada '%s' inexistente; se usa el inicial" % marcador_nombre)
			_aplicar_arranque_sin_transicion()

	# 2. Activar la cámara de entrada indicada
	_activar_camara(gs.consumir_camara_spawn())

	# 3. Restaurar acompañante (Rata) si corresponde
	if gs.tiene_rata and active != null:
		_asegurar_rata(active)

	# 4. Suave cortina de entrada (fade in desde negro)
	_animar_fade_in(active)

func _colocar_jugador(jugador: CharacterBody3D, posicion: Vector3) -> void:
	if jugador.is_inside_tree():
		jugador.global_position = posicion
	else:
		jugador.position = posicion
	jugador.velocity = Vector3.ZERO
	jugador.reset_physics_interpolation()

func _activar_camara(cam_nombre: String) -> void:
	if cam_nombre.is_empty():
		return
	var cam: Camera3D = find_child(cam_nombre, true, false) as Camera3D
	if cam:
		cam.make_current()
	else:
		push_warning("ZonaMundo: cámara '%s' inexistente en %s" % [cam_nombre, name])

func _asegurar_rata(jugador: CharacterBody3D) -> void:
	if _tiene_rata(jugador):
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
	tw.tween_property(rect, "modulate:a", 0.0, duracion_fundido_entrada)
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
	# Autoload GameState (acceso por nodo para compatibilidad con scripts headless)
	var ml := Engine.get_main_loop() as SceneTree
	return ml.root.get_node_or_null("GameState") if ml else null

