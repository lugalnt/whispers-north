extends SceneTree
var fallos := 0
var muestras := 0
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var planes = JSON.parse_string(FileAccess.get_file_as_string("res://tests/sector_camera_points.json"))
	for nombre in planes:
		var zona = load("res://scenes/world/" + nombre + ".tscn").instantiate()
		root.add_child(zona)
		current_scene = zona
		await create_timer(0.7).timeout
		var jugador = zona.get_active_player()
		jugador.set_physics_process(false)
		var guardia: Node
		for nodo in zona.get_children():
			if nodo.get_script() == load("res://scripts/world/world_presentation.gd"): guardia = nodo
		var bases := {}
		for cam in zona.find_children("*", "Camera3D", true, false): bases[cam] = cam.global_transform
		var usadas := {}
		for entrada in planes[nombre]:
			for offset in [Vector2.ZERO, Vector2(-2,0), Vector2(2,0), Vector2(0,-2), Vector2(0,2)]:
				jugador.global_position = Vector3(float(entrada[1])+offset.x, 1.6 if nombre == "World" else 1.1, float(entrada[2])+offset.y)
				guardia._process(1.0)
				var cam := root.get_camera_3d()
				muestras += 1
				if not guardia._encuadra(cam,jugador,0.03):
					fallos += 1
					print("FAIL encuadre ",nombre," ",entrada[0]," ",offset)
				usadas[cam.name] = true
			if DisplayServer.get_name() != "headless" and entrada == planes[nombre][0]:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("sectores_"+nombre+".png"))
		for cam in bases:
			if not cam.global_transform.is_equal_approx(bases[cam]):
				fallos += 1
				print("FAIL transformación ",cam.name)
		if usadas.size() < 2: fallos += 1
		print(nombre," usa ",usadas.size()," encuadres diferentes; cámaras inmutables comprobadas")
		zona.queue_free()
		await process_frame
	print("RESULTADO SECTORES: ",muestras," muestras, ",fallos," fallos")
	quit(1 if fallos else 0)
