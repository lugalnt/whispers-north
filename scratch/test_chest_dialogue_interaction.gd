extends SceneTree

func _init() -> void:
	print("\n==================================================")
	print("TESTING CHEST + DIALOGUE MANAGER INTERACTION FIX")
	print("==================================================")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var passed = 0
	var failed = 0
	
	# 1. Instanciar escena de cofre
	print("\n--- 1. Instantiating Chest with InteraccionDialogo ---")
	var chest_scene = load("res://scenes/world/Entities/Chest.tscn") as PackedScene
	var chest = chest_scene.instantiate()
	root.add_child(chest)
	
	var interact_scene = load("res://scenes/dialogue/InteraccionDialogo.tscn") as PackedScene
	var interaccion: InteraccionDialogo = interact_scene.instantiate()
	interaccion.nombre_hablante = "Cofre"
	interaccion.lineas_rapidas = ["(Es la Dani.)"]
	interaccion.es_objeto_interactuable = true
	interaccion.activar_objeto_al_terminar = true
	interaccion.ignorar_si_padre_abierto = true
	interaccion.desactivar_tras_abrir_objeto = true
	chest.add_child(interaccion)
	
	# Instanciar jugador
	var player_scene = load("res://scenes/player/player_32.tscn") as PackedScene
	var player = player_scene.instantiate()
	player.name = "Player"
	player.add_to_group("player")
	player.position = Vector3(0.5, 0, 0)
	root.add_child(player)
	
	await process_frame
	
	if chest.has_method("abrir") and chest.has_method("interactuar"):
		print("[PASS] Chest implementa abrir() e interactuar() correctamente")
		passed += 1
	else:
		print("[FAIL] Chest no tiene los métodos requeridos")
		failed += 1
	
	# 2. Verificar detección de padre interactuable
	print("\n--- 2. Testing _padre_es_interactuable() & _padre_esta_abierto() ---")
	if interaccion._padre_es_interactuable():
		print("[PASS] InteraccionDialogo detectó correctamente que el cofre es un objeto interactuable")
		passed += 1
	else:
		print("[FAIL] No detectó padre interactuable")
		failed += 1
		
	if not interaccion._padre_esta_abierto():
		print("[PASS] Estado inicial: cofre cerrado detectado correctamente")
		passed += 1
	else:
		print("[FAIL] Reportó cofre abierto antes de tiempo")
		failed += 1

	# 3. Iniciar interacción de diálogo
	print("\n--- 3. Testing Dialogue Launch & Freeze ---")
	interaccion.iniciar_dialogo(player)
	await process_frame
	
	if player.is_interacting:
		print("[PASS] Jugador bloqueado correctamente al iniciar el diálogo del cofre")
		passed += 1
	else:
		print("[FAIL] Jugador no fue bloqueado")
		failed += 1

	# 4. Simular finalización del diálogo
	print("\n--- 4. Testing Dialogue Completion & Automatic Chest Opening ---")
	interaccion._finalizar_dialogo()
	await process_frame
	await process_frame
	
	# Si el jugador está reproduciendo la animación de abrir cofre (play_interact), esperar a que termine
	var anim_sp = player.get_node_or_null("Sprite2_5D")
	if anim_sp and anim_sp.is_playing() and anim_sp.animation.begins_with("interact_"):
		await anim_sp.animation_finished
	await process_frame
	
	if not player.is_interacting:
		print("[PASS] Jugador desbloqueado tras terminar el diálogo")
		passed += 1
	else:
		print("[FAIL] Jugador sigue bloqueado")
		failed += 1
		
	if chest.esta_abierto:
		print("[PASS] El cofre se abrió automáticamente al terminar el diálogo")
		passed += 1
	else:
		print("[FAIL] El cofre no se abrió tras el diálogo")
		failed += 1

	# 5. Comprobar que tras abrirse, InteraccionDialogo permite que inputs pasen al cofre
	print("\n--- 5. Testing Post-Open Pass-Through ---")
	if interaccion._padre_esta_abierto():
		print("[PASS] InteraccionDialogo detecta que el cofre ya está abierto")
		passed += 1
	else:
		print("[FAIL] No detectó cofre abierto")
		failed += 1

	# Limpiar
	chest.queue_free()
	player.queue_free()
	await process_frame

	print("\n==================================================")
	print("RESULTADOS FINALES: PASARON %d / %d" % [passed, passed + failed])
	print("==================================================")
	quit(0 if failed == 0 else 1)
