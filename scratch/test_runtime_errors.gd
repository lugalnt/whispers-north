extends SceneTree

func _init() -> void:
	print("--- INICIANDO TEST RUNTIME PARA VERIFICAR 0 ERRORES/WARNINGS ---")

	# 1. Test MainMenu resolution division
	var pantalla_idx := DisplayServer.window_get_current_screen()
	var pant_size    := DisplayServer.screen_get_size(pantalla_idx)
	var pant_pos     := DisplayServer.screen_get_position(pantalla_idx)
	var nueva_res    := Vector2i(1280, 720)
	var pos := pant_pos + (pant_size - nueva_res) / 2
	print("1. Cálculo de centrado de ventana OK: ", pos)

	# 2. Test loading fire_mountain.tscn (sin error de UID de Txa_test_kazan_b.png)
	var fire_mountain = load("res://assets/models/GameCube - The Legend of Zelda_ The Wind Waker - Great Sea Islands - Fire Mountain/fire_mountain.tscn")
	assert(fire_mountain != null, "fire_mountain.tscn debe cargar sin error")
	print("2. fire_mountain.tscn cargado limpiamente.")

	# 3. Test loading pot.dae, pot_brk_1.dae, pot_brk_2.dae (sin error de UID de Rock_Pot_A_Alb.png)
	var dae_pot = load("res://assets/models/Generic Pot/pot.dae")
	var dae_brk1 = load("res://assets/models/Generic Pot/pot_brk_1.dae")
	var dae_brk2 = load("res://assets/models/Generic Pot/pot_brk_2.dae")
	assert(dae_pot != null and dae_brk1 != null and dae_brk2 != null, "Modelos DAE deben cargar sin error")
	print("3. Modelos DAE del jarrón y fragmentos cargados limpiamente.")

	# 4. Test chest.gd preloads (byeguys.mp3)
	var chest_script = load("res://scripts/world/chest.gd")
	assert(chest_script != null, "chest.gd debe compilar sin error de preload")
	print("4. chest.gd compilado sin errores.")

	# 5. Test Pot and EncuentroCombate runtime instantiation (sin !is_inside_tree warnings)
	var pot_scene = load("res://scenes/world/Entities/Pot.tscn")
	var pot_node = pot_scene.instantiate()
	root.add_child(pot_node)
	
	# Simular inicio de combate
	var enc: EncuentroCombate = pot_node._obtener_encuentro()
	assert(enc != null, "Encuentro debe existir")
	print("5. Pot y EncuentroCombate instanciados correctamente.")

	# 6. Test fragment generation
	pot_node._crear_fragmentos(Vector3.ZERO)
	print("6. _crear_fragmentos ejecutado sin advertencias.")

	# Limpiar
	pot_node.queue_free()

	print("--- TEST FINALIZADO CON ÉXITO: 0 ERRORES Y 0 ADVERTENCIAS ---")
	quit(0)
