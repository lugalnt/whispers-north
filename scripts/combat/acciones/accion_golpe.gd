class_name AccionGolpe
extends BattlerAction

## Ataque cuerpo a cuerpo del jugador con comando de acción (golpe a tiempo).
##
## Flujo:
##   1. Camina hasta el enemigo.
##   2. Se echa hacia atrás (carga) y lanza el golpe. Mientras tanto se abre el comando:
##      pulsar `interact` justo cuando el golpe conecta = +bonus de daño.
##   3. Aplica el daño, reacción del objetivo y vuelve a su sitio.
##
## ANIMACIÓN PLACEHOLDER: usa `anim_ataque` del battler (ahora "interact_side" del personaje)
## más un empujón procedural. Cuando exista una animación de ataque real (p. ej. del
## "16x16 Attack-Sheet.png"), basta con cambiar `anim_ataque` en la escena del battler y,
## si hace falta, ajustar `tiempo_impacto` para que coincida con el frame del golpe.

@export_group("Tiempos")
@export var duracion_acercarse: float = 0.5
## Segundos desde que empieza la carga hasta que el golpe conecta
@export var tiempo_impacto: float = 0.55
## Margen para pulsar antes / después del impacto
@export var ventana_antes: float = 0.2
@export var ventana_despues: float = 0.06
@export var duracion_volver: float = 0.4

@export_group("Comando de acción")
## Daño extra si se acierta el comando
@export var bonus_exito: int = 1
@export var mostrar_indicador: bool = true

@export_group("Sonidos")
@export var sonido_golpe: AudioStream = preload("res://assets/audio/sfx/snd_doorclose.wav")
@export var sonido_exito: AudioStream = preload("res://assets/audio/sfx/snd_bell_bounce_short.wav")

func _init() -> void:
	nombre = "Golpear"
	descripcion = "Pulsa el botón justo cuando el golpe conecte para hacer más daño."
	objetivo = Objetivo.ENEMIGO

func ejecutar(origen: Battler, objetivos: Array[Battler], arena: Node) -> void:
	if objetivos.is_empty():
		return
	var victima: Battler = objetivos[0]

	# 1. Acercarse
	await origen.caminar_hasta(victima.posicion_frente(origen), duracion_acercarse)
	origen.mirar_hacia(victima.global_position.x)

	# 2. Carga + golpe (en paralelo con el comando de acción)
	_animar_golpe(origen, victima)
	var pos_indicador: Vector2 = arena.a_pantalla(origen.punto_cabeza() + Vector3.UP * 0.6)
	var resultado: ComandoAccion.Resultado = await arena.comando.ejecutar(
			tiempo_impacto, ventana_antes, ventana_despues, pos_indicador, mostrar_indicador)
	var exito: bool = resultado == ComandoAccion.Resultado.EXITO

	# 3. Impacto
	var danio: int = calcular_danio(origen, victima, poder, bonus_exito if exito else 0)
	var sfx_impacto = origen.sfx_ataque_golpe if (origen and "sfx_ataque_golpe" in origen and origen.sfx_ataque_golpe) else sonido_golpe
	var sfx_bien = origen.sfx_ataque_exito if (origen and "sfx_ataque_exito" in origen and origen.sfx_ataque_exito) else sonido_exito
	arena.reproducir_sonido(sfx_impacto)
	if exito:
		arena.reproducir_sonido(sfx_bien)
	victima.recibir_danio(danio)
	arena.mostrar_numero(victima, danio, exito)
	arena.sacudir_camara(0.18 if exito else 0.08)
	if victima.esta_vivo():
		victima.animar_herido()
	await arena.esperar(0.4)

	# 4. Volver
	await origen.volver_a_base(duracion_volver)

## Carga hacia atrás y golpe hacia delante, terminando justo en `tiempo_impacto`
func _animar_golpe(origen: Battler, victima: Battler) -> void:
	var t_carga: float = tiempo_impacto * 0.6
	var t_golpe: float = tiempo_impacto - t_carga
	var dir: float = signf(victima.global_position.x - origen.global_position.x)
	var x_base: float = origen.global_position.x
	var escala: Vector3 = origen.escala_base()

	origen.reproducir(&"") # detiene la respiración procedural
	var tween: Tween = origen.create_tween()
	# Carga: se echa hacia atrás y se agacha
	tween.tween_property(origen, "global_position:x", x_base - dir * 0.35, t_carga).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(origen.visual, "scale", escala * Vector3(1.15, 0.85, 1.0), t_carga)
	# Golpe: animación de ataque (placeholder) + empujón hacia el objetivo
	tween.tween_callback(func() -> void: origen.reproducir(origen.anim_ataque))
	tween.tween_property(origen, "global_position:x", x_base + dir * 0.25, t_golpe).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(origen.visual, "scale", escala * Vector3(0.9, 1.1, 1.0), t_golpe)
	# Recuperación
	tween.tween_property(origen.visual, "scale", escala, 0.1)
	tween.tween_property(origen, "global_position:x", x_base, 0.15)
