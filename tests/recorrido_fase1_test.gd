extends SceneTree
## Pruebas de validación de la Fase 1: Recorrido de 5 zonas, WorldTransition,
## cámaras sin solape de sistemas, persistencia en GameState y Nueva partida.
## Ejecutar:
##   godot --headless --path . --script res://tests/recorrido_fase1_test.gd

var fallos: int = 0
var gs: Node

func _initialize() -> void:
	_ejecutar.call_deferred()

func comprobar(valor: bool, mensaje: String) -> void:
	if valor:
		print("PASS ", mensaje)
	else:
		fallos += 1
		push_error("FAIL: " + mensaje)

func cuadros(cantidad: int) -> void:
	for i in cantidad:
		await physics_frame
		await process_frame

func cargar_escena_limpia(ruta: String) -> Node:
	if current_scene != null and is_instance_valid(current_scene):
		current_scene.queue_free()
		current_scene = null
		await cuadros(3)
	var packed: PackedScene = load(ruta) as PackedScene
	comprobar(packed != null, "Escena cargable: %s" % ruta)
	if packed == null:
		return null
	var inst: Node = packed.instantiate()
	inst.scene_file_path = ruta
	root.add_child(inst)
	current_scene = inst
	await cuadros(6)
	return inst

## Simula el salto de WorldTransition entre la escena actual y su destino
## verificando marcadores, posición segura, cámara, ausencia de bucle y persistencia.
func verificar_transicion(escena_origen: String, nombre_transicion: String, escena_esperada: String, marcador_esperado: String, camara_esperada: String) -> void:
	gs.spawn_nombre_marcador = ""
	gs.spawn_camara_siguiente = ""
	var origen: Node = await cargar_escena_limpia(escena_origen)
	if origen == null:
		return
	var trans: WorldTransition = origen.find_child(nombre_transicion, true, false) as WorldTransition
	comprobar(trans != null, "Existe WorldTransition '%s' en %s" % [nombre_transicion, escena_origen.get_file()])
	if trans == null:
		return
	comprobar(trans.escena_destino == escena_esperada, "%s -> escena_destino = %s" % [nombre_transicion, escena_esperada.get_file()])
	comprobar(trans.nombre_marcador_destino == marcador_esperado, "%s -> marcador = %s" % [nombre_transicion, marcador_esperado])
	comprobar(trans.camara_destino == camara_esperada, "%s -> camara = %s" % [nombre_transicion, camara_esperada])

	var jugador_origen: CharacterBody3D = origen.call("get_active_player") as CharacterBody3D
	comprobar(jugador_origen != null, "Jugador activo en origen %s" % escena_origen.get_file())

	# Preparar transición como hace WorldTransition._iniciar_transicion
	gs.preparar_transicion(trans.nombre_marcador_destino, trans.offset_aparicion, trans.camara_destino)
	var destino: Node = await cargar_escena_limpia(trans.escena_destino)
	if destino == null:
		return

	comprobar(not gs.hay_transicion_pendiente(), "Transición consumida al entrar en %s" % escena_esperada.get_file())
	comprobar(gs.zona_actual == escena_esperada, "GameState.zona_actual actualizada a %s" % escena_esperada.get_file())

	var marcador_nodo: Node3D = destino.find_child(marcador_esperado, true, false) as Node3D
	comprobar(marcador_nodo != null, "Existe marcador '%s' en %s" % [marcador_esperado, escena_esperada.get_file()])

	var jugador_dest: CharacterBody3D = destino.call("get_active_player") as CharacterBody3D
	comprobar(jugador_dest != null, "Jugador activo tras llegar a %s" % escena_esperada.get_file())

	var cam_actual: Camera3D = root.get_camera_3d()
	comprobar(cam_actual != null and cam_actual.name == camara_esperada, "Cámara activa tras transición (%s -> %s): esperado '%s', actual '%s'" % [
		escena_origen.get_file(), escena_esperada.get_file(), camara_esperada, cam_actual.name if cam_actual else "ninguna"
	])

	# Dejar correr física para verificar que hay piso debajo y no se activa otra transición en bucle
	var y_inicial: float = jugador_dest.global_position.y
	await cuadros(18)
	var y_final: float = jugador_dest.global_position.y
	comprobar(y_final > -1.5 and absf(y_final - y_inicial) < 2.5, "Posición de llegada segura sobre suelo en %s (%s, y=%.2f)" % [
		escena_esperada.get_file(), marcador_esperado, y_final
	])

	var solapa_transicion: bool = false
	for nodo in destino.find_children("*", "Area3D", true, false):
		if nodo is WorldTransition and (nodo as Area3D).overlaps_body(jugador_dest):
			solapa_transicion = true
			break
	comprobar(not solapa_transicion, "Llegada '%s' en %s no solapa con ningún WorldTransition (sin bucle)" % [
		marcador_esperado, escena_esperada.get_file()
	])

func _ejecutar() -> void:
	gs = root.get_node("GameState")
	comprobar(gs != null, "Autoload GameState disponible")

	# 1. Progresión única y reinicio de Nueva Partida
	gs.nueva_partida()
	var senales_progreso: Array = []
	gs.progreso_cambiado.connect(func(id: StringName, val: Variant): senales_progreso.append([id, val]))

	comprobar(not gs.tiene_progreso(gs.PROGRESO_TUTORIAL_DIARIO), "Progreso inicial limpio tras nueva_partida()")
	comprobar(gs.reclamar_unico(gs.PROGRESO_TUTORIAL_DIARIO), "Primera llamada a reclamar_unico devuelve true")
	comprobar(not gs.reclamar_unico(gs.PROGRESO_TUTORIAL_DIARIO), "Segunda llamada a reclamar_unico devuelve false")
	comprobar(gs.tiene_progreso(gs.PROGRESO_TUTORIAL_DIARIO), "tiene_progreso refleja bandera reclamada")
	comprobar(senales_progreso.size() == 1 and senales_progreso[0][0] == gs.PROGRESO_TUTORIAL_DIARIO, "Señal progreso_cambiado emitida una sola vez")

	gs.agregar_exp(60)
	gs.actualizar_hp(7)
	gs.tiene_rata = true
	gs.desbloquear_accion("barrida_vortice")
	gs.agregar_item("llave_antigua", 2)
	gs.marcar_progreso(gs.COFRE_CUEVA_OCULTO, true)

	comprobar(gs.nivel >= 2 and gs.hp_actual == 7 and gs.tiene_rata and gs.tiene_accion("barrida_vortice"), "Estado modificado antes de reiniciar")

	gs.nueva_partida()
	comprobar(gs.nivel == 1 and gs.exp_actual == 0 and gs.exp_para_siguiente_nivel == 50, "nueva_partida() reinicia nivel y EXP")
	comprobar(gs.hp_actual == gs.stats.max_hp and not gs.tiene_rata and gs.acciones_desbloqueadas.is_empty(), "nueva_partida() reinicia HP, rata y acciones")
	comprobar(not gs.tiene_progreso(gs.PROGRESO_TUTORIAL_DIARIO) and not gs.tiene_progreso(gs.COFRE_CUEVA_OCULTO), "nueva_partida() limpia banderas de progreso")
	comprobar(gs.inventario.obtener_cantidad("fragmento_ceramica") == 3 and gs.inventario.obtener_cantidad("llave_antigua") == 1, "nueva_partida() restaura inventario inicial exacto")

	# 2. Inspección de las 5 escenas del recorrido y exclusión de sistemas de cámaras
	var escenas_recorrido: Array[String] = [
		gs.ESCENA_CASA,
		gs.ESCENA_VECINDAD,
		gs.ESCENA_PUEBLO,
		gs.ESCENA_CUEVA,
		gs.ESCENA_BOSQUE,
	]
	for ruta in escenas_recorrido:
		var nodo: Node = await cargar_escena_limpia(ruta)
		comprobar(nodo != null, "Instanciación limpia de %s" % ruta.get_file())
		if nodo == null:
			continue
		var p: CharacterBody3D = nodo.call("get_active_player") as CharacterBody3D
		comprobar(p != null, "%s expone get_active_player()" % ruta.get_file())
		var pause_menu: Node = nodo.find_child("PauseMenu", true, false)
		comprobar(pause_menu is PauseMenu, "%s instancia PauseMenu" % ruta.get_file())
		var cam: Camera3D = root.get_camera_3d()
		comprobar(cam != null, "%s activa una Camera3D inicial" % ruta.get_file())

		var switches_antiguos: Array = nodo.find_children("SwitchC_*", "Area3D", true, false)
		var switches_nuevos: Array = []
		for area in nodo.find_children("*", "Area3D", true, false):
			if area is CameraSwitch:
				switches_nuevos.append(area)
		var mezcla: bool = (not switches_antiguos.is_empty()) and (not switches_nuevos.is_empty())
		comprobar(not mezcla, "%s no mezcla SwitchC_* (%d) con CameraSwitch (%d)" % [
			ruta.get_file(), switches_antiguos.size(), switches_nuevos.size()
		])

	# 3. Persistencia de HP, inventario, rata y progreso a través de todo el recorrido ida y vuelta
	gs.nueva_partida()
	gs.actualizar_hp(9)
	gs.tiene_rata = true
	gs.agregar_item("queso_nordico", 2) # 2 iniciales + 2 = 4
	gs.reclamar_unico(gs.RECOMPENSA_NPC_UTIL)

	# Recorrido de IDA: Casa (Cuarto -> PlantaBaja) -> Vecindad -> Pueblo -> Cueva -> Bosque
	await verificar_transicion(gs.ESCENA_CASA, "Puerta_Cuarto_Escalera", gs.ESCENA_CASA, "Llegada_Escalera", "Camera2")
	await verificar_transicion(gs.ESCENA_CASA, "Puerta_Salida_Vecindad", gs.ESCENA_VECINDAD, "Llegada_DesdeCasa", "Camera1")
	await verificar_transicion(gs.ESCENA_VECINDAD, "Marker_Exit_World", gs.ESCENA_PUEBLO, "Marker_Exit_World", "Camera1")

	# Verificar que la salida del pueblo hacia la cueva está en el extremo derecho (X > 45)
	var salida_cueva: WorldTransition = current_scene.find_child("Salida_Cueva", true, false) as WorldTransition
	comprobar(salida_cueva != null and salida_cueva.global_position.x > 45.0, "Salida del pueblo hacia la cueva situada a la derecha (X=%.1f)" % (salida_cueva.global_position.x if salida_cueva else -1.0))

	await verificar_transicion(gs.ESCENA_PUEBLO, "Salida_Cueva", gs.ESCENA_CUEVA, "Llegada_DesdePueblo", "Camera1")
	await verificar_transicion(gs.ESCENA_CUEVA, "Salida_Bosque", gs.ESCENA_BOSQUE, "Llegada_DesdeCueva", "Camera1")

	# Verificar activación de cámaras por zonas en el bosque (caminar por zonas del mapa del DOCX)
	var jugador_bosque: CharacterBody3D = current_scene.call("get_active_player") as CharacterBody3D
	var zona_jefe: CameraSwitch = current_scene.find_child("ZonaCam_10", true, false) as CameraSwitch
	comprobar(zona_jefe != null, "Bosque cuenta con las 10 zonas de cámara del mapa del DOCX")
	if zona_jefe != null and jugador_bosque != null:
		zona_jefe._on_body_entered(jugador_bosque)
		comprobar(root.get_camera_3d() != null and root.get_camera_3d().name == "Camera10", "ZonaCam_10 activa Camera10 en el extremo superior derecho del bosque")

	# Recorrido de REGRESO: Bosque -> Cueva -> Pueblo -> Vecindad -> Casa (PlantaBaja -> Cuarto)
	await verificar_transicion(gs.ESCENA_BOSQUE, "Entrada_Cueva", gs.ESCENA_CUEVA, "Llegada_DesdeBosque", "Camera4")
	await verificar_transicion(gs.ESCENA_CUEVA, "Entrada_Pueblo", gs.ESCENA_PUEBLO, "Llegada_DesdeCueva", "Camera12")
	await verificar_transicion(gs.ESCENA_PUEBLO, "Marker_Exit_World", gs.ESCENA_VECINDAD, "Marker_Exit_World", "Camera6")
	await verificar_transicion(gs.ESCENA_VECINDAD, "Entrada_Casa", gs.ESCENA_CASA, "Llegada_DesdeVecindad", "Camera2")
	await verificar_transicion(gs.ESCENA_CASA, "Escalera_Subir", gs.ESCENA_CASA, "Llegada_PuertaCuarto", "Camera1")

	# Comprobar conservación de estado tras completar ida y vuelta
	var jugador_final: CharacterBody3D = current_scene.call("get_active_player") as CharacterBody3D
	var tiene_nodo_rata: bool = false
	if jugador_final != null:
		for c in jugador_final.get_children():
			if c.name.begins_with("Rat") or c.is_in_group("rat"):
				tiene_nodo_rata = true
				break
	comprobar(gs.hp_actual == 9, "HP conservado tras recorrido completo (HP=%d)" % gs.hp_actual)
	comprobar(gs.inventario.obtener_cantidad("queso_nordico") == 4, "Inventario conservado tras recorrido completo")
	comprobar(gs.tiene_rata and tiene_nodo_rata, "Acompañante (Rata) conservado e instanciado en el jugador tras recorrido completo")
	comprobar(gs.tiene_progreso(gs.RECOMPENSA_NPC_UTIL), "Progreso único conservado entre cambios de mapa")

	if current_scene != null:
		current_scene.queue_free()
	await cuadros(3)
	print("RESULTADO FASE 1: ", fallos, " fallos")
	quit(1 if fallos else 0)

