extends CSGBox3D

# Sonidos de la puerta
@export var sonido_abrir: AudioStream = preload("res://assets/audio/sfx/snd_dooropen.wav")
@export var sonido_cerrar: AudioStream = preload("res://assets/audio/sfx/snd_doorclose.wav")

# Texturas de la puerta (cerrada y abierta)
@export var textura_cerrada: Texture2D = preload("res://assets/sprites/environment/puerta.png")
@export var textura_abierta: Texture2D = preload("res://assets/sprites/environment/puerta_abierta.png")

# Referencias a nodos
@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioStreamPlayer3D")

# Variables de estado de interacción
var jugador_cerca: bool = false
var jugador_actual: CharacterBody3D = null
var esta_animando: bool = false

func _ready() -> void:
	if audio_player == null and has_node("AudioStreamPlayer3D"):
		audio_player = $AudioStreamPlayer3D
	_cambiar_textura_puerta(textura_cerrada)

func _unhandled_input(event: InputEvent) -> void:
	if jugador_cerca and not esta_animando and Input.is_action_just_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		interactuar_puerta()

# Detecta cuando el jugador entra en el área de la puerta
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D or body.name.begins_with("Player"):
		jugador_cerca = true
		jugador_actual = body as CharacterBody3D

# Detecta cuando el jugador sale del área de la puerta
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == jugador_actual:
		jugador_cerca = false
		if not esta_animando:
			jugador_actual = null

# Lógica de cambio de textura entre puerta abierta y cerrada
func interactuar_puerta() -> void:
	if esta_animando or jugador_actual == null:
		return
		
	esta_animando = true
	
	# 1. Reproducir sonido de apertura
	reproducir_sonido(sonido_abrir)
	
	# 2. Cambiar textura a puerta abierta
	_cambiar_textura_puerta(textura_abierta)
	
	# 3. Animar desvanecimiento del jugador al entrar
	var sprite_jugador = jugador_actual.get_node_or_null("Sprite2_5D")
	if sprite_jugador:
		var tween_fade_out = create_tween()
		tween_fade_out.tween_property(sprite_jugador, "modulate:a", 0.0, 0.4)
		await tween_fade_out.finished
	else:
		await get_tree().create_timer(0.4).timeout
		
	# 4. Cambiar versión del personaje (16x16 <-> 32x32)
	if is_instance_valid(jugador_actual) and jugador_actual.has_method("toggle_sprite_size"):
		jugador_actual.toggle_sprite_size()
		
	# Obtener el nuevo personaje activo
	var world = get_tree().current_scene
	if world and world.has_method("get_active_player"):
		jugador_actual = world.get_active_player()
		
	var nuevo_sprite = jugador_actual.get_node_or_null("Sprite2_5D") if jugador_actual else null
	if nuevo_sprite:
		nuevo_sprite.modulate.a = 0.0
		
	# Breve pausa dentro de la casa
	await get_tree().create_timer(0.3).timeout
	
	# 5. Reproducir sonido de cierre
	reproducir_sonido(sonido_cerrar)
	
	# 6. Cambiar textura de regreso a puerta cerrada
	_cambiar_textura_puerta(textura_cerrada)
	
	# 7. Animar reaparición del nuevo personaje
	if nuevo_sprite:
		var tween_fade_in = create_tween()
		tween_fade_in.tween_property(nuevo_sprite, "modulate:a", 1.0, 0.4)
		await tween_fade_in.finished
		
	esta_animando = false

# Cambia dinámicamente la textura del material de la puerta
func _cambiar_textura_puerta(tex: Texture2D) -> void:
	if material is StandardMaterial3D:
		(material as StandardMaterial3D).albedo_texture = tex

# Reproducción de SFX en el AudioStreamPlayer3D
func reproducir_sonido(stream: AudioStream) -> void:
	if audio_player == null:
		audio_player = get_node_or_null("AudioStreamPlayer3D")
	if audio_player and stream:
		audio_player.stream = stream
		audio_player.play()
