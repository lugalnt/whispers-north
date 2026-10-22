extends SceneTree

var log_file: FileAccess

func _initialize() -> void:
	log_file = FileAccess.open("res://scratch/test_results.txt", FileAccess.WRITE)
	log_msg("=== INICIANDO TEST DE CORRECCIONES ===")
	_run_tests()

func log_msg(msg: String) -> void:
	print(msg)
	if log_file:
		log_file.store_line(msg)
		log_file.flush()

func _run_tests() -> void:
	var root_node = root
	
	# -------------------------------------------------------------
	# TEST 1: Estado y Persistencia de Salud (GameState + CombatArena + PauseMenu)
	# -------------------------------------------------------------
	log_msg("\n--- TEST 1: Persistencia de Salud ---")
	var gs_created_by_test: bool = false
	var gs = root_node.get_node_or_null("GameState")
	if gs == null:
		var gs_script = load("res://scripts/core/game_state.gd")
		gs = gs_script.new()
		gs.name = "GameState"
		root_node.add_child(gs)
		gs._ready()
		gs_created_by_test = true
	else:
		gs._inicializar_stats()
	
	assert(gs.hp_actual == 15, "HP inicial de GameState debe ser 15, fue: %d" % gs.hp_actual)
	log_msg("✔ HP inicial en GameState: %d / %d" % [gs.hp_actual, gs.stats.max_hp])
	
	# Instanciar CombatArena
	var arena_scene = load("res://scenes/combat/CombatArena.tscn")
	var arena: CombatArena = arena_scene.instantiate()
	arena.auto_iniciar_si_esta_vacio = false
	root_node.add_child(arena)
	
	await process_frame
	await process_frame
	
	var player_battler_scene = load("res://scenes/combat/battlers/PlayerBattler.tscn")
	var pot_battler_scene = load("res://scenes/combat/battlers/PotBattler.tscn")
	arena.inicializar([player_battler_scene], [pot_battler_scene], null)
	await process_frame
	
	var player_battler: Battler = arena.aliados[0]
	assert(player_battler.hp == 15, "Battler del jugador debe tener 15 HP al entrar")
	log_msg("✔ Battler del jugador inicializado con %d HP" % player_battler.hp)
	
	# Simular daño en combate
	player_battler.recibir_danio(6)
	assert(player_battler.hp == 9, "Battler del jugador debe tener 9 HP tras recibir 6 de daño")
	log_msg("✔ Battler recibió daño en combate: HP actual = %d" % player_battler.hp)
	
	# Simular salida del combate (Huida)
	arena._sincronizar_estado_global()
	assert(gs.hp_actual == 9, "GameState.hp_actual debe ser 9 tras sincronización, fue: %d" % gs.hp_actual)
	log_msg("✔ GameState sincronizó HP tras combate: %d / %d" % [gs.hp_actual, gs.stats.max_hp])
	
	# Probar PauseMenu reflejando esta salud
	var pause_scene = load("res://scenes/ui/PauseMenu.tscn")
	var pause_menu: PauseMenu = pause_scene.instantiate()
	root_node.add_child(pause_menu)
	await process_frame
	pause_menu._actualizar_vista_stats()
	
	assert(pause_menu.stats_barra_hp.value == 9, "Barra HP de PauseMenu debe mostrar 9")
	assert(pause_menu.stats_txt_hp.text == "9 / 15 HP", "Texto HP debe ser '9 / 15 HP', fue: " + pause_menu.stats_txt_hp.text)
	log_msg("✔ PauseMenu muestra vida correcta: " + pause_menu.stats_txt_hp.text)
	
	# Probar consumo de item curativo (Queso Nórdico +5 HP)
	var uso_ok = gs.usar_item("queso_nordico")
	assert(uso_ok, "Uso de queso_nordico debe ser exitoso")
	assert(gs.hp_actual == 14, "GameState.hp_actual debe ser 14 tras curar 5, fue: %d" % gs.hp_actual)
	pause_menu._actualizar_vista_stats()
	assert(pause_menu.stats_barra_hp.value == 14, "Barra HP debe ser 14 tras curar")
	assert(pause_menu.stats_txt_hp.text == "14 / 15 HP", "Texto HP debe ser '14 / 15 HP'")
	log_msg("✔ Consumir Queso Nórdico cura HP a: " + pause_menu.stats_txt_hp.text)
	
	# Probar que al entrar a un nuevo combate, el jugador conserva sus 14 HP
	var arena2: CombatArena = arena_scene.instantiate()
	arena2.auto_iniciar_si_esta_vacio = false
	root_node.add_child(arena2)
	await process_frame
	arena2.inicializar([player_battler_scene], [pot_battler_scene], null)
	await process_frame
	assert(arena2.aliados[0].hp == 14, "Al entrar al combate con 14 HP, el battler debe tener 14 HP")
	log_msg("✔ Nuevo combate inicia con la vida persistida del jugador: %d HP" % arena2.aliados[0].hp)
	arena2.queue_free()
	
	# -------------------------------------------------------------
	# TEST 2: Detección del Acompañante y Formato del Texto
	# -------------------------------------------------------------
	log_msg("\n--- TEST 2: Detección y Texto del Acompañante ---")
	# Caso A: Sin acompañante
	gs.tiene_rata = false
	pause_menu._actualizar_vista_stats()
	log_msg("Texto sin acompañante: " + pause_menu.stats_val_acompanante.text)
	assert(pause_menu.stats_val_acompanante.text == pause_menu.texto_companero_descanso, 
		"El texto debe ser exactamente texto_companero_descanso, fue: " + pause_menu.stats_val_acompanante.text)
	log_msg("✔ Texto sin acompañante coincide exactamente con texto_companero_descanso")
	
	# Caso B: Jugador con rata en el árbol
	var dummy_player = CharacterBody3D.new()
	dummy_player.name = "Player"
	root_node.add_child(dummy_player)
	
	var rat_node = Node3D.new()
	rat_node.name = "Rat"
	rat_node.add_to_group("rat")
	dummy_player.add_child(rat_node)
	
	# Debe detectarla automáticamente
	var detectado = pause_menu._detectar_companero()
	assert(detectado, "Debe detectar a la rata anclada al jugador")
	assert(gs.tiene_rata, "GameState.tiene_rata debe actualizarse a true")
	
	pause_menu._actualizar_vista_stats()
	log_msg("Texto con acompañante detectado: " + pause_menu.stats_val_acompanante.text)
	assert(pause_menu.stats_val_acompanante.text == pause_menu.texto_companero_activo,
		"El texto debe ser exactamente texto_companero_activo, fue: " + pause_menu.stats_val_acompanante.text)
	log_msg("✔ Texto con acompañante coincide exactamente con texto_companero_activo")
	
	# -------------------------------------------------------------
	# TEST 3: Navegación de Combate con Joystick (Pelear vs Huir)
	# -------------------------------------------------------------
	log_msg("\n--- TEST 3: Navegación de Opciones en Combate con Joystick ---")
	arena._crear_botones_acciones(player_battler)
	assert(arena._opciones_menu.size() == 2, "Debe haber 2 opciones (Golpear y Huir)")
	assert(arena._botones_menu.size() == 2, "Debe haber 2 botones")
	
	# Verificar que los botones no tengan focus_mode = FOCUS_ALL para no duplicar saltos
	for btn in arena._botones_menu:
		assert(btn.focus_mode == Control.FOCUS_NONE, "Los botones de combate deben tener FOCUS_NONE")
	log_msg("✔ Todos los botones tienen FOCUS_NONE (sin interferencia de Godot GUI focus)")
	
	arena._estado = CombatArena.EstadoTurno.TURNO_JUGADOR
	arena._indice_menu_accion = 0
	arena._actualizar_resaltado_menu()
	assert(arena._indice_menu_accion == 0, "Opción inicial debe ser 0 (Golpear)")
	assert(arena._botones_menu[0].text.begins_with("▶"), "Botón 0 debe tener selector ▶")
	
	# Simular movimiento del stick hacia abajo (Axis 1, value 0.8)
	var ev_down = InputEventJoypadMotion.new()
	ev_down.axis = JOY_AXIS_LEFT_Y
	ev_down.axis_value = 0.8
	arena._unhandled_input(ev_down)
	
	assert(arena._indice_menu_accion == 1, "Tras mover stick hacia abajo, debe ser 1 (Huir), fue: %d" % arena._indice_menu_accion)
	assert(arena._botones_menu[1].text.begins_with("▶"), "Botón 1 (Huir) debe tener selector ▶")
	log_msg("✔ Movimiento hacia abajo seleccionó correctamente la opción 1 (Huir)")
	
	# Simular deriva en eje horizontal (Axis 0, value 0.1)
	var ev_drift = InputEventJoypadMotion.new()
	ev_drift.axis = JOY_AXIS_LEFT_X
	ev_drift.axis_value = 0.1
	arena._unhandled_input(ev_drift)
	
	# Simular continuación del empuje vertical
	var ev_down_continue = InputEventJoypadMotion.new()
	ev_down_continue.axis = JOY_AXIS_LEFT_Y
	ev_down_continue.axis_value = 0.85
	arena._unhandled_input(ev_down_continue)
	
	assert(arena._indice_menu_accion == 1, "No debe duplicar el paso ni resetear a 0 por deriva horizontal. Indice = %d" % arena._indice_menu_accion)
	log_msg("✔ Deriva horizontal no causó doble salto; se mantiene en opción 1 (Huir)")
	
	# Simular soltar el stick (Axis 1 retorna a 0)
	var ev_release = InputEventJoypadMotion.new()
	ev_release.axis = JOY_AXIS_LEFT_Y
	ev_release.axis_value = 0.05
	arena._unhandled_input(ev_release)
	
	# Simular stick hacia arriba (Axis 1, value -0.8)
	var ev_up = InputEventJoypadMotion.new()
	ev_up.axis = JOY_AXIS_LEFT_Y
	ev_up.axis_value = -0.8
	arena._unhandled_input(ev_up)
	
	assert(arena._indice_menu_accion == 0, "Tras mover stick hacia arriba, debe ser 0 (Golpear), fue: %d" % arena._indice_menu_accion)
	log_msg("✔ Movimiento hacia arriba seleccionó correctamente la opción 0 (Golpear)")
	
	# Volver a mover a Huir y confirmar
	arena._unhandled_input(ev_release)
	arena._unhandled_input(ev_down)
	assert(arena._indice_menu_accion == 1, "Debe estar en 1 (Huir)")
	
	var ev_interact = InputEventAction.new()
	ev_interact.action = "interact"
	ev_interact.pressed = true
	arena._unhandled_input(ev_interact)
	assert(arena._seleccion_menu_resultado == "huir", "Confirmación debe seleccionar 'huir'")
	log_msg("✔ Confirmación con botón interact/A selecciona correctamente 'huir'")
	
	# Limpieza
	arena.queue_free()
	pause_menu.queue_free()
	dummy_player.queue_free()
	if gs_created_by_test:
		gs.queue_free()
	
	log_msg("\n=== TODOS LOS TESTS PASARON CON ÉXITO (3/3) ===")
	quit(0)
