extends SceneTree

const InventoryItemScript = preload("res://scripts/inventory/inventory_item.gd")
const InventoryScript = preload("res://scripts/inventory/inventory.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")

func _initialize() -> void:
	print("========================================")
	print("INICIANDO TEST: PAUSE MENU, INVENTARIO Y STATS")
	print("========================================")
	
	# 1. Probar Input Map: acción 'pause'
	assert(InputMap.has_action("pause"), "El InputMap debe tener registrada la accion 'pause'")
	print(">> [PASS] Accion 'pause' registrada en project.godot e InputMap.")
	
	# 2. Probar InventoryItem
	var item_test = InventoryItemScript.new()
	item_test.id = "test_item"
	item_test.nombre = "Amuleto Nórdico"
	item_test.descripcion = "Un amuleto mágico protector."
	item_test.categoria = InventoryItemScript.Categoria.CLAVE
	assert(item_test.obtener_nombre_categoria() == "Objeto Clave", "Categoria debe ser Objeto Clave")
	print(">> [PASS] InventoryItem funciona correctamente.")
	
	# 3. Probar Inventory
	var inv = InventoryScript.new()
	assert(inv.esta_vacio(), "El inventario debe empezar vacio")
	inv.agregar(item_test, 2)
	assert(inv.obtener_cantidad("test_item") == 2, "Debe tener 2 unidades")
	inv.agregar(item_test, 3)
	assert(inv.obtener_cantidad("test_item") == 5, "Debe tener 5 unidades")
	var quitado = inv.quitar("test_item", 1)
	assert(quitado and inv.obtener_cantidad("test_item") == 4, "Debe tener 4 tras quitar 1")
	print(">> [PASS] Inventory reactivo (add/remove/count) funciona correctamente.")
	
	# 4. Probar GameState Autoload
	var gs = null
	if Engine.has_singleton("GameState"):
		gs = Engine.get_singleton("GameState")
	elif root.has_node("GameState"):
		gs = root.get_node("GameState")
	else:
		var gs_script = load("res://scripts/core/game_state.gd")
		gs = gs_script.new()
		gs.name = "GameState"
		root.add_child(gs)
	
	assert(gs != null, "GameState debe estar disponible")
	assert(gs.inventario != null, "GameState debe tener inventario")
	assert(gs.nivel == 1, "Nivel inicial 1")
	assert(gs.nombre_jugador == "Eric", "Nombre del jugador Eric")
	
	# Probar EXP
	var exp_previa = gs.exp_actual
	gs.agregar_exp(20)
	assert(gs.exp_actual == exp_previa + 20, "Debe haber sumado 20 EXP")
	print(">> [PASS] GameState (nivel, exp, stats, Eric) funciona correctamente.")
	
	# 5. Probar acciones tab_prev y tab_next
	assert(InputMap.has_action("tab_prev"), "Debe existir accion tab_prev")
	assert(InputMap.has_action("tab_next"), "Debe existir accion tab_next")
	print(">> [PASS] Acciones tab_prev y tab_next registradas en InputMap.")
	
	# 6. Probar PauseMenu.tscn y configurabilidad
	var pause_scene = load("res://scenes/ui/PauseMenu.tscn")
	assert(pause_scene != null, "PauseMenu.tscn debe cargar")
	var menu: PauseMenu = pause_scene.instantiate() as PauseMenu
	assert(menu != null, "PauseMenu debe instanciarse")
	
	# Test de configurabilidad desde inspector
	menu.texto_btn_reanudar = "Continuar Travesía"
	menu.texto_tab_inventario = "Mochila"
	root.add_child(menu)
	await process_frame
	
	assert(menu.btn_reanudar.text == "Continuar Travesía", "Configuracion exportada aplicada al boton reanudar")
	assert(menu.btn_tab_inventario.text == "Mochila", "Configuracion exportada aplicada a pestana")
	print(">> [PASS] Configurabilidad sencilla por nodo principal comprobada con exito.")
	
	# Verificar estado inicial oculto
	assert(not menu.visible, "El menu debe empezar invisible")
	assert(not paused, "El arbol no debe estar pausado inicialmente")
	
	# Abrir menú
	menu.abrir_menu()
	assert(menu.visible, "El menu debe ser visible tras abrir_menu")
	assert(paused, "El juego debe pausarse al abrir el menu")
	
	# Verificar pestañas
	menu.cambiar_pestana(PauseMenuScript.Pestana.INVENTARIO)
	assert(menu.vista_inventario.visible, "Vista de inventario visible")
	assert(not menu.vista_stats.visible, "Vista de stats oculta")
	
	menu.cambiar_pestana(PauseMenuScript.Pestana.STATS)
	assert(menu.vista_stats.visible, "Vista de stats visible")
	assert(not menu.vista_inventario.visible, "Vista de inventario oculta")
	assert(menu.stats_nombre.text == "Eric", "Nombre en stats es Eric")
	
	menu.cambiar_pestana(PauseMenuScript.Pestana.SISTEMA)
	assert(menu.vista_sistema.visible, "Vista de sistema visible")
	
	# Probar apertura y cierre del subpanel de controles dentro de PauseMenu
	menu._abrir_menu_controles()
	assert(menu._panel_controles_activo != null, "Panel de controles instanciado dentro de PauseMenu")
	menu._cerrar_menu_controles()
	assert(menu._panel_controles_activo == null, "Panel de controles cerrado correctamente sin atascarse")
	print(">> [PASS] Subpanel de controles se abre y se cierra correctamente.")
	
	# Cerrar menú
	menu.cerrar_menu()
	assert(not menu.visible, "El menu debe estar invisible tras cerrar_menu")
	assert(not paused, "El juego debe reanudarse al cerrar el menu")
	print(">> [PASS] PauseMenu (apertura, pausa del juego, navegacion de pestañas y cierre) probado con exito.")
	
	menu.queue_free()
	
	print("========================================")
	print("TODOS LOS TESTS DE PAUSE MENU PASARON CON EXITO (0 ERRORES)")
	print("========================================")
	quit(0)
