extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var zona = load("res://scenes/world/World_Town.tscn").instantiate()
	root.add_child(zona)
	current_scene = zona
	await create_timer(0.8).timeout
	var jugador = zona.get_active_player()
	jugador.set_physics_process(false)
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.fov = 50
	for nombre in ["Npc", "Npc_Exp", "Npc_Util"]:
		var npc = zona.get_node(nombre)
		jugador.global_position = npc.global_position + Vector3(1.8, 0, 0)
		cam.position = npc.global_position + Vector3(1, 3.2, 7)
		cam.look_at(npc.global_position + Vector3(0.7, 0, 0))
		cam.make_current()
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("asset_" + nombre + ".png"))
		var sp = npc.get_node("Sprite2_5D")
		var tex = sp.sprite_frames.get_frame_texture("interact_down", 0)
		print(nombre, " altura=", tex.get_height()*sp.pixel_size, " pies=", sp.global_position.y-tex.get_height()*sp.pixel_size/2)
	quit()
