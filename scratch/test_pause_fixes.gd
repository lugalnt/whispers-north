extends SceneTree

func _initialize() -> void:
	print("==================================================")
	print("INICIANDO PRUEBAS DE FIXES DEL MENÚ DE PAUSA")
	print("==================================================")
	
	var passed = 0
	var failed = 0
	
	# Usar el autoload real GameState
	var gs = root.get_node_or_null("GameState")
	if gs == null:
		print("Creando GameState...")
		var GS_script = load("res://scripts/core/game_state.gd")
		gs = GS_script.new()
		gs.name = "GameState"
		root.add_child(gs)
	
	await process_frame
	await process_frame
	
	# TEST 1: Etiquetas de título respetan configuración en nodo principal
	print("\n--- TEST 1: Configuración de título en nodo principal ---")
	var pause_scene = load("res://scenes/ui/PauseMenu.tscn")
	var menu: PauseMenu = pause_scene.instantiate() as PauseMenu
	
	# Personalizar textos en el nodo principal (Inspector)
	menu.texto_titulo_menu = "AVENTURA DEL NORTE"
	menu.texto_titulo_perfil = "El Fuki"
	root.add_child(menu)
	
	await process_frame
	menu.abrir_menu()
	await process_frame
	
	# Verificar que el header respeta texto_titulo_menu
	print("Header Titulo actual: ", menu.lbl_header_titulo.text)
	if menu.lbl_header_titulo.text == "AVENTURA DEL NORTE":
		print("[PASS] lbl_header_titulo respeta texto_titulo_menu configurado en nodo principal")
		passed += 1
	else:
		print("[FAIL] lbl_header_titulo no tiene el texto esperado: ", menu.lbl_header_titulo.text)
		failed += 1
		
	# Cambiar a pestaña de Stats y verificar que stats_titulo muestra "El Fuki" y no es sobreescrito por GameState
	menu.cambiar_pestana(PauseMenu.Pestana.STATS)
	await process_frame
	print("Stats Titulo Perfil actual: ", menu.stats_titulo.text)
	if menu.stats_titulo.text == "El Fuki":
		print("[PASS] stats_titulo respeta texto_titulo_perfil ('El Fuki') configurado en nodo principal")
		passed += 1
	else:
		print("[FAIL] stats_titulo fue sobreescrito: ", menu.stats_titulo.text)
		failed += 1

	# TEST 2: Consumir consumibles seleccionando e interactuando de nuevo
	print("\n--- TEST 2: Consumo de consumibles al interactuar de nuevo ---")
	menu.cambiar_pestana(PauseMenu.Pestana.INVENTARIO)
	await process_frame
	
	# Asegurar que Eric tiene daño para comprobar curación
	gs.actualizar_hp(5)
	print("HP de Eric antes de consumir: ", gs.hp_actual, " / ", gs.stats.max_hp)
	
	# Asegurar que el queso está en el inventario con 2 unidades
	var queso = ItemDatabase.obtener_item("queso_nordico")
	if queso == null:
		queso = load("res://data/items/queso_nordico.tres")
	
	# Dejar solo queso_nordico para probar con claridad
	gs.inventario.items.clear()
	gs.inventario.agregar(queso, 2)
	menu._actualizar_vista_inventario()
	await process_frame
	
	var cant_inicial_queso = gs.inventario.obtener_cantidad("queso_nordico")
	print("Cantidad inicial de queso: ", cant_inicial_queso)
	print("Slots en cuadrícula: ", menu._botones_slots.size())
	
	if menu._botones_slots.is_empty():
		print("[FAIL] No hay botones de slots en el inventario")
		failed += 1
	else:
		# Slot 0 es ahora queso_nordico
		var slot_queso = menu._botones_slots[0]
		slot_queso.emit_signal("focus_entered")
		print("Item seleccionado tras focus: ", menu._item_seleccionado_id)
		
		# Segunda interacción: presionar el slot directamente (slot_btn.pressed)
		slot_queso.emit_signal("pressed")
		await process_frame
		
		var hp_despues_primer_consumo = gs.hp_actual
		var cant_despues_primer_consumo = gs.inventario.obtener_cantidad("queso_nordico")
		print("HP tras primer consumo: ", hp_despues_primer_consumo, " (esperado 10)")
		print("Cantidad de queso restante: ", cant_despues_primer_consumo, " (esperado 1)")
		
		if hp_despues_primer_consumo == 10 and cant_despues_primer_consumo == 1:
			print("[PASS] Ítem consumido exitosamente al presionar el slot seleccionado")
			passed += 1
		else:
			print("[FAIL] No se consumió correctamente: HP=%d, Cant=%d" % [hp_despues_primer_consumo, cant_despues_primer_consumo])
			failed += 1

	# TEST 3: Retención de foco tras consumo
	print("\n--- TEST 3: Retención de foco tras consumir ---")
	if menu._indice_slot_enfocado == 0 and not menu._botones_slots.is_empty():
		print("[PASS] El índice de foco se mantuvo correctamente en el slot activo")
		passed += 1
	else:
		print("[FAIL] El foco se perdió tras consumir")
		failed += 1

	# TEST 4: Consumir mediante acción 'interact' en _unhandled_input
	print("\n--- TEST 4: Consumo mediante acción 'interact' ---")
	if not menu._botones_slots.is_empty():
		var ev = InputEventAction.new()
		ev.action = "interact"
		ev.pressed = true
		
		menu._botones_slots[0].grab_focus()
		menu._unhandled_input(ev)
		await process_frame
		
		var hp_despues_segundo_consumo = gs.hp_actual
		var cant_despues_segundo_consumo = gs.inventario.obtener_cantidad("queso_nordico")
		print("HP tras segundo consumo (interact): ", hp_despues_segundo_consumo, " (esperado 15)")
		print("Cantidad de queso restante: ", cant_despues_segundo_consumo, " (esperado 0)")
		
		if hp_despues_segundo_consumo == 15 and cant_despues_segundo_consumo == 0:
			print("[PASS] Ítem consumido exitosamente con la acción 'interact'")
			passed += 1
		else:
			print("[FAIL] Falló el consumo con acción 'interact': HP=%d, Cant=%d" % [hp_despues_segundo_consumo, cant_despues_segundo_consumo])
			failed += 1

	print("\n==================================================")
	print("RESULTADOS FINALES: PASARON %d / %d" % [passed, passed + failed])
	print("==================================================")
	
	quit(0 if failed == 0 else 1)
