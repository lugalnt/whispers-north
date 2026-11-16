extends SceneTree
var fallos := 0
func _initialize() -> void: ejecutar.call_deferred()
func check(ok: bool, mensaje: String) -> void:
	if not ok: fallos += 1
	print("PASS " if ok else "FAIL ", mensaje)
func frames(n := 5) -> void:
	for i in n: await physics_frame
func foto(nombre: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("gupi_" + nombre + ".png"))
func ejecutar() -> void:
	root.get_node("GameState").nueva_partida()
	var casa = load("res://scenes/world/World_House.tscn").instantiate()
	root.add_child(casa)
	current_scene = casa
	await frames(20)
	var evento: InputEvent = InputMap.action_get_events("interact").filter(func(e): return e is InputEventJoypadButton)[0]
	casa._input(evento)
	check(not casa.pista.text.contains("Joypad") and casa.pista.text.length() < 230, "Tutorial de mando legible y sin nombres internos")
	await foto("casa_mando")
	var pausa = casa.get_node("PauseMenu")
	pausa._input(evento)
	check(pausa.lbl_header_pistas.text.contains("LB") and not pausa.lbl_header_pistas.text.contains("Q / E"), "Pistas de pausa reflejan mando")
	pausa.abrir_menu()
	await process_frame
	await foto("pausa_mando")
	pausa.cerrar_menu()
	var controles = load("res://scenes/ui/ControlsMenu.tscn").instantiate()
	casa.add_child(controles)
	await process_frame
	for lista in [controles._lista_teclado, controles._lista_joycon]:
		for i in range(1, lista.get_child_count()):
			for col in [2, 3]:
				var boton = lista.get_child(i).get_child(col)
				check(boton.get_node(boton.focus_neighbor_top) == lista.get_child(i-1).get_child(col), "Foco vertical permanece en columna")
	controles.queue_free()
	casa.queue_free()
	await frames()
	for nombre in ["World", "World_Town"]:
		var zona = load("res://scenes/world/" + nombre + ".tscn").instantiate()
		root.add_child(zona)
		current_scene = zona
		await frames(30)
		var borde = zona.get_node_or_null("LimitesMundo")
		check(borde != null and not borde.regiones.is_empty(), nombre + " tiene perímetro")
		var count := 0
		for cuerpo in borde.get_children():
			if not cuerpo is StaticBody3D: continue
			var tam: Vector3 = cuerpo.get_child(0).shape.size
			var dir := Vector3.RIGHT if tam.x < tam.z else Vector3.BACK
			var centro: Vector3 = cuerpo.global_position - Vector3.UP
			var ray := PhysicsRayQueryParameters3D.create(centro - dir, centro + dir)
			if not zona.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(): count += 1
		check(count > 3, nombre + " barreras físicas verificadas: " + str(count))
		var jugador = zona.get_active_player()
		var cam := root.get_camera_3d()
		var origen := cam.global_position
		jugador.global_position += Vector3(1, 0, 2)
		await frames(15)
		check(cam.global_position.is_equal_approx(origen), "Corrección de cámara no traslada su posición")
		await foto(nombre)
		# Forzar caída para comprobar la recuperación de seguridad.
		jugador._ultimo_suelo = jugador.global_position
		jugador._hay_suelo_seguro = true
		jugador.global_position.y -= 12
		await frames(3)
		check(jugador.global_position.y > -2, "Recuperación después de caída accidental")
		zona.queue_free()
		await frames()
	current_scene = null
	print("RESULTADO GUPI: ", fallos, " fallos")
	quit(1 if fallos else 0)
