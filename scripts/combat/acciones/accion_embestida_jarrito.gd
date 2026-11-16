extends BattlerAction
## Embestida corta con el comando de esquive compartido y salto del objetivo.

@export_group("Comando de esquive")
@export var mostrar_indicador: bool = true
@export var ventana_antes: float = 0.22
@export var ventana_despues: float = 0.06
@export var sonido_esquive: AudioStream = preload("res://assets/audio/sfx/snd_item.wav")


func ejecutar(origen: Battler, objetivos: Array[Battler], arena: Node) -> void:
	if objetivos.is_empty() or not origen.esta_vivo():
		return
	var victima: Battler = objetivos[0]
	var frente: Vector3 = victima.posicion_frente(origen)
	var direccion: float = signf(frente.x - origen.global_position.x)
	var carga: Vector3 = frente - Vector3(direccion * 0.6, 0, 0)
	await origen.caminar_hasta(carga, 0.35)
	origen.mirar_hacia(victima.global_position.x)
	# Iniciar el salto al acertar, sin esperar a que termine la ventana de impacto.
	var al_resolver: Callable = func(resultado: ComandoAccion.Resultado) -> void:
		if resultado == ComandoAccion.Resultado.EXITO and victima.esta_vivo():
			victima.animar_esquive()
	arena.comando.resuelto.connect(al_resolver, CONNECT_ONE_SHOT)
	origen.reproducir(origen.anim_ataque)
	# Anticipación: cuadros 4-6 (150 + 180 + 180 ms); embestida: 7-8.
	var tween := origen.create_tween()
	tween.tween_interval(0.51)
	tween.tween_property(origen, "global_position", frente, 0.17)
	var pos_indicador: Vector2 = arena.a_pantalla(victima.punto_cabeza() + Vector3.UP * 0.6)
	var resultado: ComandoAccion.Resultado = await arena.comando.ejecutar(
		0.68, ventana_antes, ventana_despues, pos_indicador, mostrar_indicador)
	if arena.comando.resuelto.is_connected(al_resolver):
		arena.comando.resuelto.disconnect(al_resolver)
	if resultado == ComandoAccion.Resultado.EXITO:
		arena.reproducir_sonido(sonido_esquive)
		arena.mostrar_texto(victima, "¡Esquivado!", Color(0.55, 1.0, 0.65))
	elif victima.esta_vivo():
		var danio := calcular_danio(origen, victima, poder)
		victima.recibir_danio(danio)
		arena.mostrar_numero(victima, danio, false)
		arena.reproducir_sonido(origen.sfx_ataque_golpe)
		if victima.esta_vivo():
			victima.animar_herido()
	await origen.esperar_animacion()
	await origen.volver_a_base(0.35)
