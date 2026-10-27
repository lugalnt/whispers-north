extends SceneTree

const ControlsMenuScript = preload("res://scripts/ui/ControlsMenu.gd")
const ControlsRemapScript = preload("res://addons/ControlsRemap/ControlsRemap.gd")

func _initialize() -> void:
	print("==================================================")
	print("TEST DE COMPATIBILIDAD CON CONTROL DE PS5 (DualSense)")
	print("==================================================")

	var controls_scene = load("res://scenes/ui/ControlsMenu.tscn")
	assert(controls_scene != null, "ControlsMenu.tscn debe cargar")
	var menu: Control = controls_scene.instantiate()
	root.add_child(menu)
	await process_frame

	menu.preparar()

	# 1. Verificar nomenclatura oficial de PS5 en NOMBRES_JOYBUTTON
	print("\n--- 1. Verificación de Nomenclatura PS5 ---")
	var dict_nombres: Dictionary = menu.NOMBRES_JOYBUTTON
	assert(dict_nombres[JOY_BUTTON_A].contains("Cruz"), "Botón 0 debe indicar Cruz para PS5")
	assert(dict_nombres[JOY_BUTTON_B].contains("Círculo"), "Botón 1 debe indicar Círculo para PS5")
	assert(dict_nombres[JOY_BUTTON_X].contains("Cuadrado"), "Botón 2 debe indicar Cuadrado para PS5")
	assert(dict_nombres[JOY_BUTTON_Y].contains("Triángulo"), "Botón 3 debe indicar Triángulo para PS5")
	assert(dict_nombres[JOY_BUTTON_BACK].contains("Create"), "Botón 4 debe indicar Create (botón compartir PS5)")
	assert(dict_nombres[JOY_BUTTON_START].contains("Options"), "Botón 6 debe indicar Options (botón pausa PS5)")
	assert(dict_nombres[JOY_BUTTON_LEFT_SHOULDER].begins_with("L1"), "Botón 9 debe ser L1")
	assert(dict_nombres[JOY_BUTTON_RIGHT_SHOULDER].begins_with("R1"), "Botón 10 debe ser R1")
	assert(dict_nombres[JOY_BUTTON_DPAD_UP] == "D-Pad ↑", "Botón 11 debe ser D-Pad ↑")
	assert(dict_nombres[JOY_BUTTON_DPAD_DOWN] == "D-Pad ↓", "Botón 12 debe ser D-Pad ↓")
	assert(dict_nombres[JOY_BUTTON_DPAD_LEFT] == "D-Pad ←", "Botón 13 debe ser D-Pad ←")
	assert(dict_nombres[JOY_BUTTON_DPAD_RIGHT] == "D-Pad →", "Botón 14 debe ser D-Pad →")
	assert(dict_nombres[JOY_BUTTON_TOUCHPAD] == "Touchpad", "Botón 20 debe ser Touchpad de PS5")
	print(">> [PASS] Botonera completa de PS5 correctamente mapeada y etiquetada.")

	# 2. Verificar Gatillos L2/R2 y Sticks Analógicos en _obtener_nombre_joypad_motion
	print("\n--- 2. Verificación de Gatillos y Sticks PS5 ---")
	assert(menu._obtener_nombre_joypad_motion(JOY_AXIS_TRIGGER_LEFT, 0.8).begins_with("L2"), "Eje 4 debe ser gatillo L2")
	assert(menu._obtener_nombre_joypad_motion(JOY_AXIS_TRIGGER_RIGHT, 0.8).begins_with("R2"), "Eje 5 debe ser gatillo R2")
	assert(menu._obtener_nombre_joypad_motion(JOY_AXIS_LEFT_Y, -0.9) == "Stick Izq. ↑", "Stick Izq Y negativo es arriba")
	assert(menu._obtener_nombre_joypad_motion(JOY_AXIS_LEFT_Y, 0.9) == "Stick Izq. ↓", "Stick Izq Y positivo es abajo")
	assert(menu._obtener_nombre_joypad_motion(JOY_AXIS_LEFT_X, -0.9) == "Stick Izq. ←", "Stick Izq X negativo es izquierda")
	assert(menu._obtener_nombre_joypad_motion(JOY_AXIS_LEFT_X, 0.9) == "Stick Izq. →", "Stick Izq X positivo es derecha")
	print(">> [PASS] Gatillos adaptativos L2/R2 y sticks del DualSense correctamente reconocidos.")

	# 3. Test de reasignación con botón Círculo (no debe cancelarse con ui_cancel)
	print("\n--- 3. Reasignación con Círculo (PS5) ---")
	var btn_interact: Button = menu.get_node("PanelFondo/VBox/TabContainer/JoyCon/ListaJoycon/Fila_interact_joypad/Btn_interact_joypad")
	btn_interact.pressed.emit()
	assert(menu._escuchando, "Menú debe estar en modo escucha")

	# Simular pulsación de botón Círculo (índice 1) en control PS5
	var ev_circulo := InputEventJoypadButton.new()
	ev_circulo.button_index = JOY_BUTTON_B
	ev_circulo.pressed = true
	menu._input(ev_circulo)

	assert(not menu._escuchando, "Modo escucha debe finalizar tras presionar Círculo")
	var badge_interact: Panel = menu.get_node("PanelFondo/VBox/TabContainer/JoyCon/ListaJoycon/Fila_interact_joypad/Badge_interact_joypad")
	var lbl_interact: Label = badge_interact.get_node("LblBadge")
	assert(lbl_interact.text.contains("Círculo"), "Badge debe mostrar Círculo y no haberse cancelado")
	print(">> [PASS] Botón Círculo de PS5 se asigna correctamente sin ser bloqueado por ui_cancel.")

	# 4. Test de reasignación con Stick Analógico del DualSense
	print("\n--- 4. Reasignación con Stick Analógico de PS5 ---")
	var btn_up: Button = menu.get_node("PanelFondo/VBox/TabContainer/JoyCon/ListaJoycon/Fila_move_up_joypad/Btn_move_up_joypad")
	btn_up.pressed.emit()
	assert(menu._escuchando, "Menú debe estar en modo escucha para move_up")

	# Deriva leve (deadzone < 0.5): debe ser ignorada
	var ev_drift := InputEventJoypadMotion.new()
	ev_drift.axis = JOY_AXIS_LEFT_Y
	ev_drift.axis_value = -0.15
	menu._input(ev_drift)
	assert(menu._escuchando, "Deriva leve del stick (<0.5) no debe cancelar ni asignar")

	# Empuje intencional hacia arriba (-0.85): debe asignarse
	var ev_stick_up := InputEventJoypadMotion.new()
	ev_stick_up.axis = JOY_AXIS_LEFT_Y
	ev_stick_up.axis_value = -0.85
	menu._input(ev_stick_up)

	assert(not menu._escuchando, "Modo escucha debe finalizar tras empujar el stick")
	var badge_up: Panel = menu.get_node("PanelFondo/VBox/TabContainer/JoyCon/ListaJoycon/Fila_move_up_joypad/Badge_move_up_joypad")
	var lbl_up: Label = badge_up.get_node("LblBadge")
	assert(lbl_up.text == "Stick Izq. ↑", "Badge debe mostrar 'Stick Izq. ↑'")
	print(">> [PASS] Stick analógico del control de PS5 se asigna e identifica correctamente.")

	# 5. Test de cancelación con botón Create (Share) de PS5
	print("\n--- 5. Cancelación con botón Create (PS5) ---")
	btn_up.pressed.emit()
	assert(menu._escuchando, "Modo escucha activado")
	var ev_create := InputEventJoypadButton.new()
	ev_create.button_index = JOY_BUTTON_BACK
	ev_create.pressed = true
	menu._input(ev_create)
	assert(not menu._escuchando, "Botón Create debe cancelar limpiamente la escucha")
	print(">> [PASS] Botón Create (PS5) cancela la escucha correctamente.")

	# 6. Test de restauración a valores por defecto
	print("\n--- 6. Restauración de Defaults ---")
	menu._on_restablecer()
	lbl_interact = badge_interact.get_node("LblBadge")
	assert(lbl_interact.text.contains("Cruz"), "Interact debe volver a Cruz (✕) / A")
	print(">> [PASS] Restauración devuelve el control de PS5 a su configuración predeterminada limpia.")

	menu.queue_free()

	print("\n==================================================")
	print("TODAS LAS VERIFICACIONES DE PS5 PASARON CON ÉXITO")
	print("==================================================")
	quit(0)
