extends SceneTree

func _init() -> void:
	print("==================================================")
	print("INICIANDO PRUEBAS DEL SISTEMA DE ITEMS Y POOLS")
	print("==================================================")
	
	var passed = 0
	var failed = 0
	
	# Test 1: ItemDatabase
	print("\n--- Test 1: ItemDatabase auto-escaneo ---")
	var items = ItemDatabase.obtener_diccionario_items()
	print("Items detectados en res://data/items/: ", items.keys())
	if items.has("fragmento_ceramica") and items.has("queso_nordico") and items.has("llave_antigua"):
		print("[PASS] ItemDatabase detectó todos los items por defecto (.tres)")
		passed += 1
	else:
		print("[FAIL] Faltan items en ItemDatabase")
		failed += 1
		
	# Test 2: Propiedades de los Items
	print("\n--- Test 2: Propiedades de Items ---")
	var queso = ItemDatabase.obtener_item("queso_nordico")
	if queso and queso.nombre == "Queso Nórdico" and queso.categoria == InventoryItem.Categoria.CONSUMIBLE and queso.curacion_hp == 5:
		print("[PASS] Propiedades de queso_nordico.tres cargadas correctamente: ", queso.nombre, " Curación HP:", queso.curacion_hp)
		passed += 1
	else:
		print("[FAIL] Propiedades de queso_nordico no coinciden: ", queso)
		failed += 1
		
	# Test 3: ItemPool
	print("\n--- Test 3: ItemPool selección aleatoria ---")
	var pool: ItemPool = load("res://data/item_pools/pool_mundo_general.tres")
	if pool and pool.entradas.size() > 0:
		var conteos = {}
		for i in range(100):
			var elegido = pool.elegir_item()
			if elegido:
				conteos[elegido.id] = conteos.get(elegido.id, 0) + 1
		print("[PASS] ItemPool ejecutó 100 sorteos exitosamente. Resultados: ", conteos)
		passed += 1
	else:
		print("[FAIL] No se pudo cargar pool_mundo_general.tres")
		failed += 1
		
	# Test 4: GameState y agregar_item
	print("\n--- Test 4: GameState con Items .tres ---")
	var gs = load("res://scripts/core/game_state.gd").new()
	gs.name = "GameState"
	root.add_child(gs)
	gs._ready()
	print("DEBUG: Engine.get_main_loop() = ", Engine.get_main_loop())
	print("DEBUG: root.has_node('GameState') = ", root.has_node("GameState"))
	print("DEBUG: root children = ", root.get_children().map(func(n): return n.name))
	var cant_inicial_queso = gs.inventario.obtener_cantidad("queso_nordico")
	print("Cantidad inicial de queso en GameState: ", cant_inicial_queso)
	if cant_inicial_queso == 2:
		print("[PASS] GameState inicializó items desde recursos .tres")
		passed += 1
	else:
		print("[FAIL] Cantidad inicial inesperada: ", cant_inicial_queso)
		failed += 1
		
	gs.agregar_item("queso_nordico", 3)
	var nueva_cant_queso = gs.inventario.obtener_cantidad("queso_nordico")
	print("Nueva cantidad tras agregar 3 quesos: ", nueva_cant_queso)
	if nueva_cant_queso == 5:
		print("[PASS] gs.agregar_item funcionó correctamente")
		passed += 1
	else:
		print("[FAIL] Cantidad no sumó correctamente: ", nueva_cant_queso)
		failed += 1

	# Test 5: ItemPickup3D
	print("\n--- Test 5: ItemPickup3D recolección ---")
	var pickup_scene: PackedScene = load("res://scenes/world/Entities/ItemPickup.tscn")
	var pickup = pickup_scene.instantiate()
	pickup.item = queso
	pickup.cantidad = 2
	root.add_child(pickup)
	pickup._ready()
	
	# Simular recolección
	var dummy_player = CharacterBody3D.new()
	dummy_player.name = "Player"
	dummy_player.add_to_group("player")
	root.add_child(dummy_player)
	
	pickup.recoger(dummy_player)
	var cant_post_pickup = gs.inventario.obtener_cantidad("queso_nordico")
	print("Cantidad de queso tras recolectar ItemPickup3D (+2): ", cant_post_pickup)
	if cant_post_pickup == 7:
		print("[PASS] ItemPickup3D recogido y agregado al inventario de GameState")
		passed += 1
	else:
		print("[FAIL] ItemPickup3D no agregó los items esperados")
		failed += 1

	# Test 6: Pot drop logic
	print("\n--- Test 6: Pot con botín / drops ---")
	var pot_scene: PackedScene = load("res://scenes/world/Entities/Pot.tscn")
	var pot = pot_scene.instantiate()
	root.add_child(pot)
	pot._ready()
	pot.soltar_item_al_romper = true
	pot.item_garantizado = queso
	pot.cantidad_drop_garantizado = 1
	var hijos_antes = root.get_child_count()
	pot._destruir(pot.global_position)
	var hijos_despues = root.get_child_count()
	print("Hijos en root antes de romper jarrón: ", hijos_antes, ", después: ", hijos_despues)
	var pickup_encontrado = false
	for c in root.get_children():
		if c is ItemPickup3D:
			pickup_encontrado = true
			break
	if pickup_encontrado:
		print("[PASS] Pot soltó ItemPickup3D en el mundo al destruirse")
		passed += 1
	else:
		print("[FAIL] Pot no soltó el item pickup esperado")
		failed += 1

	# Test 7: EncuentroCombate recompensas
	print("\n--- Test 7: EncuentroCombate recompensas de items ---")
	var encuentro = EncuentroCombate.new()
	root.add_child(encuentro)
	encuentro._ready()
	encuentro.items_garantizados.append(queso)
	var cant_antes_combate = gs.inventario.obtener_cantidad("queso_nordico")
	encuentro._entregar_recompensas()
	var cant_despues_combate = gs.inventario.obtener_cantidad("queso_nordico")
	print("Cantidad antes de recompensa: ", cant_antes_combate, ", después: ", cant_despues_combate)
	if cant_despues_combate > cant_antes_combate:
		print("[PASS] EncuentroCombate entregó items de recompensa a GameState")
		passed += 1
	else:
		print("[FAIL] EncuentroCombate no entregó el item")
		failed += 1

	# Test 8: Chest recompensas
	print("\n--- Test 8: Chest recompensas de items ---")
	var chest_scene: PackedScene = load("res://scenes/world/Entities/Chest.tscn")
	var chest = chest_scene.instantiate()
	root.add_child(chest)
	chest._ready()
	chest.contiene_rata = false
	chest.item_recompensa = queso
	chest.cantidad_item = 2
	chest.soltar_como_pickup_3d = false
	var cant_antes_cofre = gs.inventario.obtener_cantidad("queso_nordico")
	chest._entregar_recompensas_cofre()
	var cant_despues_cofre = gs.inventario.obtener_cantidad("queso_nordico")
	print("Cantidad antes de cofre: ", cant_antes_cofre, ", después: ", cant_despues_cofre)
	if cant_despues_cofre == cant_antes_cofre + 2:
		print("[PASS] Chest entregó items correctamente a GameState")
		passed += 1
	else:
		print("[FAIL] Chest no entregó la cantidad esperada")
		failed += 1

	print("\n==================================================")
	print("RESULTADOS FINALES: PASARON %d / %d" % [passed, passed + failed])
	print("==================================================")
	
	quit(0 if failed == 0 else 1)
