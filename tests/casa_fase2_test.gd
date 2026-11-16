extends SceneTree

var fallos := 0
var pruebas := 0
var gs: Node

func _initialize() -> void:
	ejecutar.call_deferred()

func check(valor: bool, mensaje: String) -> void:
	pruebas += 1
	if not valor:
		fallos += 1
		push_error("FAIL " + mensaje)
	else:
		print("PASS " + mensaje)

func cuadros(n: int = 8) -> void:
	for i in n:
		await physics_frame
		await process_frame

func captura(nombre: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("wotn_fase2_" + nombre + ".png"))

func cargar() -> Node:
	if is_instance_valid(current_scene):
		current_scene.queue_free()
		await cuadros()
	var casa: Node = load(gs.ESCENA_CASA).instantiate()
	root.add_child(casa)
	current_scene = casa
	await cuadros(20)
	return casa

func leer(dialogo: InteraccionDialogo, jugador: Node3D) -> void:
	dialogo.iniciar_dialogo(jugador)
	await cuadros()
	check(dialogo._en_dialogo and jugador.is_interacting, "Diálogo real abierto y jugador bloqueado")
	await captura("dialogo")
	for i in 70:
		if not dialogo._en_dialogo:
			break
		var evento := InputEventAction.new()
		evento.action = &"ui_accept"
		evento.pressed = true
		for nodo in current_scene.get_children():
			if nodo is NordicDialogueBalloon:
				nodo._unhandled_input(evento)
		await cuadros(3)
	check(not dialogo._en_dialogo and not jugador.is_interacting, "Diálogo completado y controles restaurados")

func ejecutar() -> void:
	gs = root.get_node("GameState")
	gs.nueva_partida()
	check(gs.escena_nueva_partida == gs.ESCENA_CASA, "Nueva partida empieza en casa")
	var casa: Node = await cargar()
	var jugador: CharacterBody3D = casa.get_active_player()
	var diario: InteraccionDialogo = casa.diario
	var bajar: Node = casa.get_node("Transiciones/Puerta_Cuarto_Escalera")
	check(jugador.is_on_floor(), "Aparición junto a cama sobre suelo")
	await captura("cuarto")
	var posicion := jugador.global_position
	bajar._iniciar_transicion(jugador)
	await cuadros()
	check(jugador.global_position.distance_to(posicion) < 0.1, "No baja antes de leer el diario")
	check(not jugador.is_interacting, "Intento bloqueado no congela jugador")
	# Las líneas y los indicadores proceden del Input Map, sin crear acciones.
	check(diario.lineas_rapidas[2].contains(casa._control(&"interact")), "Tutorial refleja control de interacción")
	casa._usa_mando = true
	casa._actualizar_textos()
	check(diario.lineas_rapidas[2].contains(casa._control(&"interact")), "Tutorial refleja control de mando")
	casa._usa_mando = false
	casa._actualizar_textos()
	await leer(diario, jugador)
	check(gs.tiene_progreso(gs.PROGRESO_TUTORIAL_DIARIO), "Lectura completa registra progreso")
	check(not diario.activo and not casa.pista.visible, "Tutorial deja de mostrarse al terminar")
	var id_jugador := jugador.get_instance_id()
	await bajar._iniciar_transicion(jugador)
	await cuadros()
	check(jugador.get_instance_id() == id_jugador and current_scene == casa, "Escalera conserva jugador y escena")
	check(root.get_camera_3d().name == "Camera2" and jugador.global_position.x > 35, "Bajada activa planta baja")
	check(not jugador.is_interacting and not gs.hay_transicion_pendiente(), "Escalera restaura control sin estado pendiente")
	await captura("planta_baja")
	await leer(casa.padre, jugador)
	check(gs.tiene_progreso(gs.PROGRESO_CHARLA_PROGENITOR), "Charla con padre registrada")
	await casa.get_node("Transiciones/Escalera_Subir")._iniciar_transicion(jugador)
	await cuadros()
	check(root.get_camera_3d().name == "Camera1" and jugador.global_position.x < 4, "Regreso al cuarto")
	# Restaurar progreso al recargar, como al volver desde la vecindad.
	gs.preparar_transicion("Llegada_DesdeVecindad", Vector3.ZERO, "Camera2")
	casa = await cargar()
	await create_timer(0.6).timeout
	check(not casa.diario.activo and not casa.pista.visible, "Regreso a casa no repite tutorial")
	check(casa.padre.lineas_rapidas.size() == 1, "Padre usa saludo posterior al regresar")
	# Cancelar a mitad del fundido libera la reserva común y el jugador.
	jugador = casa.get_active_player()
	var subir: Node = casa.get_node("Transiciones/Escalera_Subir")
	subir._iniciar_transicion(jugador)
	await cuadros(2)
	subir.queue_free()
	await cuadros()
	check(not jugador.is_interacting, "Eliminar transición restaura controles")
	check(root.get_node("CoordinadorEncuentros").bloquear_actividad(casa), "Cancelación libera coordinador")
	root.get_node("CoordinadorEncuentros").liberar_actividad(casa)
	gs.nueva_partida()
	casa = await cargar()
	check(casa.diario.activo and casa.pista.visible, "Nueva partida reactiva tutorial")
	check(not gs.tiene_progreso(gs.PROGRESO_CHARLA_PROGENITOR), "Nueva partida reinicia charla")
	casa.queue_free()
	await cuadros()
	print("RESULTADO FASE 2: %d pruebas, %d fallos" % [pruebas, fallos])
	quit(1 if fallos else 0)
