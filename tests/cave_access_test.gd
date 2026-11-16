extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.get_node("GameState").nueva_partida()
	var zona = load("res://scenes/world/World_Town.tscn").instantiate()
	root.add_child(zona)
	current_scene = zona
	for i in 20: await physics_frame
	var jugador: CharacterBody3D = zona.get_active_player()
	jugador.global_position = Vector3(46.3, 1.0, 4.3)
	jugador.set_physics_process(false)
	for i in 240:
		if not is_instance_valid(zona) or current_scene != zona: break
		if not jugador.is_interacting:
			jugador.velocity = Vector3(3, -2, 0)
			jugador.move_and_slide()
		await physics_frame
	await create_timer(0.8).timeout
	var ok := current_scene != null and current_scene.scene_file_path.ends_with("World_Cave.tscn")
	print("PASS Acceso físico a cueva atraviesa el sensor" if ok else "FAIL Entrada de cueva bloqueada")
	if current_scene: current_scene.queue_free()
	await process_frame
	quit(0 if ok else 1)

