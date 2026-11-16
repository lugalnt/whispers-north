extends SceneTree
var fallos := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok: fallos += 1
	print("PASS " if ok else "FAIL ", message)
func run() -> void:
	var zona = load("res://scenes/world/World_Town.tscn").instantiate()
	root.add_child(zona)
	current_scene = zona
	await create_timer(0.8).timeout
	var jugador = zona.get_active_player()
	jugador.set_physics_process(false)
	var bases := {}
	for cam in zona.get_node("Cameras").get_children():
		if cam is Camera3D: bases[cam] = cam.global_transform
	var guardia: Node
	for nodo in zona.get_children():
		if nodo.get_script() == load("res://scripts/world/world_presentation.gd"): guardia = nodo
	for pos in [Vector3(-7,1.1,18),Vector3(-14,1.1,11),Vector3(0,1.1,11),Vector3(8,1.1,4),Vector3(22,1.1,4),Vector3(35,1.1,4),Vector3(45,1.1,4)]:
		jugador.global_position = pos
		await create_timer(0.8).timeout
		check(guardia._encuadra(root.get_camera_3d(), jugador, 0.02), "Jugador completo en " + str(pos))
	for cam in bases:
		check(cam.global_transform.is_equal_approx(bases[cam]), str(cam.name) + " conserva posición y ángulo")
	check(zona.get_node("DecoracionNueva").get_child_count() == 14, "Cinco bancos y nueve jardineras")
	for i in 4:
		var prop = zona.get_node("DecoracionNueva").get_child(i)
		var pos: Vector3 = prop.global_position - zona.get_node("Fountain").global_position
		check(Vector2(pos.x,pos.z).length() > 6.5, "Mueble de plaza separado de fuente")
	zona.queue_free()
	await process_frame
	print("RESULTADO CAMARAS FIJAS: ", fallos, " fallos")
	quit(1 if fallos else 0)
