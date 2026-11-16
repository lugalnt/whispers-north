extends SceneTree
var fallos := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok: fallos += 1
	print("PASS " if ok else "FAIL ", message)
func run() -> void:
	var zona = load("res://scenes/world/World_Cave.tscn").instantiate()
	root.add_child(zona)
	current_scene = zona
	await create_timer(0.6).timeout
	var player = zona.get_active_player()
	player.set_physics_process(false)
	player.global_position = Vector3(9.5, 1, 0)
	var a: Camera3D = zona.get_node("Cameras/Camera1")
	var b: Camera3D = zona.get_node("Cameras/Camera2")
	a.make_current()
	await create_timer(0.6).timeout
	Input.action_press("move_right")
	player._physics_process(0.016)
	var rumbo: Vector3 = Vector3(player.velocity.x, 0, player.velocity.z).normalized()
	var base_a := a.global_transform
	var destino := b.global_position
	b.make_current()
	await create_timer(0.10).timeout
	check(a.global_transform.is_equal_approx(base_a) and b.global_position.is_equal_approx(destino), "Cambio mantiene encuadres fijos sin interpolación")
	player._physics_process(0.016)
	var nuevo: Vector3 = Vector3(player.velocity.x, 0, player.velocity.z).normalized()
	check(rumbo.dot(nuevo) > 0.999, "Mantener entrada conserva rumbo al cambiar cámara")
	await create_timer(0.6).timeout
	check(b.global_position.distance_to(destino) < 0.01, "Transición termina en el emplazamiento diseñado")
	Input.action_release("move_right")
	player._physics_process(0.016)
	Input.action_press("move_up")
	player._physics_process(0.016)
	var esperado := -root.get_camera_3d().global_basis.z
	esperado.y = 0
	nuevo = Vector3(player.velocity.x, 0, player.velocity.z).normalized()
	check(esperado.normalized().dot(nuevo) > 0.999, "Nueva entrada responde a la nueva cámara")
	Input.action_release("move_up")
	zona.queue_free()
	await process_frame
	print("RESULTADO CAMARAS: ", fallos, " fallos")
	quit(1 if fallos else 0)
