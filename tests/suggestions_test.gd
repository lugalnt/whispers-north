extends SceneTree
var fallos := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, texto: String) -> void:
	if not ok: fallos += 1
	print("PASS " if ok else "FAIL ", texto)
func run() -> void:
	var hints = load("res://scripts/ui/input_hints.gd")
	check(hints.familia("Sony DualSense") == "ps" and hints.boton(0, "ps") == "✕", "PlayStation: glifo Cruz")
	check(hints.familia("Nintendo Switch Pro Controller") == "switch" and hints.boton(0, "switch") == "B", "Nintendo: botón inferior B")
	check(hints.familia("Xbox Wireless Controller") == "xbox" and hints.boton(0, "xbox") == "A", "Xbox: botón inferior A")
	var zona = load("res://scenes/world/World_Cave.tscn").instantiate()
	root.add_child(zona)
	current_scene = zona
	await create_timer(0.5).timeout
	check(zona.get_node("DecoracionTunel").get_child_count() == 16, "Cuatro faroles, cuatro cajas y cuatro rocas")
	var jugador = zona.get_active_player()
	jugador.set_physics_process(false)
	for i in 4:
		jugador.global_position = Vector3(9.5 + 21.5 * i, 1, 0)
		zona.get_node("Cameras/Camera" + str(i+1)).make_current()
		await create_timer(0.65).timeout
		var ray := PhysicsRayQueryParameters3D.create(Vector3(3, 0.5, 0), Vector3(83, 0.5, 0), 1, [jugador.get_rid()])
		check(zona.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "Paso central libre, tramo " + str(i+1))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("sugerencia_cueva" + str(i+1) + ".png"))
	zona.queue_free()
	await process_frame
	print("RESULTADO SUGERENCIAS: ", fallos, " fallos")
	quit(1 if fallos else 0)
