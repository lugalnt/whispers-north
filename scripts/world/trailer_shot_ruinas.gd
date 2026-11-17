extends Node3D

## Escena temporal de tráiler para grabar un plano secuencia cinematográfico en las Ruinas
## sin modificar World_ForestRuins.tscn ni afectar el flujo normal del juego.
## Ejecutar directamente con F6 o con el modo Movie Maker de Godot.

const ESCENA_RUINAS := preload("res://scenes/world/World_ForestRuins.tscn")

@export_group("Plano Secuencia del Tráiler")
@export var iniciar_automaticamente: bool = true
@export var duracion_shot: float = 24.0
@export var espera_antes_de_mover: float = 0.6
@export var pausa_en_plano_final: float = 1.8
@export var fov_camara: float = 52.0
@export var ocultar_jugador: bool = true
@export var fundido_negro_entrada_salida: bool = true
@export var desactivar_y_restaurar_al_terminar: bool = true
@export var cerrar_al_terminar_en_movie: bool = true

var _ruinas: Node3D = null
var _rig: Node3D = null
var _cam_trailer: Camera3D = null
var _cam_previa: Camera3D = null
var _path_cam: Path3D = null
var _follow_cam: PathFollow3D = null
var _path_look: Path3D = null
var _follow_look: PathFollow3D = null
var _cortina_rect: ColorRect = null
var _canvas_cortina: CanvasLayer = null

var _progreso_t: float = 0.0
var _shot_activo: bool = false
var _estado_ocultos: Dictionary = {}

# Puntos de vuelo de la cámara (posición 3D sobre el mapa de las Ruinas).
var _puntos_camara: PackedVector3Array = PackedVector3Array([
	Vector3(16.0, 8.6, 70.0),   # 0. Entrada oeste y sendero sur despejado
	Vector3(41.0, 9.5, 69.0),   # 1. Tramo sur mirando hacia el claro sureste
	Vector3(64.5, 9.2, 68.5),   # 2. Claro sureste (ruina + cofre + jarrito)
	Vector3(44.5, 10.5, 53.5),  # 3. Ruina este y cruce central
	Vector3(31.5, 11.2, 43.5),  # 4. Hacia la ruina oeste y sendero norte
	Vector3(23.5, 10.2, 23.0),  # 5. Ruinas del noroeste y cofre
	Vector3(49.5, 8.5, 25.5),   # 6. Puente norte despejado hacia el Gran Santuario
	Vector3(69.0, 5.4, 21.8),   # 7. Plano bajo frente al Mandoble de las Ruinas
	Vector3(88.8, 5.2, 24.2),   # 8. Plano heroico final del Coloso Carmesí dentro del claro
])

# Puntos hacia donde apunta suavemente la cámara en cada tramo.
var _puntos_mira: PackedVector3Array = PackedVector3Array([
	Vector3(28.0, 1.4, 61.0),   # 0. Sendero inicial
	Vector3(55.0, 1.5, 60.5),   # 1. Camino hacia el claro SE
	Vector3(69.5, 1.5, 59.5),   # 2. Claro SE y cofre
	Vector3(49.5, 1.5, 46.5),   # 3. Claro este y estelas
	Vector3(25.5, 1.5, 39.5),   # 4. Ruina oeste
	Vector3(16.5, 1.5, 13.0),   # 5. Triple cámara NO
	Vector3(66.0, 1.8, 22.5),   # 6. Arco del Gran Santuario al fondo
	Vector3(69.0, 2.2, 12.6),   # 7. Altar del Mandoble
	Vector3(88.8, 2.1, 16.5),   # 8. Coloso de las Ruinas y monolitos
])

func _ready() -> void:
	_ruinas = ESCENA_RUINAS.instantiate() as Node3D
	_ruinas.name = "WorldForestRuins"
	add_child(_ruinas)
	_construir_rig_y_rutas()
	if iniciar_automaticamente:
		# Esperar un par de cuadros a que ZonaMundo termine su arranque inicial.
		call_deferred("_arrancar_cuando_este_listo")

func _arrancar_cuando_este_listo() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	iniciar_shot()

func _construir_rig_y_rutas() -> void:
	_rig = Node3D.new()
	_rig.name = "TrailerRig"
	add_child(_rig)

	_path_cam = _crear_path("TrailerPathCam", _puntos_camara, true)
	_rig.add_child(_path_cam)
	_follow_cam = PathFollow3D.new()
	_follow_cam.name = "FollowCam"
	_follow_cam.loop = false
	_path_cam.add_child(_follow_cam)

	_cam_trailer = Camera3D.new()
	_cam_trailer.name = "TrailerCam"
	_cam_trailer.fov = fov_camara
	_cam_trailer.near = 0.2
	_cam_trailer.far = 250.0
	_follow_cam.add_child(_cam_trailer)

	_path_look = _crear_path("TrailerPathLook", _puntos_mira, true)
	_rig.add_child(_path_look)
	_follow_look = PathFollow3D.new()
	_follow_look.name = "FollowLook"
	_follow_look.loop = false
	_path_look.add_child(_follow_look)

	_canvas_cortina = CanvasLayer.new()
	_canvas_cortina.layer = 120
	_cortina_rect = ColorRect.new()
	_cortina_rect.color = Color(0, 0, 0, 0)
	_cortina_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas_cortina.add_child(_cortina_rect)
	add_child(_canvas_cortina)

func _crear_path(nombre: String, puntos: PackedVector3Array, suavizado: bool) -> Path3D:
	var p := Path3D.new()
	p.name = nombre
	var curve := Curve3D.new()
	var n := puntos.size()
	for i in n:
		var pt := puntos[i]
		var tang_in := Vector3.ZERO
		var tang_out := Vector3.ZERO
		if suavizado and n >= 2:
			var prev := puntos[maxi(0, i - 1)]
			var nxt := puntos[mini(n - 1, i + 1)]
			var tang := (nxt - prev) * 0.22
			tang_in = -tang
			tang_out = tang
		curve.add_point(pt, tang_in, tang_out)
	p.curve = curve
	return p

## Activa el shot: desactiva temporalmente jugador/UI/triggers y corre la trayectoria.
func iniciar_shot() -> void:
	if _shot_activo or _ruinas == null:
		return
	_shot_activo = true
	_preparar_escena_para_grabacion()

	_cam_previa = get_viewport().get_camera_3d()
	_cam_trailer.fov = fov_camara
	_cam_trailer.make_current()
	aplicar_tiempo_normalizado(0.0)

	if fundido_negro_entrada_salida:
		_cortina_rect.color.a = 1.0
		var tw_in := create_tween()
		tw_in.tween_property(_cortina_rect, "color:a", 0.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tw_in.finished
	if espera_antes_de_mover > 0.0:
		await get_tree().create_timer(espera_antes_de_mover).timeout

	var tw_shot := create_tween()
	tw_shot.tween_method(aplicar_tiempo_normalizado, 0.0, 1.0, maxf(1.0, duracion_shot))\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	await tw_shot.finished

	if pausa_en_plano_final > 0.0:
		await get_tree().create_timer(pausa_en_plano_final).timeout

	if fundido_negro_entrada_salida:
		var tw_out := create_tween()
		tw_out.tween_property(_cortina_rect, "color:a", 1.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tw_out.finished

	finalizar_shot()

## Posiciona y orienta la cámara del tráiler en un progreso t entre 0.0 y 1.0.
func aplicar_tiempo_normalizado(t: float) -> void:
	_progreso_t = clampf(t, 0.0, 1.0)
	if _follow_cam == null or _follow_look == null or _cam_trailer == null:
		return
	_follow_cam.progress_ratio = _progreso_t
	_follow_look.progress_ratio = _progreso_t
	var mira := _follow_look.global_position
	if _cam_trailer.global_position.distance_squared_to(mira) > 0.01:
		_cam_trailer.look_at(mira, Vector3.UP)

## Desactiva el rig de tráiler y deja todo restaurado o cierra en modo Movie Maker.
func finalizar_shot() -> void:
	_shot_activo = false
	if cerrar_al_terminar_en_movie and OS.has_feature("movie"):
		get_tree().quit()
		return
	if desactivar_y_restaurar_al_terminar:
		_restaurar_escena()
		if _cam_previa != null and is_instance_valid(_cam_previa):
			_cam_previa.make_current()
		if _cortina_rect:
			var tw_clear := create_tween()
			tw_clear.tween_property(_cortina_rect, "color:a", 0.0, 0.5)

func _preparar_escena_para_grabacion() -> void:
	_estado_ocultos.clear()
	var jugador: CharacterBody3D = _ruinas.call("get_active_player") as CharacterBody3D if _ruinas.has_method("get_active_player") else null
	if jugador:
		_estado_ocultos["player_vis"] = jugador.visible
		_estado_ocultos["player_phys"] = jugador.is_physics_processing()
		_estado_ocultos["player_layer"] = jugador.collision_layer
		jugador.set_physics_process(false)
		jugador.collision_layer = 0
		if "is_interacting" in jugador:
			jugador.is_interacting = true
		if ocultar_jugador:
			jugador.visible = false

	var pause_menu: Node = _ruinas.get_node_or_null("PauseMenu")
	if pause_menu:
		_estado_ocultos["pause_proc"] = pause_menu.process_mode
		pause_menu.process_mode = Node.PROCESS_MODE_DISABLED
		if "visible" in pause_menu:
			pause_menu.visible = false

	# Ocultar avisos flotantes [E] y evitar triggers durante el vuelo de cámara
	for inter in _ruinas.find_children("*", "Area3D", true, false):
		var a := inter as Area3D
		if a == null:
			continue
		if a is WorldTransition or a.name == "TriggerCinematicaJefe" or "mostrar_indicador" in a:
			_estado_ocultos[a.get_instance_id()] = a.monitoring
			a.monitoring = false
			if "mostrar_indicador" in a:
				a.mostrar_indicador = false

	# Quitar cualquier cortina negra sobrante de WorldPresentation / ZonaMundo
	for child in _ruinas.get_children():
		if child is CanvasLayer and (child.name == "FadeInCanvas" or child.name.begins_with("Transition")):
			child.queue_free()

func _restaurar_escena() -> void:
	var jugador: CharacterBody3D = _ruinas.call("get_active_player") as CharacterBody3D if _ruinas.has_method("get_active_player") else null
	if jugador:
		jugador.visible = bool(_estado_ocultos.get("player_vis", true))
		jugador.set_physics_process(bool(_estado_ocultos.get("player_phys", true)))
		jugador.collision_layer = int(_estado_ocultos.get("player_layer", 1))
		if "is_interacting" in jugador:
			jugador.is_interacting = false

	var pause_menu: Node = _ruinas.get_node_or_null("PauseMenu")
	if pause_menu and _estado_ocultos.has("pause_proc"):
		pause_menu.process_mode = _estado_ocultos["pause_proc"]

	for inter in _ruinas.find_children("*", "Area3D", true, false):
		var a := inter as Area3D
		if a and _estado_ocultos.has(a.get_instance_id()):
			a.monitoring = bool(_estado_ocultos[a.get_instance_id()])
