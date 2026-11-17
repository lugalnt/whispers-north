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
	quit()
