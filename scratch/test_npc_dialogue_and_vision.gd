@tool
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("TEST: NPC VISUAL DIRECTION AWARENESS & DIALOGUE ISOLATION")
	print("==================================================")
	
	# 1. Crear entorno y jugador falso
	var root = Node3D.new()
	root.name = "TestRoot"
	get_root().add_child(root)
	
	var cam = Camera3D.new()
	cam.name = "Camera3D"
	root.add_child(cam)
	cam.position = Vector3(0, 5, 10)
	cam.look_at_from_position(Vector3(0, 5, 10), Vector3.ZERO, Vector3.UP)
	
	# Instanciar NPC desde prefab
	var npc_scene = load("res://scenes/world/Entities/placeholder_npc.tscn") as PackedScene
	assert(npc_scene != null, "placeholder_npc.tscn debe cargar")
	
	var npc_a = npc_scene.instantiate() as CharacterBody3D
	npc_a.name = "Npc_A"
	root.add_child(npc_a)
	npc_a.position = Vector3(-10, 0, 0)
	
	# Añadir InteraccionDialogo a NPC A
	var inter_scene = load("res://scenes/dialogue/InteraccionDialogo.tscn") as PackedScene
	var dial_a = inter_scene.instantiate() as InteraccionDialogo
	dial_a.name = "InteraccionDialogo"
	dial_a.nombre_hablante = "NPC A"
	dial_a.lineas_rapidas = ["Linea de A"] as Array[String]
	npc_a.add_child(dial_a)
	
	var npc_b = npc_scene.instantiate() as CharacterBody3D
	npc_b.name = "Npc_B"
	root.add_child(npc_b)
	npc_b.position = Vector3(10, 0, 0)
	
	var dial_b = inter_scene.instantiate() as InteraccionDialogo
	dial_b.name = "InteraccionDialogo"
	dial_b.nombre_hablante = "NPC B"
	dial_b.lineas_rapidas = ["Linea de B"] as Array[String]
	npc_b.add_child(dial_b)
	
	# Jugador
	var player = CharacterBody3D.new()
	player.name = "Player"
	player.add_to_group("player")
	root.add_child(player)
	player.position = Vector3(0, 0, 0)
	
	print("Verificando que los NPCs NO se detecten a sí mismos como el jugador...")
	# Llamar a _on_body_entered pasando el npc mismo
	dial_a._on_body_entered(npc_a)
	dial_b._on_body_entered(npc_b)
	assert(dial_a._jugador_en_rango == null, "NPC A no debe auto-detectarse")
	assert(dial_b._jugador_en_rango == null, "NPC B no debe auto-detectarse")
	print("PASS: Ningún NPC se auto-detectó.")
	
	# 2. Mover jugador cerca de NPC A (-10, 0, 0)
	print("\nMoviendo jugador cerca de NPC A...")
	player.position = Vector3(-10, 0, 1.5) # Justo enfrente de NPC A (hacia el sur / abajo)
	dial_a._on_body_entered(player)
	
	assert(dial_a._jugador_en_rango == player, "NPC A debe tener al jugador en rango")
	assert(dial_b._jugador_en_rango == null, "NPC B no debe tener al jugador en rango")
	assert(dial_a._es_el_interactuable_mas_cercano(player), "NPC A debe ser el más cercano a player")
	assert(not dial_b._es_el_interactuable_mas_cercano(player), "NPC B no puede ser el más cercano a player")
	print("PASS: Detección y proximidad aisladas por NPC.")
	
	# 3. Probar orientación visual hacia el jugador (mirar_hacia)
	print("\nProbando orientación de sprites con PlaceholderNPC...")
	assert(npc_a.has_method("mirar_hacia"), "NPC debe tener script PlaceholderNPC")
	var sp_a: AnimatedSprite3D = npc_a.get_node("Sprite2_5D") as AnimatedSprite3D
	assert(sp_a != null, "Sprite2_5D debe existir")
	
	# Jugador al sur (frente de la cámara) -> interact_down
	npc_a.mirar_hacia(Vector3(-10, 0, 5))
	print("Jugador al frente (+Z) -> Anim: ", sp_a.animation, " | Flip: ", sp_a.flip_h, " | Frame: ", sp_a.frame)
	assert(sp_a.animation == "interact_down", "Debe mirar hacia abajo/frente")
	assert(sp_a.frame == 0, "Debe pausarse en frame 0")
	
	# Jugador a la derecha (+X) -> interact_side, flip_h = false
	npc_a.mirar_hacia(Vector3(-5, 0, 0))
	print("Jugador a la derecha (+X) -> Anim: ", sp_a.animation, " | Flip: ", sp_a.flip_h, " | Frame: ", sp_a.frame)
	assert(sp_a.animation == "interact_side" and sp_a.flip_h == false, "Debe mirar a la derecha sin flip")
	assert(sp_a.frame == 0, "Debe pausarse en frame 0")
	
	# Jugador a la izquierda (-X) -> interact_side, flip_h = true
	npc_a.mirar_hacia(Vector3(-15, 0, 0))
	print("Jugador a la izquierda (-X) -> Anim: ", sp_a.animation, " | Flip: ", sp_a.flip_h, " | Frame: ", sp_a.frame)
	assert(sp_a.animation == "interact_side" and sp_a.flip_h == true, "Debe mirar a la izquierda con flip")
	assert(sp_a.frame == 0, "Debe pausarse en frame 0")
	
	# Jugador al norte (-Z) -> interact_up
	npc_a.mirar_hacia(Vector3(-10, 0, -5))
	print("Jugador detrás (-Z) -> Anim: ", sp_a.animation, " | Flip: ", sp_a.flip_h, " | Frame: ", sp_a.frame)
	assert(sp_a.animation == "interact_up", "Debe mirar hacia arriba/detrás")
	assert(sp_a.frame == 0, "Debe pausarse en frame 0")
	
	# Restaurar pose
	npc_a.restaurar_pose_defecto()
	print("Restaurar pose -> Anim: ", sp_a.animation, " | Frame: ", sp_a.frame)
	assert(sp_a.animation == npc_a._anim_reposo, "Debe volver a la animación de reposo original")
	assert(sp_a.frame == npc_a._frame_reposo, "Debe volver al frame de reposo original")
	
	# 4. Probar en World_Town con los NPCs reales
	print("\nVerificando escena real World_Town.tscn...")
	var town_scene = load("res://scenes/world/World_Town.tscn") as PackedScene
	var town = town_scene.instantiate()
	var town_npc = town.get_node_or_null("Npc")
	var town_npc_exp = town.get_node_or_null("Npc_Exp")
	var town_npc_util = town.get_node_or_null("Npc_Util")
	
	assert(town_npc != null and town_npc_exp != null and town_npc_util != null, "Los 3 NPCs deben existir en Town")
	assert(town_npc.get_script() != null, "Npc debe tener script")
	assert(town_npc_exp.get_script() != null, "Npc_Exp debe tener script")
	assert(town_npc_util.get_script() != null, "Npc_Util debe tener script")
	
	var dial_npc = town_npc.get_node("InteraccionDialogo") as InteraccionDialogo
	var dial_exp = town_npc_exp.get_node("InteraccionDialogo") as InteraccionDialogo
	var dial_util = town_npc_util.get_node("InteraccionDialogo") as InteraccionDialogo
	
	print("Lineas de Npc: ", dial_npc.lineas_rapidas)
	print("Lineas de Npc_Exp: ", dial_exp.lineas_rapidas)
	print("Lineas de Npc_Util: ", dial_util.lineas_rapidas)
	
	assert(dial_npc.lineas_rapidas != dial_exp.lineas_rapidas, "Líneas deben ser distintas")
	assert(dial_exp.lineas_rapidas != dial_util.lineas_rapidas, "Líneas deben ser distintas")
	
	root.queue_free()
	town.free()
	
	print("\n==================================================")
	print("TODAS LAS PRUEBAS PASARON EXITOSAMENTE (100% OK)")
	print("==================================================")
	quit(0)
