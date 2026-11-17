extends "res://scripts/world/zona_mundo.gd"

## Escena de prueba en desuso para encuadre de cámara fija y capas de sprite de árbol.

const TRACK_ENV: AudioStream = preload("res://assets/audio/music/Man_music.ogg")
const SFX_EVENT: AudioStream = preload("res://assets/audio/sfx/snd_item.wav")

@onready var _canopy_b: Sprite3D = get_node_or_null("ArbolTest/CapaFondo") as Sprite3D
@onready var _canopy_f: Sprite3D = get_node_or_null("ArbolTest/CapaFrente") as Sprite3D
@onready var _audio_env: AudioStreamPlayer = get_node_or_null("AudioEnv") as AudioStreamPlayer
@onready var _sfx_prop: AudioStreamPlayer = get_node_or_null("SfxProp") as AudioStreamPlayer
@onready var _salida: WorldTransition = get_node_or_null("Salida") as WorldTransition

var _tiempo_anim: float = 0.0
var _completado_local: bool = false

func _ready() -> void:
	marcador_inicial = "Llegada_Sur"
	super._ready()
	_configurar_salida()
	_orientar_jugador()
	_asegurar_audio_bucle()

func _process(delta: float) -> void:
	_tiempo_anim += delta
	if _canopy_b:
		_canopy_b.position.x = sin(_tiempo_anim * 1.6) * 0.055
	if _canopy_f:
		_canopy_f.position.x = -sin(_tiempo_anim * 1.6 + 0.65) * 0.055

func _configurar_salida() -> void:
	if _salida == null:
		return
	var gs: Node = get_node_or_null("/root/GameState")
	if gs == null:
		return
	if "ruta_retorno_escena" in gs and not gs.ruta_retorno_escena.is_empty():
		_salida.escena_destino = gs.ruta_retorno_escena
	if "ruta_retorno_marcador" in gs and not gs.ruta_retorno_marcador.is_empty():
		_salida.nombre_marcador_destino = gs.ruta_retorno_marcador
	if "ruta_retorno_camara" in gs and not gs.ruta_retorno_camara.is_empty():
		_salida.camara_destino = gs.ruta_retorno_camara

func _orientar_jugador() -> void:
	var jugador: Node3D = get_active_player()
	if jugador == null:
		return
	if "last_input_dir" in jugador:
		jugador.last_input_dir = Vector2(0, -1)
	var spr: AnimatedSprite3D = jugador.get_node_or_null("Sprite2_5D") as AnimatedSprite3D
	if spr and spr.sprite_frames and spr.sprite_frames.has_animation(&"idle_up"):
		spr.play(&"idle_up")

func _asegurar_audio_bucle() -> void:
	if _audio_env == null:
		return
	if _audio_env.stream == null:
		_audio_env.stream = TRACK_ENV
	if _audio_env.stream is AudioStreamOggVorbis:
		(_audio_env.stream as AudioStreamOggVorbis).loop = true
	if not _audio_env.finished.is_connected(_on_audio_terminado):
		_audio_env.finished.connect(_on_audio_terminado)
	if not _audio_env.playing:
		_audio_env.play()

func _on_audio_terminado() -> void:
	if is_instance_valid(_audio_env):
		_audio_env.play()

func estado_aplicado() -> bool:
	var gs: Node = get_node_or_null("/root/GameState")
	if gs and gs.has_method("evento_arbol_completado"):
		return _completado_local or gs.evento_arbol_completado()
	return _completado_local

func aplicar_evento() -> void:
	_completado_local = true
	var gs: Node = get_node_or_null("/root/GameState")
	if gs and gs.has_method("registrar_evento_arbol"):
		gs.registrar_evento_arbol()
	if _sfx_prop:
		if _sfx_prop.stream == null:
			_sfx_prop.stream = SFX_EVENT
		_sfx_prop.play()
