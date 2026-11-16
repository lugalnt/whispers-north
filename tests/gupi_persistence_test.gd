extends SceneTree
var fallos := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, mensaje: String) -> void:
	if not ok: fallos += 1
	print("PASS " if ok else "FAIL ", mensaje)
func cargar() -> Node:
	var zona = load("res://scenes/world/World_Town.tscn").instantiate()
	root.add_child(zona)
	current_scene = zona
	for i in 12: await physics_frame
	return zona
func run() -> void:
	var gs := root.get_node("GameState")
	gs.nueva_partida()
	var zona: Node = await cargar()
	var j: Node = null
	for n in zona.find_children("*", "CharacterBody3D", true, false):
		if n is Jarrito: j = n; break
	check(j != null, "Jarrón disponible en nueva partida")
	var ruta := zona.get_path_to(j)
	var id: StringName = j._id_derrota
	j._retirar_derrotado()
	for i in 3: await physics_frame
	check(gs.tiene_progreso(id), "Derrota registra identificador estable")
	check(zona.get_node_or_null(ruta) == null, "Derrotado desaparece")
	zona.queue_free()
	await process_frame
	zona = await cargar()
	check(zona.get_node_or_null(ruta) == null, "Volver al pueblo no revive al derrotado")
	zona.queue_free()
	await process_frame
	gs.nueva_partida()
	zona = await cargar()
	check(zona.get_node_or_null(ruta) != null, "Nueva partida restaura enemigo")
	zona.queue_free()
	await process_frame
	print("RESULTADO PERSISTENCIA: ", fallos, " fallos")
	quit(1 if fallos else 0)
