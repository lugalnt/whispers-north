extends "res://scripts/world/world_transition.gd"

## Paso entre plantas sin recargar la casa. Conserva la API de WorldTransition.
@export var progreso_requerido: StringName = &""
@export_range(0.1, 3.0) var demora_escalera: float = 0.75
@export var sonido_pasos: AudioStream
var _jugador: CharacterBody3D
var _cortina: CanvasLayer
var _tween: Tween

func _iniciar_transicion(jugador: Node3D) -> void:
	var mundo := get_tree().current_scene
	if mundo == null or jugador != mundo.get_active_player():
		return
	if _transicionando or jugador.is_interacting or get_tree().paused:
		return
	var gs := get_node("/root/GameState")
	if progreso_requerido != &"" and not gs.tiene_progreso(progreso_requerido):
		if mundo.has_method("recordar_diario"):
			mundo.recordar_diario()
		return
	var destino := mundo.find_child(nombre_marcador_destino, true, false) as Node3D
	var camara := mundo.find_child(camara_destino, true, false) as Camera3D
	if destino == null or camara == null:
		push_error("TransicionCasa: marcador o cámara inexistente")
		return
	var coordinador := get_node("/root/CoordinadorEncuentros")
	if not coordinador.bloquear_actividad(self):
		return
	_transicionando = true
	_jugador = jugador as CharacterBody3D
	_jugador.is_interacting = true
	_jugador.velocity = Vector3.ZERO
	transicion_iniciada.emit(escena_destino)
	_cortina = CanvasLayer.new()
	_cortina.layer = 125
	var negro := ColorRect.new()
	negro.color = Color.BLACK
	negro.modulate.a = 0.0
	_cortina.add_child(negro)
	add_child(_cortina)
	negro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tween = create_tween()
	_tween.tween_property(negro, "modulate:a", 1.0, duracion_fundido)
	await _tween.finished
	var audio := AudioStreamPlayer.new()
	audio.stream = sonido_pasos if sonido_pasos else _pasos_provisionales()
	audio.bus = &"SFX"
	_cortina.add_child(audio)
	audio.play()
	_tween = create_tween()
	_tween.tween_interval(demora_escalera)
	await _tween.finished
	if not is_instance_valid(_jugador):
		_limpiar()
		return
	_jugador.global_position = destino.global_position + offset_aparicion
	_jugador.velocity = Vector3.ZERO
	_jugador.reset_physics_interpolation()
	camara.make_current()
	_tween = create_tween()
	_tween.tween_property(negro, "modulate:a", 0.0, duracion_fundido)
	await _tween.finished
	_limpiar()

func _limpiar() -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	if is_instance_valid(_jugador):
		_jugador.is_interacting = false
	_jugador = null
	if is_instance_valid(_cortina):
		_cortina.queue_free()
	_cortina = null
	var coordinador := get_node_or_null("/root/CoordinadorEncuentros")
	if coordinador:
		coordinador.liberar_actividad(self)
	_transicionando = false

func _exit_tree() -> void:
	if not Engine.is_editor_hint():
		_limpiar()

## Foley sintético provisional: tres golpes suaves de madera, sustituible en Inspector.
func _pasos_provisionales() -> AudioStreamWAV:
	var sonido := AudioStreamWAV.new()
	sonido.format = AudioStreamWAV.FORMAT_16_BITS
	sonido.mix_rate = 22050
	var datos := PackedByteArray()
	datos.resize(15435 * 2)
	for i in 15435:
		var t := float(i) / 22050.0
		var local := fmod(t, 0.23)
		var muestra := sin(TAU * 130.0 * local) * exp(-local * 45.0) * 0.28
		datos.encode_s16(i * 2, int(muestra * 32767.0))
	sonido.data = datos
	return sonido
