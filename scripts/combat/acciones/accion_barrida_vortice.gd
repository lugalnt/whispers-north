class_name AccionBarridaVortice
extends BattlerAction

## Ataque especial de área desbloqueable con el NPC Útil.
## Arremete a toda velocidad atravesando a todos los enemigos en fila.
##
## Mecánica:
## - Comando de acción: Secuencia con timing de botones de movimiento y acción.
## - Éxito: Atraviesa e inflige daño a TODOS los enemigos y recibe un self-hit de 2-3 de daño.
## - Fallo / Anticipado: Tropieza sin dañar a los enemigos y recibe el self-hit de 2-3 de daño.

@export_group("Tiempos")
@export var tiempo_por_paso_comando: float = 0.65
@export var duracion_por_enemigo: float = 0.22
@export var duracion_volver: float = 0.5

@export_group("Sonidos")
@export var sonido_carga: AudioStream = preload("res://assets/audio/sfx/snd_mysterygo.wav")
@export var sonido_impacto: AudioStream = preload("res://assets/audio/sfx/test_battle_start.mp3")
@export var sonido_autodanio: AudioStream = preload("res://assets/audio/sfx/snd_doorclose.wav")

func _init() -> void:
	nombre = "Barrida Torbellino"
	descripcion = "Arremete atravesando a todos los enemigos. Requiere secuencia de timing. Inflige autodaño (2-3 HP)."
	objetivo = Objetivo.TODOS_ENEMIGOS
	poder = 2

func ejecutar(origen: Battler, objetivos: Array[Battler], arena: Node) -> void:
	# 1. Filtrar solo enemigos vivos
	var victimas: Array[Battler] = []
	for obj in objetivos:
		if is_instance_valid(obj) and obj.esta_vivo():
			victimas.append(obj)
	
	if victimas.is_empty():
		return
	
	# Ordenar víctimas por posición horizontal (de izquierda a derecha para atravesarlos en orden)
	victimas.sort_custom(func(a: Battler, b: Battler) -> bool:
		return a.global_position.x < b.global_position.x
	)
	
	var pos_indicador: Vector2 = arena.a_pantalla(origen.punto_cabeza() + Vector3.UP * 0.7)
	
	# 2. Anticipación y carga
	arena.reproducir_sonido(sonido_carga)
	origen.reproducir(origen.anim_ataque)
	await origen.aplastar(Vector3(1.2, 0.75, 1.2), 0.35)
	
	# 3. Comando de acción: secuencia de timing con botones de movimiento y acción
	var secuencia: Array[StringName] = [&"move_right", &"move_up", &"interact"]
	var resultado: ComandoAccion.Resultado = await arena.comando.ejecutar_secuencia(
		secuencia,
		tiempo_por_paso_comando,
		0.26,
		0.12,
		pos_indicador,
		true
	)
	
	var exito: bool = (resultado == ComandoAccion.Resultado.EXITO)
	var sfx_corte = origen.sfx_ataque_especial if (origen and "sfx_ataque_especial" in origen and origen.sfx_ataque_especial) else sonido_impacto
	var sfx_exito = origen.sfx_ataque_exito if (origen and "sfx_ataque_exito" in origen and origen.sfx_ataque_exito) else null
	
	if exito:
		if sfx_exito:
			arena.reproducir_sonido(sfx_exito)
		
		# 4. ÉXITO: El personaje se desplaza a toda velocidad atravesando a todos los enemigos en orden
		origen.reproducir(origen.anim_caminar)
		
		for victima in victimas:
			if not is_instance_valid(victima) or not victima.esta_vivo():
				continue
			
			# Pasar a través de la víctima
			var x_paso: float = victima.global_position.x + victima.radio + 0.5
			var pos_paso: Vector3 = Vector3(x_paso, victima.global_position.y, victima.global_position.z)
			
			var tw_corte := origen.create_tween()
			tw_corte.tween_property(origen, "global_position", pos_paso, duracion_por_enemigo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			await tw_corte.finished
			
			# Daño al enemigo atravesado
			var danio: int = calcular_danio(origen, victima, poder, 1)
			victima.recibir_danio(danio)
			arena.reproducir_sonido(sfx_corte)
			arena.mostrar_numero(victima, danio, true)
			arena.sacudir_camara(0.18)
			if victima.esta_vivo():
				victima.animar_herido()
			
			await arena.esperar(0.08)
		
		# Autodaño (self-hit de 2-3 de daño)
		var autodanio: int = randi_range(2, 3)
		_aplicar_autodanio(origen, arena, autodanio)
		
	else:
		# 4. FALLO: El personaje tropieza o avanza poco sin hacer daño a nadie, solo autodaño
		var x_fallo: float = origen.global_position.x + 1.2
		var pos_fallo: Vector3 = Vector3(x_fallo, origen.global_position.y, origen.global_position.z)
		
		var tw_fallo := origen.create_tween()
		tw_fallo.tween_property(origen, "global_position", pos_fallo, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw_fallo.finished
		
		arena.mostrar_texto(origen, "¡Fallo!", Color(1.0, 0.45, 0.4))
		
		# Autodaño (self-hit de 2-3 de daño)
		var autodanio: int = randi_range(2, 3)
		_aplicar_autodanio(origen, arena, autodanio)
	
	await arena.esperar(0.3)
	
	# 5. Volver a posición base
	await origen.volver_a_base(duracion_volver)

func _aplicar_autodanio(origen: Battler, arena: Node, danio: int) -> void:
	if not is_instance_valid(origen) or not origen.esta_vivo():
		return
	
	var sfx_herido = origen.sonido_herido if (origen and "sonido_herido" in origen and origen.sonido_herido) else sonido_autodanio
	arena.reproducir_sonido(sfx_herido)
	origen.recibir_danio(danio)
	arena.mostrar_numero(origen, danio, false)
	arena.sacudir_camara(0.15)
	if origen.esta_vivo():
		origen.animar_herido()
	
	# Sincronizar salud con GameState si es el jugador
	if origen.controlado_por_jugador:
		var GS = load("res://scripts/core/game_state.gd")
		if GS and GS.instancia != null:
			GS.instancia.actualizar_hp(origen.hp)
