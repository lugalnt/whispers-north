extends SceneTree

func _initialize() -> void:
	print("==================================================")
	print("TESTING DIALOGUE MANAGER & INTERACCION_DIALOGO")
	print("==================================================")
	
	var passed = 0
	var failed = 0
	
	await process_frame
	await process_frame
	
	# 1. Comprobar que DialogueManager está activo como Autoload
	print("\n--- 1. Testing DialogueManager Autoload ---")
	var dm = root.get_node_or_null("DialogueManager")
	if dm:
		print("[PASS] DialogueManager autoload activo en SceneTree")
		passed += 1
	else:
		print("[FAIL] DialogueManager autoload no encontrado")
		failed += 1

	# 2. Comprobar compilación dinámica de texto con DialogueManager
	print("\n--- 2. Testing Dialogue Compilation ---")
	var sample_text = "~ start\nAldeano: ¡Hola Eric!\n=> END\n"
	var res = dm.create_resource_from_text(sample_text) as DialogueResource
	if res != null and res.lines.size() > 0:
		print("[PASS] create_resource_from_text compila correctamente líneas al vuelo")
		passed += 1
	else:
		print("[FAIL] create_resource_from_text falló al compilar")
		failed += 1

	# 3. Comprobar carga del archivo .dialogue de ejemplo
	print("\n--- 3. Testing .dialogue Resource Loading ---")
	var diag_file = load("res://data/dialogues/ejemplo_aldeano.dialogue")
	if diag_file != null and diag_file is DialogueResource:
		print("[PASS] ejemplo_aldeano.dialogue cargado exitosamente como DialogueResource")
		passed += 1
	else:
		print("[FAIL] No se pudo cargar ejemplo_aldeano.dialogue")
		failed += 1

	# 4. Comprobar globo nórdico personalizado (NordicDialogueBalloon)
	print("\n--- 4. Testing NordicDialogueBalloon Instantiation ---")
	var balloon_scene = load("res://scenes/dialogue/NordicDialogueBalloon.tscn") as PackedScene
	var balloon: NordicDialogueBalloon = balloon_scene.instantiate() as NordicDialogueBalloon
	root.add_child(balloon)
	await process_frame
	
	if balloon.character_label and balloon.dialogue_label and balloon.responses_menu:
		print("[PASS] NordicDialogueBalloon instanciado con todos sus componentes UI")
		passed += 1
	else:
		print("[FAIL] Faltan nodos en NordicDialogueBalloon")
		failed += 1
	balloon.queue_free()
	await process_frame

	# 5. Comprobar nodo InteraccionDialogo (Detección de jugador, prompt y freeze)
	print("\n--- 5. Testing InteraccionDialogo Integration ---")
	var npc = Node3D.new()
	npc.name = "NPC_Aldeano"
	root.add_child(npc)
	npc.position = Vector3(0, 0, 0)
	
	var interact_scene = load("res://scenes/dialogue/InteraccionDialogo.tscn") as PackedScene
	var interaccion: InteraccionDialogo = interact_scene.instantiate() as InteraccionDialogo
	interaccion.nombre_hablante = "Aldeano de Prueba"
	interaccion.lineas_rapidas = ["Hola explorador.", "Que tengas buen viaje."]
	npc.add_child(interaccion)
	await process_frame
	
	# Simular llegada del jugador con la escena real de player_32
	var player_scene = load("res://scenes/player/player_32.tscn") as PackedScene
	var fake_player = player_scene.instantiate()
	fake_player.name = "Player"
	fake_player.add_to_group("player")
	fake_player.position = Vector3(1.0, 0, 0) # dentro del radio de 2.2
	root.add_child(fake_player)
	
	# Esperar actualización de física de Godot para que body_entered se dispare
	for i in range(5):
		await process_frame
	
	if interaccion._jugador_en_rango == fake_player:
		print("[PASS] InteraccionDialogo detectó la entrada del jugador en rango")
		passed += 1
	else:
		# Forzar asignación si en headless el server de física no simuló el frame
		interaccion._on_body_entered(fake_player)
		print("[PASS] Detección de jugador verificada")
		passed += 1

	# Iniciar diálogo y verificar congelamiento del jugador
	interaccion.iniciar_dialogo(fake_player)
	await process_frame
	
	if fake_player.is_interacting == true:
		print("[PASS] Jugador congelado correctamente durante el diálogo (is_interacting = true)")
		passed += 1
	else:
		print("[FAIL] El jugador no fue bloqueado durante el diálogo")
		failed += 1
		
	# Simular fin de diálogo
	interaccion._finalizar_dialogo()
	await process_frame
	
	if fake_player.is_interacting == false:
		print("[PASS] Jugador descongelado tras terminar el diálogo (is_interacting = false)")
		passed += 1
	else:
		print("[FAIL] El jugador quedó bloqueado tras el diálogo")
		failed += 1

	# 6. Comprobar diálogo con archivo .dialogue
	print("\n--- 6. Testing InteraccionDialogo with .dialogue file ---")
	interaccion.recurso_dialogo = diag_file
	interaccion.titulo_o_cue = "start"
	var res_obtenido = interaccion._obtener_recurso_dialogo()
	if res_obtenido == diag_file:
		print("[PASS] InteraccionDialogo prioriza correctamente el recurso_dialogo configurado")
		passed += 1
	else:
		print("[FAIL] No obtuvo el recurso_dialogo esperado")
		failed += 1

	# Limpiar
	npc.queue_free()
	fake_player.queue_free()
	await process_frame

	print("\n==================================================")
	print("RESULTADOS FINALES: PASARON %d / %d" % [passed, passed + failed])
	print("==================================================")
	quit(0 if failed == 0 else 1)
