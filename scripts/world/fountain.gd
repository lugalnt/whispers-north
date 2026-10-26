@tool
class_name Fountain
extends StaticBody3D

## Controlador de la fuente de agua animada (Pokémon B2W2) para Whispers of the North.
## Gestiona la animación de flujo continuo de agua y cascada mediante UV scrolling en AnimationPlayer.

@export_group("Animación de Agua")
## Si es true, el agua fluye continuamente.
@export var animar_agua: bool = true:
	set(val):
		animar_agua = val
		_actualizar_estado_animacion()

## Velocidad de la cascada y corriente de agua (1.0 = normal).
@export_range(0.1, 4.0, 0.1) var velocidad_flujo: float = 1.0:
	set(val):
		velocidad_flujo = val
		if _anim_player:
			_anim_player.speed_scale = velocidad_flujo

@export_group("Audio Ambiental")
## Sonido ambiental continuo de agua fluyendo (opcional).
@export var sonido_agua: AudioStream = null:
	set(val):
		sonido_agua = val
		_actualizar_audio()

## Distancia máxima en metros donde se escucha el agua.
@export_range(5.0, 60.0, 1.0) var distancia_audio: float = 25.0:
	set(val):
		distancia_audio = val
		if _audio_player:
			_audio_player.max_distance = distancia_audio

@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready() -> void:
	_actualizar_estado_animacion()
	_actualizar_audio()

func _actualizar_estado_animacion() -> void:
	if _anim_player == null:
		_anim_player = get_node_or_null("AnimationPlayer")
	if _anim_player == null:
		return
	
	_anim_player.speed_scale = velocidad_flujo
	if animar_agua:
		if not _anim_player.is_playing() or _anim_player.current_animation != "flow":
			_anim_player.play("flow")
	else:
		_anim_player.pause()

func _actualizar_audio() -> void:
	if Engine.is_editor_hint():
		return # No reproducir SFX en el editor para no molestar
	
	if _audio_player == null:
		_audio_player = get_node_or_null("AudioStreamPlayer3D")
	if _audio_player == null:
		return
	
	_audio_player.max_distance = distancia_audio
	if sonido_agua:
		_audio_player.stream = sonido_agua
		if not _audio_player.playing:
			_audio_player.play()
	else:
		_audio_player.stop()
