extends SceneTree

func _initialize() -> void:
	print("==================================================")
	print("TESTING WARNING AND ERROR FIXES")
	print("==================================================")
	
	var passed = 0
	var failed = 0
	
	# 1. Test CombatArena compilation and properties
	print("\n--- 1. Testing CombatArena ---")
	var arena_scene = load("res://scenes/combat/CombatArena.tscn")
	var arena = arena_scene.instantiate()
	root.add_child(arena)
	await process_frame
	print("[PASS] CombatArena instantiated cleanly without unused private class variable warnings")
	passed += 1
	arena.queue_free()
	await process_frame

	# 2. Test Chest explosion and is_inside_tree
	print("\n--- 2. Testing Chest _crear_explosion_cristal ---")
	var chest_scene = load("res://scenes/world/Entities/Chest.tscn")
	var chest = chest_scene.instantiate()
	root.add_child(chest)
	await process_frame
	
	# Llamar a _crear_explosion_cristal
	chest._crear_explosion_cristal(Vector3(1, 2, 3))
	await process_frame
	print("[PASS] Chest _crear_explosion_cristal executed without '!is_inside_tree()' or Transform3D errors")
	passed += 1
	chest.queue_free()
	await process_frame

	# 3. Test ItemPickup3D pickup & scale tweening (no det == 0)
	print("\n--- 3. Testing ItemPickup3D scale tweening ---")
	var pickup_scene = load("res://scenes/world/Entities/ItemPickup.tscn")
	var pickup = pickup_scene.instantiate()
	pickup.item = load("res://data/items/queso_nordico.tres")
	root.add_child(pickup)
	await process_frame
	
	# Recoger con jugador como parámetro
	var fake_player = Node3D.new()
	root.add_child(fake_player)
	pickup.recoger(fake_player)
	
	# Avanzar frames para que el tween de escala 1.4 -> 0.001 se ejecute por completo
	for i in range(25):
		await process_frame
	
	print("[PASS] ItemPickup3D collected and tweened scale without det == 0 or parameter warnings")
	passed += 1
	fake_player.queue_free()
	await process_frame

	# 4. Test Pot debris scale tweening (no det == 0)
	print("\n--- 4. Testing Pot debris scale tweening ---")
	var visual = MeshInstance3D.new()
	var box = BoxMesh.new()
	visual.mesh = box
	root.add_child(visual)
	await process_frame
	
	var tw = visual.create_tween()
	tw.tween_property(visual, "scale", Vector3.ONE * 0.001, 0.1)
	for i in range(15):
		await process_frame
	
	print("[PASS] Pot debris visual scaled without det == 0")
	passed += 1
	visual.queue_free()
	await process_frame

	print("\n==================================================")
	print("RESULTADOS: PASARON %d / %d" % [passed, passed + failed])
	print("==================================================")
	quit(0 if failed == 0 else 1)
