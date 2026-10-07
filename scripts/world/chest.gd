extends Node3D

# Sonidos requeridos para la interacción con el cofre y la rata
@export var sonido_salida_rata: AudioStream = preload("res://assets/audio/sfx/higuys.mp3")
@export var sonido_desvanecer_inicio: AudioStream = preload("res://assets/audio/sfx/byeguys.mp3")
@export var sonido_desvanecer_scream: AudioStream = preload("res://assets/audio/sfx/scream.mp3")
@export var sonido_cristal_roto: AudioStream = preload("res://assets/audio/sfx/snd_glassbreak.wav")

# Escena de la rata para reinstanciar en el bucle cuando se requiera
@export var escena_rata: PackedScene = preload("res://scenes/world/Rat.tscn")

# Nodos hijos del cofre
@onready var sprite_cerrado: Sprite3D = $StaticBody3D/Closed
@onready var sprite_abierto: Sprite3D = $StaticBody3D/Open
@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioStreamPlayer3D")

# Variables booleanas de estado
var jugador_cerca: bool = false
var esta_abierto: bool = false
var rata_en_cabeza: bool = false
var desvaneciendo: bool = false

# Referencias dinámicas
var jugador_actual: CharacterBody3D = null
var rata_instancia: Node3D = null

func _ready() -> void:
	if audio_player == null and has_node("AudioStreamPlayer3D"):
		audio_player = $AudioStreamPlayer3D
		
	# Buscar si ya existe un nodo Rata hijo inicial
	if has_node("Rat"):
		rata_instancia = $Rat
		rata_instancia.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not jugador_cerca or desvaneciendo:
		return
		
	if Input.is_action_just_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if not esta_abierto and not rata_en_cabeza:
			_fase_1_abrir_y_saltar()
		elif esta_abierto and rata_en_cabeza:
			_fase_2_desvanecer_y_explotar_rata()

# Detecta cuando el jugador entra en el área del cofre
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name.begins_with("Player"):
		jugador_cerca = true
		jugador_actual = body as CharacterBody3D

# Detecta cuando el jugador sale del área del cofre
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D or body.name.begins_with("Player"):
		jugador_cerca = false

# FASE 1: Abrir cofre y salto parabólico de la rata hacia la cabeza del Player
func _fase_1_abrir_y_saltar() -> void:
	if jugador_actual == null:
		# Obtener jugador activo desde la escena principal como fallback
		var world = get_tree().current_scene
		if world and world.has_method("get_active_player"):
			jugador_actual = world.get_active_player()
			
	if jugador_actual == null:
		return
		
	esta_abierto = true
	
	# Cambiar visibilidad de los sprites del cofre
	sprite_cerrado.hide()
	sprite_abierto.show()
	
	# Asegurar que la rata exista (instanciar si fue liberada anteriormente en el bucle)
	if rata_instancia == null or not is_instance_valid(rata_instancia):
		if has_node("Rat"):
			rata_instancia = $Rat
		else:
			rata_instancia = escena_rata.instantiate()
			add_child(rata_instancia)
			
	rata_instancia.add_to_group("rat")
	rata_instancia.scale = Vector3.ONE
	
	# Asegurar que la rata sea visible y su alfa sea 1.0
	var sprite_rata = _obtener_sprite_rata(rata_instancia)
	if sprite_rata:
		sprite_rata.modulate = Color.WHITE
		
	# Posición inicial de la rata (desde el cofre)
	rata_instancia.global_position = global_position + Vector3(0, 0.5, 0)
	rata_instancia.show()
	
	# Reproducir Sonido 1 (Salida de la rata)
	reproducir_sonido(sonido_salida_rata)
	
	# Parámetros del salto parabólico
	var duracion: float = 0.8
	var destino_cabeza: Vector3 = jugador_actual.global_position + Vector3(0, 1.2, 0)
	var pos_inicial: Vector3 = rata_instancia.global_position
	var altura_pico: float = max(pos_inicial.y, destino_cabeza.y) + 1.2
	
	# Tweens en paralelo para simular física y gravedad:
	# 1. Movimiento lineal horizontal en ejes X y Z
	var tween_xz: Tween = create_tween().set_parallel(true)
	tween_xz.tween_property(rata_instancia, "global_position:x", destino_cabeza.x, duracion).set_trans(Tween.TRANS_LINEAR)
	tween_xz.tween_property(rata_instancia, "global_position:z", destino_cabeza.z, duracion).set_trans(Tween.TRANS_LINEAR)
	
	# 2. Movimiento parabólico en eje Y (Subida con EASE_OUT, bajada con EASE_IN)
	var tween_y: Tween = create_tween()
	tween_y.tween_property(rata_instancia, "global_position:y", altura_pico, duracion / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(rata_instancia, "global_position:y", destino_cabeza.y, duracion / 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	await tween_xz.finished
	
	# Al aterrizar, cambiar nodo padre (reparent) al Player para anclarla a su cabeza
	if is_instance_valid(rata_instancia) and is_instance_valid(jugador_actual):
		rata_instancia.reparent(jugador_actual)
		rata_instancia.position = Vector3(0, 1.2, 0) # Offset relativo a la cabeza
		rata_en_cabeza = true

# FASE 2: Secuencia de desvanecimiento, scream, explosión tipo globo/cristal y sonido de cristal roto
func _fase_2_desvanecer_y_explotar_rata() -> void:
	if not is_instance_valid(rata_instancia):
		return
		
	desvaneciendo = true
	
	# 1. Reproducir Sonido 2 (byeguys.mp3 - inicio interacción)
	reproducir_sonido(sonido_desvanecer_inicio)
	
	# 2. Delay de 1 segundo
	await get_tree().create_timer(1.0).timeout
	
	# 3. Reproducir Sonido 3 (scream.mp3)
	reproducir_sonido(sonido_desvanecer_scream)
	
	# Esperar el punto culminante del sonido scream
	await get_tree().create_timer(0.6).timeout
	
	# 4. Reproducir sonido de cristal roto / explosión
	reproducir_sonido(sonido_cristal_roto)
	
	# 5. Efecto de hinchado/globo y destello blanco antes de estallar
	var pos_cabeza: Vector3 = rata_instancia.global_position
	var sprite_rata = _obtener_sprite_rata(rata_instancia)
	
	if is_instance_valid(rata_instancia):
		var tween_pop: Tween = create_tween().set_parallel(true)
		tween_pop.tween_property(rata_instancia, "scale", Vector3(1.7, 1.7, 1.7), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if sprite_rata:
			tween_pop.tween_property(sprite_rata, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.08)
		await tween_pop.finished
		
	# 6. Generar explosión de partículas de cristal en 3D
	_crear_explosion_cristal(pos_cabeza)
	
	# 7. Liberar el nodo de la rata inmediatamente tras la explosión
	if is_instance_valid(rata_instancia):
		rata_instancia.queue_free()
		rata_instancia = null
		
	# 8. Reiniciar estado del cofre para permitir repetir la interacción (bucle)
	esta_abierto = false
	rata_en_cabeza = false
	desvaneciendo = false
	sprite_abierto.hide()
	sprite_cerrado.show()

# Emisor procedural de partículas para simular cristal o globo explotando
func _crear_explosion_cristal(posicion: Vector3) -> void:
	var particulas = CPUParticles3D.new()
	particulas.global_position = posicion
	particulas.amount = 35
	particulas.lifetime = 0.6
	particulas.one_shot = true
	particulas.explosiveness = 1.0
	
	particulas.direction = Vector3(0, 1, 0)
	particulas.spread = 180.0
	particulas.gravity = Vector3(0, -9.8, 0)
	particulas.initial_velocity_min = 3.5
	particulas.initial_velocity_max = 7.5
	
	# Malla de fragmentos de cristal brillantes
	var mesh = QuadMesh.new()
	mesh.size = Vector2(0.12, 0.12)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.95, 1.0, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.7, 0.9, 1.0)
	mat.emission_energy_multiplier = 3.0
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mesh.material = mat
	
	particulas.mesh = mesh
	
	var world = get_tree().current_scene

	if world:
		world.add_child(particulas)
		particulas.emitting = true
		get_tree().create_timer(particulas.lifetime + 0.2).timeout.connect(particulas.queue_free)

# Función para obtener el nodo Sprite3D dentro de la estructura de la rata
func _obtener_sprite_rata(nodo_rata: Node) -> Sprite3D:
	if nodo_rata is Sprite3D:
		return nodo_rata as Sprite3D
	var sprite = nodo_rata.find_child("Sprite3D", true, false)
	if sprite is Sprite3D:
		return sprite as Sprite3D
	return null

# Reproducción de SFX en el AudioStreamPlayer3D
func reproducir_sonido(stream: AudioStream) -> void:
	if audio_player == null:
		audio_player = get_node_or_null("AudioStreamPlayer3D")
	if audio_player and stream:
		audio_player.stream = stream
		audio_player.play()
