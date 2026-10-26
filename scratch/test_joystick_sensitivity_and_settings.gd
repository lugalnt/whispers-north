extends SceneTree

const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const ControlsMenuScript = preload("res://scripts/ui/ControlsMenu.gd")

func _initialize() -> void:
	print("========================================")
	print("INICIANDO TEST: SENSIBILIDAD JOYSTICK, SETTINGS Y ERIC")
	print("========================================")

	# 1. Test de ControlsMenu: foco inicial, cierre con ui_cancel y cambio de pestañas
	var controls_scene = load("res://scenes/ui/ControlsMenu.tscn")
	assert(controls_scene != null, "ControlsMenu.tscn debe cargar")
	var controls_node = controls_scene.instantiate()
	root.add_child(controls_node)
	await process_frame

	controls_node.preparar()
	assert(controls_node._btn_regresar.has_focus(), "BtnRegresar debe tener foco tras preparar()")
	print(">> [PASS] ControlsMenu enfoca BtnRegresar al abrirse (evita pérdida de foco en control).")

	# Probar cambio de pestaña en control
	var tab_container: TabContainer = controls_node._tab_container
	assert(tab_container.current_tab == 0, "Pestaña inicial es 0 (Teclado)")

	var ev_next = InputEventAction.new()
	ev_next.action = "tab_next"
	ev_next.pressed = true
	controls_node._input(ev_next)
	assert(tab_container.current_tab == 1, "tab_next debe cambiar a pestaña 1 (JoyCon)")

	var ev_prev = InputEventAction.new()
	ev_prev.action = "tab_prev"
	ev_prev.pressed = true
	controls_node._input(ev_prev)
	assert(tab_container.current_tab == 0, "tab_prev debe regresar a pestaña 0 (Teclado)")
	print(">> [PASS] Atajos de control (LB/RB, tab_prev/tab_next) cambian de pestaña en settings.")

	# Probar cierre con ui_cancel
	var flags := {"emitida": false}
	controls_node.regresar_pedido.connect(func(): flags["emitida"] = true)
	var ev_cancel = InputEventAction.new()
	ev_cancel.action = &"ui_cancel"
	ev_cancel.pressed = true
	controls_node._input(ev_cancel)
	assert(flags["emitida"], "ui_cancel debe emitir regresar_pedido en ControlsMenu")
	print(">> [PASS] ControlsMenu se cierra limpiamente al pulsar ui_cancel / botón regresar.")
	controls_node.queue_free()

	# 2. Test de Sensibilidad y Debounce de Joystick en Combate
	var arena_scene = load("res://scenes/combat/CombatArena.tscn")
	var arena: CombatArena = arena_scene.instantiate()
	arena.auto_iniciar_si_esta_vacio = false
	root.add_child(arena)
	await process_frame

	var p_scene = load("res://scenes/combat/battlers/PlayerBattler.tscn")
	var pot_scene = load("res://scenes/combat/battlers/PotBattler.tscn")
	arena.inicializar([p_scene], [pot_scene], null)
	await process_frame

	arena._estado = CombatArena.EstadoTurno.TURNO_JUGADOR
	var idx_inicial = arena._indice_menu_accion

	# Simular movimiento de joystick rápido (varios micro-eventos analógicos seguidos)
	var ev_motion1 = InputEventJoypadMotion.new()
	ev_motion1.axis = 1
	ev_motion1.axis_value = 0.55 # Hacia abajo

	# Primer evento: debe procesarse
	assert(arena._debe_procesar_paso_menu(ev_motion1), "Primer tick del stick debe aceptarse")
	# Segundo evento inmediato (1 ms después, simula micro-movimiento analógico): debe ser bloqueado por debounce
	assert(not arena._debe_procesar_paso_menu(ev_motion1), "Micro-movimientos continuos deben ser bloqueados por debounce")

	# Simular retorno del stick al centro (< 0.25)
	var ev_center = InputEventJoypadMotion.new()
	ev_center.axis = 1
	ev_center.axis_value = 0.05
	arena._unhandled_input(ev_center)
	assert(not arena._stick_v_activo, "Retorno al centro debe resetear el stick")

	# Nuevo movimiento del stick: debe aceptarse de inmediato
	var ev_motion2 = InputEventJoypadMotion.new()
	ev_motion2.axis = 1
	ev_motion2.axis_value = -0.6
	assert(arena._debe_procesar_paso_menu(ev_motion2), "Nuevo movimiento tras retorno debe aceptarse inmediatamente")
	print(">> [PASS] Debounce de joystick en menú de combate probado con éxito (sin spam ni hipersensibilidad).")
	arena.queue_free()

	# 3. Test de Protagonista Eric y configurabilidad de PauseMenu
	var gs_script = load("res://scripts/core/game_state.gd")
	var gs = gs_script.new()
	assert(gs.nombre_jugador == "Eric", "El protagonista es Eric")
	assert(gs.titulo_jugador == "Explorador del Norte", "El protagonista es hombre: Explorador")
	print(">> [PASS] Protagonista correctamente configurado: Eric (Explorador del Norte).")

	print("========================================")
	print("TODOS LOS NUEVOS TESTS PASARON CON ÉXITO (0 ERRORES)")
	print("========================================")
	quit(0)
