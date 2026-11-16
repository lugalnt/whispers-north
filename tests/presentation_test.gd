extends SceneTree
var fallos := 0
func _initialize() -> void: ejecutar.call_deferred()
func check(ok: bool, nombre: String) -> void:
	if not ok: fallos += 1
	print("PASS " if ok else "FAIL ", nombre)
func foto(nombre: String) -> void:
	await create_timer(0.3).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("wotn_fix_" + nombre + ".png"))
func ejecutar() -> void:
	root.get_node("GameState").nueva_partida()
	var menu = load("res://scenes/ui/MainMenu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(900, 700))
	menu._on_opciones_pressed()
	await create_timer(0.7).timeout
	await foto("opciones")
	var panel: Control = menu.get_node("PanelOpciones")
	check(panel.get_global_rect().encloses(menu.get_node("PanelOpciones/ListaOpciones/Regresar").get_global_rect()), "Opciones: botón dentro del panel")
	menu.queue_free()
	await process_frame
	for nombre in ["World", "World_Town", "World_House", "World_Cave", "World_ForestRuins"]:
		var zona = load("res://scenes/world/" + nombre + ".tscn").instantiate()
		root.add_child(zona)
		current_scene = zona
		await create_timer(0.7).timeout
		var jugador = zona.get_active_player()
		var guardia: Node
		for child in zona.get_children():
			if child.get_script() == load("res://scripts/world/world_presentation.gd"): guardia = child
		check(guardia != null, nombre + ": guardia de encuadre")
		if nombre == "World":
			check(guardia.vegetacion.size() > 20, "Vegetación apoyada en suelo")
			await foto("arboles")
			var pausa = zona.get_node("PauseMenu")
			root.get_node("GameState").inventario.agregar(ItemDatabase.obtener_item("queso_nordico"), 2)
			pausa.abrir_menu()
			pausa.cambiar_pestana(1)
			await foto("stats")
			var cont: Control = pausa.get_node("ContenedorPrincipal")
			var grid: Control = cont.find_child("GridStats", true, false)
			check(cont.get_global_rect().grow(-24).encloses(grid.get_global_rect()), "Estadísticas dentro del marco")
			pausa.cambiar_pestana(0)
			await foto("inventario")
			pausa.cerrar_menu()
		# Puntos alejados del encuadre inicial: la cámara debe recuperar al jugador.
		jugador.set_physics_process(false)
		var origen: Vector3 = jugador.global_position
		for desplazamiento in [Vector3(7, 0, 0), Vector3(-7, 0, 0), Vector3(0, 0, 7), Vector3(0, 0, -7)]:
			jugador.global_position = origen + desplazamiento
			guardia._process(0.016)
			var cam := root.get_camera_3d()
			check(not cam.is_position_behind(jugador.global_position) and root.get_visible_rect().grow(-30).has_point(cam.unproject_position(jugador.global_position)), nombre + ": protagonista en encuadre")
		zona.queue_free()
		await process_frame
	var padre := Node3D.new()
	root.add_child(padre)
	for tipo in [&"impacto", &"paso", &"agua", &"recogida"]:
		var fx = preload("res://scripts/vfx/nordic_vfx.gd").emitir(padre, tipo, Vector3.ZERO)
		check(fx != null and fx.texture != null, "VFX " + tipo)
	await create_timer(0.7).timeout
	check(padre.get_child_count() == 0, "VFX liberados al terminar")
	padre.queue_free()
	print("RESULTADO PRESENTACION: ", fallos, " fallos")
	quit(1 if fallos else 0)


