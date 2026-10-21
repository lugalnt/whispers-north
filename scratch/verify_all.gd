extends SceneTree

func _initialize():
	print("========================================")
	print("RUNNING COMPLETE COMBAT TEST")
	print("========================================")
	
	var arena_scene = load("res://scenes/combat/CombatArena.tscn")
	var arena: CombatArena = arena_scene.instantiate()
	arena.auto_iniciar_si_esta_vacio = false
	root.add_child(arena)
	
	await process_frame
	await process_frame
	
	var p_scene = load("res://scenes/combat/battlers/PlayerBattler.tscn")
	var pot_scene = load("res://scenes/combat/battlers/PotBattler.tscn")
	
	arena.inicializar([p_scene], [pot_scene], null)
	await process_frame
	
	var player: Battler = arena.aliados[0]
	var pot: Battler = arena.enemigos[0]
	
	print("\n--- 1. VERIFYING CHARACTERS' GROUND CONTACT ---")
	print("Arena floor surface top: local Y = 0.0")
	var player_sp: AnimatedSprite3D = player.visual as AnimatedSprite3D
	var player_tex = player_sp.sprite_frames.get_frame_texture(player_sp.animation, 0)
	var player_bottom_y = player.position.y + player.visual.position.y - (player_tex.get_height() * player_sp.pixel_size * 0.5)
	print("Player visual local Y: ", player.visual.position.y)
	print("Player feet Y: ", player_bottom_y)
	
	var pot_mi: MeshInstance3D = pot.find_child("Root__Mt_Pot_A", true, false)
	var pot_verts: PackedVector3Array = pot_mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var pot_min_y = 9999.0
	for v in pot_verts:
		var gv = pot.to_local(pot_mi.global_transform * v)
		if gv.y < pot_min_y: pot_min_y = gv.y
	print("Pot visual local Y: ", pot.visual.position.y)
	print("Pot base Y: ", pot_min_y)
	
	if absf(player_bottom_y) < 0.05 and absf(pot_min_y) < 0.05:
		print(">> [PASS] Neither character is buried in the floor! Both feet/base rest on Y=0.")
	else:
		print(">> [FAIL] Ground alignment off: player=", player_bottom_y, " pot=", pot_min_y)

	print("\n--- 2. VERIFYING HEALTH BARS INITIALIZATION & UPDATES ---")
	print("Player HP: %d / %d" % [player.hp, player.stats.max_hp])
	print("Pot HP: %d / %d" % [pot.hp, pot.stats.max_hp])
	
	var pot_hud = arena._paneles_hud.get(pot)
	var player_hud = arena._paneles_hud.get(player)
	print("Pot HUD registered: ", pot_hud != null)
	print("Player HUD registered: ", player_hud != null)
	
	if pot_hud and player_hud:
		print("Initial Pot bar value: ", pot_hud.pbar.value, " max: ", pot_hud.pbar.max_value, " text: '", pot_hud.lbl.text, "'")
		print("Applying 3 damage to Pot...")
		pot.recibir_danio(3)
		print("Pot HP: %d, HUD text: '%s'" % [pot.hp, pot_hud.lbl.text])
		
		print("Applying 2 damage to Player...")
		player.recibir_danio(2)
		print("Player HP: %d, HUD text: '%s'" % [player.hp, player_hud.lbl.text])
		
		if pot.hp == (pot.stats.max_hp - 3) and pot_hud.lbl.text == ("%d / %d HP" % [pot.stats.max_hp - 3, pot.stats.max_hp]) and player.hp == (player.stats.max_hp - 2) and player_hud.lbl.text == ("%d / %d HP" % [player.stats.max_hp - 2, player.stats.max_hp]):
			print(">> [PASS] Health bars and text update and change accurately!")
		else:
			print(">> [FAIL] Health bar values mismatch!")

	print("\n--- 3. VERIFYING 'Z' KEY / INTERACT / UI_ACCEPT ---")
	arena._crear_botones_acciones(player)
	arena._estado = CombatArena.EstadoTurno.TURNO_JUGADOR
	
	var ev_z = InputEventKey.new()
	ev_z.physical_keycode = KEY_Z
	ev_z.pressed = true
	
	print("Input Map check for 'Z':")
	print("  event.is_action_pressed('interact'): ", ev_z.is_action_pressed("interact"))
	print("  event.is_action_pressed('ui_accept'): ", ev_z.is_action_pressed("ui_accept"))
	
	arena._seleccion_menu_resultado = null
	arena._unhandled_input(ev_z)
	print("Option selected in combat menu via 'Z': ", arena._seleccion_menu_resultado)
	if arena._seleccion_menu_resultado != null:
		print(">> [PASS] Pressing 'Z' confirms options in combat menus perfectly!")
	else:
		print(">> [FAIL] Pressing 'Z' did not confirm menu option!")

	print("\n========================================")
	print("TEST COMPLETE")
	print("========================================")
	arena.queue_free()
	quit()
