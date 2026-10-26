@tool
class_name WorldTransition
extends Area3D

## Zona de transición entre mapas/mundos (ej: World <-> World_Town).
## Detecta al jugador, ejecuta una transición cinematográfica con fundido
## y sonido de ambiente, y transporta a Eric al marcador de destino.

signal transicion_iniciada(escena_destino: String)

@export_group("Destino")
## Ruta del archivo de escena (.tscn) al que viajará el jugador
@export_file("*.tscn") var escena_destino: String = ""
## Nombre del nodo marcador en la escena de destino (ej: "Marker_Exit_World")
@export var nombre_marcador_destino: String = "Marker_Exit_World"
## Nombre de la cámara que debe activarse al llegar (ej: "Camera1", "Camera6")
@export var camara_destino: String = "Camera1"
## Desplazamiento respecto al marcador donde aparecerá el jugador (para no quedar dentro del trigger)
@export var offset_aparicion: Vector3 = Vector3.ZERO

@export_group("Volumen y Colisión")
## Tamaño de la caja de detección en metros (X, Y, Z)
@export var tamano_zona: Vector3 = Vector3(4.0, 3.0, 2.0):
	set(val):
		tamano_zona = val
		_actualizar_forma_colision()

@export_group("Efectos Visuales y Sonoros")
## Si es true, genera una suave brisa de partículas atmosféricas en el sendero
@export var mostrar_particulas_viento: bool = true:
	set(val):
		mostrar_particulas_viento = val
		_actualizar_particulas()

## Duración en segundos del fundido a negro al cruzar la salida
@export var duracion_fundido: float = 0.45
## Color de la cortina de transición
@export var color_fundido: Color = Color.BLACK
## Sonido ambiental al cruzar la transición de camino
@export var sonido_transicion: AudioStream = preload("res://assets/audio/sfx/snd_doorclose.wav")

var _transicionando: bool = false
var _shape_colision: CollisionShape3D = null
var _particulas: CPUParticles3D = null
var _etiqueta_editor: Label3D = null

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Capa del jugador
	
	_asegurar_colision()
	_asegurar_particulas()
	_actualizar_etiqueta_editor()
	
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _asegurar_colision() -> void:
	_shape_colision = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if _shape_colision == null:
		_shape_colision = CollisionShape3D.new()
		_shape_colision.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = tamano_zona
		_shape_colision.shape = box
		add_child(_shape_colision)
	elif _shape_colision.shape == null or not (_shape_colision.shape is BoxShape3D):
		var box := BoxShape3D.new()
		box.size = tamano_zona
		_shape_colision.shape = box
	else:
		(_shape_colision.shape as BoxShape3D).size = tamano_zona

func _actualizar_forma_colision() -> void:
	if _shape_colision and _shape_colision.shape is BoxShape3D:
		(_shape_colision.shape as BoxShape3D).size = tamano_zona

func _asegurar_particulas() -> void:
	_particulas = get_node_or_null("WindParticles") as CPUParticles3D
	if _particulas == null and mostrar_particulas_viento:
		_particulas = CPUParticles3D.new()
		_particulas.name = "WindParticles"
		_particulas.amount = 28
		_particulas.lifetime = 2.0
		_particulas.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		_particulas.emission_box_extents = Vector3(tamano_zona.x * 0.45, 0.6, tamano_zona.z * 0.45)
		_particulas.gravity = Vector3(0.0, -0.3, 0.0)
		_particulas.direction = Vector3(0.0, 0.1, 1.0)
		_particulas.spread = 45.0
		_particulas.initial_velocity_min = 1.0
		_particulas.initial_velocity_max = 2.5
		_particulas.color = Color(0.95, 0.98, 1.0, 0.45)
		
		# Malla simple de mota de polvo/nieve
		var quad := QuadMesh.new()
		quad.size = Vector2(0.12, 0.12)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		quad.material = mat
		_particulas.mesh = quad
		
		add_child(_particulas)
		_particulas.position = Vector3(0, 0.5, 0)
	elif _particulas:
		_particulas.visible = mostrar_particulas_viento

func _actualizar_particulas() -> void:
	if _particulas:
		_particulas.visible = mostrar_particulas_viento
		_particulas.emission_box_extents = Vector3(tamano_zona.x * 0.45, 0.6, tamano_zona.z * 0.45)

func _actualizar_etiqueta_editor() -> void:
	if Engine.is_editor_hint():
		if _etiqueta_editor == null:
			_etiqueta_editor = get_node_or_null("EditorLabel") as Label3D
		if _etiqueta_editor == null:
			_etiqueta_editor = Label3D.new()
			_etiqueta_editor.name = "EditorLabel"
			_etiqueta_editor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			_etiqueta_editor.no_depth_test = true
			_etiqueta_editor.font_size = 28
			_etiqueta_editor.modulate = Color(0.3, 0.9, 1.0, 0.9)
			_etiqueta_editor.outline_modulate = Color.BLACK
			_etiqueta_editor.outline_size = 6
			add_child(_etiqueta_editor)
		
		var nom_dest = escena_destino.get_file().get_basename() if not escena_destino.is_empty() else "(Sin destino)"
		_etiqueta_editor.text = "🚪 Sendero hacia: %s\nCam: %s" % [nom_dest, camara_destino if not camara_destino.is_empty() else "Auto"]
		_etiqueta_editor.position = Vector3(0, tamano_zona.y * 0.5 + 0.6, 0)
		_etiqueta_editor.visible = true
	else:
		var lbl = get_node_or_null("EditorLabel")
		if lbl:
			lbl.queue_free()

func _on_body_entered(body: Node3D) -> void:
	if _transicionando or escena_destino.is_empty():
		return
	
	# Verificar si el cuerpo es el jugador
	var es_jugador: bool = false
	if body.is_in_group("player") or body.name.begins_with("Player"):
		es_jugador = true
	elif body is CharacterBody3D:
		var mundo = get_tree().current_scene
		if mundo and mundo.has_method("get_active_player") and mundo.get_active_player() == body:
			es_jugador = true
	
	if not es_jugador:
		return
	
	_iniciar_transicion(body)

func _iniciar_transicion(jugador: Node3D) -> void:
	_transicionando = true
	transicion_iniciada.emit(escena_destino)
	print("[WorldTransition] Cruzando hacia: %s (Marcador: %s)" % [escena_destino, nombre_marcador_destino])
	
	# 1. Bloquear movimiento del personaje durante el cambio de escena
	if jugador is CharacterBody3D:
		var cb := jugador as CharacterBody3D
		cb.velocity = Vector3.ZERO
		if "is_interacting" in cb:
			cb.is_interacting = true
	
	# 2. Reproducir sonido de transición
	if sonido_transicion:
		var sfx := AudioStreamPlayer.new()
		sfx.stream = sonido_transicion
		sfx.bus = &"SFX"
		if get_tree().root:
			get_tree().root.add_child(sfx)
			sfx.play()
			sfx.finished.connect(sfx.queue_free)
	
	# 3. Guardar datos de aparición y estado en GameState
	var gs = _obtener_game_state()
	if gs:
		gs.preparar_transicion(nombre_marcador_destino, offset_aparicion, camara_destino)
		gs.tiene_rata = _jugador_tiene_rata(jugador)
		gs.usar_personaje_32 = jugador.name.begins_with("Player32")
	
	# 4. Cortina cinematográfica de salida (Fade out a negro)
	var canvas := CanvasLayer.new()
	canvas.name = "TransitionCanvas"
	canvas.layer = 125
	var rect := ColorRect.new()
	rect.color = color_fundido
	rect.modulate.a = 0.0
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	get_tree().root.add_child(canvas)
	
	var tw = create_tween()
	tw.tween_property(rect, "modulate:a", 1.0, duracion_fundido).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	
	# 5. Cambiar a la escena de destino
	get_tree().change_scene_to_file(escena_destino)
	
	# La cortina se desvanece suavemente una vez que la nueva escena cargue
	var tw_out = canvas.create_tween()
	tw_out.tween_interval(0.1)
	tw_out.tween_property(rect, "modulate:a", 0.0, duracion_fundido).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_out.finished
	canvas.queue_free()

func _jugador_tiene_rata(jugador: Node3D) -> bool:
	if jugador == null:
		return false
	for c in jugador.get_children():
		if c.name.begins_with("Rat") or c.is_in_group("rat"):
			return true
	return false

func _obtener_game_state():
	var gs_script = load("res://scripts/core/game_state.gd")
	if gs_script and "instancia" in gs_script and gs_script.instancia != null:
		return gs_script.instancia
	if is_inside_tree() and get_tree() and get_tree().root.has_node("GameState"):
		return get_tree().root.get_node("GameState")
	return null
