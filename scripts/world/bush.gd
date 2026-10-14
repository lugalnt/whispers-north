extends Node3D

# Arbusto que teletransporta al jugador hacia otro arbusto (destino).
# Uso: en la instancia "Bush2" asigna `destino` = Bush1 (el arbusto de llegada).
# En la instancia "Bush1" desactiva `interactuable` (solo sirve como punto de llegada).

# Si es false, este arbusto no reacciona a la interacción (solo es destino)
@export var interactuable: bool = true
# Arbusto hacia donde se teletransporta al jugador
@export var destino: Node3D
# Posición de aparición relativa al destino (por defecto: a la izquierda, eje -X del mundo)
@export var offset_destino: Vector3 = Vector3(-1.8, 0.0, 0.0)

# Cámara que se activa al llegar. Si se deja vacía y `cambiar_a_camara_cercana`
# está activo, se elige automáticamente la cámara más cercana al punto de llegada.
@export var camara_destino: Camera3D
@export var cambiar_a_camara_cercana: bool = true

# Duración del desvanecimiento / reaparición (igual que la puerta)
@export var duracion_fade: float = 0.4
@export var pausa_entre_fades: float = 0.3

# Sonidos (reutiliza los de la puerta)
@export var sonido_entrar: AudioStream = preload("res://assets/audio/sfx/snd_dooropen.wav")
@export var sonido_salir: AudioStream = preload("res://assets/audio/sfx/snd_doorclose.wav")

@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioStreamPlayer3D")

var jugador_cerca: bool = false
var jugador_actual: CharacterBody3D = null
var esta_animando: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if not interactuable or not jugador_cerca or esta_animando:
		return
	if event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_teletransportar_jugador()

# Detecta cuando el jugador entra en el área del arbusto
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name.begins_with("Player"):
		jugador_cerca = true
		jugador_actual = body as CharacterBody3D

# Detecta cuando el jugador sale del área del arbusto
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == jugador_actual:
		jugador_cerca = false
		if not esta_animando:
			jugador_actual = null

# Desvanece al jugador, lo mueve junto al destino y lo hace reaparecer
func _teletransportar_jugador() -> void:
	if destino == null:
		push_warning("Bush '%s' no tiene destino asignado." % name)
		return
	if jugador_actual == null:
		return

	esta_animando = true
	var jugador := jugador_actual

	# Animación de interacción del jugador (solo si su modelo la tiene)
	if jugador.has_method("play_interact"):
		await jugador.play_interact(global_position)
		if not is_instance_valid(jugador):
			esta_animando = false
			return

	# Bloquear el movimiento durante el efecto
	var estaba_bloqueado: bool = jugador.get("is_interacting") == true
	if "is_interacting" in jugador:
		jugador.is_interacting = true

	reproducir_sonido(sonido_entrar)

	# 1. Desvanecer al jugador (solo el efecto, sin cambiar de modelo)
	var sprite := jugador.get_node_or_null("Sprite2_5D")
	if sprite:
		var tween_out := create_tween()
		tween_out.tween_property(sprite, "modulate:a", 0.0, duracion_fade)
		await tween_out.finished
	else:
		await get_tree().create_timer(duracion_fade).timeout

	# 2. Teletransportar a la izquierda del arbusto destino
	if is_instance_valid(jugador):
		jugador.global_position = destino.global_position + offset_destino
		jugador.velocity = Vector3.ZERO
		jugador.reset_physics_interpolation()
		_cambiar_camara(jugador.global_position)

	jugador_cerca = false
	jugador_actual = null

	await get_tree().create_timer(pausa_entre_fades).timeout

	# 3. Reaparecer
	if is_instance_valid(destino) and destino.has_method("reproducir_sonido"):
		destino.reproducir_sonido(sonido_salir)

	if sprite:
		var tween_in := create_tween()
		tween_in.tween_property(sprite, "modulate:a", 1.0, duracion_fade)
		await tween_in.finished

	if is_instance_valid(jugador) and "is_interacting" in jugador:
		jugador.is_interacting = estaba_bloqueado

	esta_animando = false

# Activa la cámara seleccionada o, en su defecto, la más cercana a la posición dada
func _cambiar_camara(posicion: Vector3) -> void:
	if camara_destino != null:
		camara_destino.make_current()
		return
	if not cambiar_a_camara_cercana:
		return

	var escena := get_tree().current_scene
	if escena == null:
		return

	var mas_cercana: Camera3D = null
	var menor_distancia := INF
	for nodo in escena.find_children("*", "Camera3D", true, false):
		var cam := nodo as Camera3D
		var distancia := cam.global_position.distance_squared_to(posicion)
		if distancia < menor_distancia:
			menor_distancia = distancia
			mas_cercana = cam

	if mas_cercana != null and not mas_cercana.current:
		mas_cercana.make_current()

# Reproducción de SFX en el AudioStreamPlayer3D
func reproducir_sonido(stream: AudioStream) -> void:
	if audio_player == null:
		audio_player = get_node_or_null("AudioStreamPlayer3D")
	if audio_player and stream:
		audio_player.stream = stream
		audio_player.play()
