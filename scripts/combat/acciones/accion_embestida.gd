class_name AccionEmbestida
extends BattlerAction

## Ataque enemigo: se acerca a saltitos, se carga y embiste en arco.
## El objetivo puede ESQUIVAR pulsando `interact` justo antes del impacto (comando de acción).
##
## Flujo:
##   1. Se acerca a saltitos hasta media distancia.
##   2. Anticipación (se aplasta y tiembla) para avisar al jugador.
##   3. Embestida en arco; durante el salto se abre el comando de esquive.
##      - Éxito: el objetivo salta, el atacante pasa por debajo y no hay daño.
##      - Fallo / pulsar demasiado pronto: recibe el daño.
##   4. Vuelve a su sitio.
##
## ANIMACIÓN PLACEHOLDER: todo es procedural (el jarrón es un modelo 3D sin animaciones).
## Si el enemigo tiene sprites, rellena `anim_caminar` / `anim_ataque` en su escena de battler.

@export_group("Tiempos")
@export var duracion_acercarse: float = 0.6
## Fracción del camino que recorre antes de cargar (0 = no se mueve, 1 = hasta el objetivo)
@export_range(0.0, 1.0) var fraccion_acercamiento: float = 0.45
@export var duracion_carga: float = 0.4
## Duración del salto de la embestida (el impacto ocurre al final)
@export var tiempo_impacto: float = 0.5
@export var altura_salto: float = 0.9
@export var ventana_antes: float = 0.2
@export var ventana_despues: float = 0.05
@export var duracion_volver: float = 0.55

@export_group("Comando de esquive")
## En Paper Mario no se muestra ayuda al defenderse; para el prototipo se muestra el indicador
@export var mostrar_indicador: bool = true

@export_group("Sonidos")
@export var sonido_carga: AudioStream = preload("res://assets/audio/sfx/snd_mysterygo.wav")
@export var sonido_golpe: AudioStream = preload("res://assets/audio/sfx/snd_doorclose.wav")
@export var sonido_esquive: AudioStream = preload("res://assets/audio/sfx/snd_item.wav")

func _init() -> void:
	nombre = "Embestida"
	descripcion = "Salta contra el objetivo. Se puede esquivar a tiempo."
	objetivo = Objetivo.ENEMIGO

func ejecutar(origen: Battler, objetivos: Array[Battler], arena: Node) -> void:
	if objetivos.is_empty():
		return
	var victima: Battler = objetivos[0]
	var frente: Vector3 = victima.posicion_frente(origen)
	var punto_carga: Vector3 = origen.global_position.lerp(frente, fraccion_acercamiento)

	# 1. Acercarse
	await origen.caminar_hasta(punto_carga, duracion_acercarse)

	# 2. Anticipación
	arena.reproducir_sonido(sonido_carga)
	await origen.aplastar(Vector3(1.25, 0.7, 1.25), duracion_carga)

	# 3. Embestida + comando de esquive
	# El esquive visual empieza en cuanto se pulsa bien (no al impacto) para que se vea fluido
	var al_resolver: Callable = func(resultado: ComandoAccion.Resultado) -> void:
		if resultado == ComandoAccion.Resultado.EXITO:
			victima.animar_esquive()
	arena.comando.resuelto.connect(al_resolver, CONNECT_ONE_SHOT)

	origen.reproducir(origen.anim_ataque)
	_animar_salto(origen, punto_carga, frente)
	var pos_indicador: Vector2 = arena.a_pantalla(victima.punto_cabeza() + Vector3.UP * 0.6)
	var resultado_cmd: ComandoAccion.Resultado = await arena.comando.ejecutar(
			tiempo_impacto, ventana_antes, ventana_despues, pos_indicador, mostrar_indicador)
	if arena.comando.resuelto.is_connected(al_resolver):
		arena.comando.resuelto.disconnect(al_resolver)

	if resultado_cmd == ComandoAccion.Resultado.EXITO:
		# Esquivado: el atacante sigue de largo por debajo del objetivo
		arena.reproducir_sonido(sonido_esquive)
		arena.mostrar_texto(victima, "¡Esquivado!", Color(0.55, 1.0, 0.65))
		var dir: float = signf(frente.x - punto_carga.x)
		var pasado: Vector3 = Vector3(victima.global_position.x + dir * (victima.radio + origen.radio + 0.4), frente.y, frente.z)
		var tween_pasar: Tween = origen.create_tween()
		tween_pasar.tween_property(origen, "global_position", pasado, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween_pasar.finished
		await origen.aplastar(Vector3(1.2, 0.8, 1.2), 0.15)
	else:
		# Impacto
		var danio: int = calcular_danio(origen, victima, poder)
		arena.reproducir_sonido(sonido_golpe)
		victima.recibir_danio(danio)
		arena.mostrar_numero(victima, danio, false)
		arena.sacudir_camara(0.2)
		if victima.esta_vivo():
			victima.animar_herido()
		# Rebote hacia atrás tras el golpe
		var dir_rebote: float = signf(punto_carga.x - frente.x)
		var tween_rebote: Tween = origen.create_tween()
		tween_rebote.tween_property(origen, "global_position:x", frente.x + dir_rebote * 0.6, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_rebote.parallel().tween_property(origen.visual, "position:y", origen.visual.position.y + 0.4, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_rebote.tween_property(origen.visual, "position:y", origen.visual.position.y, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tween_rebote.finished

	await arena.esperar(0.25)

	# 4. Volver
	await origen.volver_a_base(duracion_volver)

## Salto en arco desde `desde` hasta `hasta`, aterrizando justo en `tiempo_impacto`
func _animar_salto(origen: Battler, desde: Vector3, hasta: Vector3) -> void:
	origen.global_position = desde
	var mitad: float = tiempo_impacto * 0.5
	var y_base: float = origen.visual.position.y
	var tween_x: Tween = origen.create_tween()
	tween_x.tween_property(origen, "global_position", hasta, tiempo_impacto).set_trans(Tween.TRANS_LINEAR)
	var tween_y: Tween = origen.create_tween()
	tween_y.tween_property(origen.visual, "position:y", y_base + altura_salto, mitad).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(origen.visual, "position:y", y_base, mitad).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
