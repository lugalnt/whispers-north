extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for nombre in ["World_House", "World", "World_Town", "World_ForestRuins"]:
		var zona = load("res://scenes/world/" + nombre + ".tscn").instantiate()
		root.add_child(zona)
		current_scene = zona
		await create_timer(0.8).timeout
		await foto(nombre)
		if nombre == "World_House":
			zona.get_active_player().global_position = Vector3(40, 1.1, 0)
			zona.get_node("Cameras/Camera2").make_current()
			await create_timer(0.3).timeout
			await foto("PlantaBaja")
		zona.queue_free()
		await process_frame
	quit()
func foto(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("luz_" + nombre + ".png"))
