extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var gs = root.get_node("GameState")
	gs.nueva_partida()
	var world = load("res://scenes/world/World.tscn").instantiate()
	root.add_child(world)
	current_scene = world
	await process_frame
	var chest = world.get_node("Chest")
	var player := CharacterBody3D.new()
	root.add_child(player)
	assert(not chest.contiene_rata)
	await chest.abrir(player)
	assert(gs.inventario.obtener_cantidad("espada_corta") == 1)
	assert(not chest.rata_en_cabeza and not gs.tiene_rata)
	await chest.abrir(player)
	assert(gs.inventario.obtener_cantidad("espada_corta") == 1)
	print("PASS Cofre entrega una espada corta, no entrega rata y no duplica al reabrir")
	quit()
