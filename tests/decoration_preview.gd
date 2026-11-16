extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	for nombre in ["World", "World_Town"]:
		var zona = load("res://scenes/world/" + nombre + ".tscn").instantiate()
		root.add_child(zona)
		current_scene = zona
		await create_timer(0.7).timeout
		var rig := Node3D.new()
		zona.add_child(rig)
		var cam := Camera3D.new()
		rig.add_child(cam)
		cam.projection = Camera3D.PROJECTION_PERSPECTIVE
		cam.size = 55
		cam.position = Vector3(0, 70, 0) if nombre == "World" else Vector3(7, 70, 0)
		cam.position = Vector3(-9, 8, -9) if nombre == "World" else Vector3(-9, 10, 24)
		cam.look_at(Vector3(2, 0.5, -13) if nombre == "World" else Vector3(-7, 0, 10))
		print(nombre, ": ", zona.get_node("DecoracionEntorno").get_child_count(), " decoraciones")
		cam.make_current()
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("decor_" + nombre + ".png"))
		zona.queue_free()
		await process_frame
	quit()


