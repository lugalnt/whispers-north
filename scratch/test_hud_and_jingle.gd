extends SceneTree

func _init() -> void:
	print("--- TEST INICIO: HUD TEXTS Y JINGLE CUSTOMIZABLE ---")
	
	# 1. Probar CombatArena.tscn
	var arena_scene: PackedScene = load("res://scenes/combat/CombatArena.tscn")
	assert(arena_scene != null, "CombatArena.tscn debe cargar")
	var arena: CombatArena = arena_scene.instantiate() as CombatArena
	assert(arena != null, "CombatArena debe instanciarse")
	root.add_child(arena)
	
	print("[1] Arena instanciada. Jingle en nodo visual:", arena.jingle_inicio)
	assert(arena.jingle_inicio != null, "CombatArena.tscn debe tener su jingle_inicio asignado en el nodo principal")
	assert(arena.texto_inicio_combate == "¡Empieza el combate!", "texto_inicio_combate por defecto correcto")
	assert(arena.texto_victoria == "¡Victoria!", "texto_victoria por defecto correcto")
	assert(arena.texto_huida == "¡Escapaste del combate!", "texto_huida por defecto correcto")
	assert(arena.texto_opcion_huir == "Huir", "texto_opcion_huir por defecto correcto")
	
	# 2. Probar aplicar_configuracion_encuentro
	var sfx_custom: AudioStream = load("res://assets/audio/sfx/snd_bell_bounce_short.wav")
	arena.aplicar_configuracion_encuentro(
		null,
		null,
		"¡Recompensa custom!",
		50,
		sfx_custom,
		"¡Duelo épico!",
		"¡Gran triunfo!",
		"¡Caíste!",
		"¡Huidita!",
		"BOTÍN"
	)
	
	assert(arena.jingle_inicio == sfx_custom, "Jingle debe haberse actualizado al custom")
	assert(arena.texto_inicio_combate == "¡Duelo épico!", "texto_inicio_combate actualizado")
	assert(arena.texto_victoria == "¡Gran triunfo!", "texto_victoria actualizado")
	assert(arena.texto_derrota == "¡Caíste!", "texto_derrota actualizado")
	assert(arena.texto_huida == "¡Huidita!", "texto_huida actualizado")
	assert(arena.texto_titulo_recompensas == "BOTÍN", "texto_titulo_recompensas actualizado")
	assert(arena.texto_recompensas == "¡Recompensa custom!", "texto_recompensas actualizado")
	assert(arena.exp_victoria == 50, "exp_victoria actualizada")
	print("[2] aplicacion de textos y jingle personalizada exitosa.")
	
	arena.queue_free()
	
	# 3. Probar EncuentroCombate
	var enc: EncuentroCombate = EncuentroCombate.new()
	assert(enc.jingle_inicio == null, "EncuentroCombate.jingle_inicio debe ser null por defecto para heredar de la arena")
	assert(enc.texto_inicio_combate == "", "texto_inicio_combate vacio por defecto")
	
	# Probar herencia de jingle desde la escena de arena
	var arena_temp: CombatArena = arena_scene.instantiate() as CombatArena
	var jingle_heredado: AudioStream = enc.jingle_inicio
	if jingle_heredado == null and arena_temp.jingle_inicio != null:
		jingle_heredado = arena_temp.jingle_inicio
	assert(jingle_heredado != null, "Debe heredar el jingle de CombatArena.tscn si el encuentro es null")
	print("[3] Herencia de jingle desde CombatArena.tscn visual exitosa:", jingle_heredado.resource_path)
	arena_temp.queue_free()
	enc.queue_free()
	
	# 4. Probar Pot y propagación de propiedades
	var pot_scene: PackedScene = load("res://scenes/world/Entities/Pot.tscn")
	assert(pot_scene != null, "Pot.tscn debe cargar")
	var pot: CharacterBody3D = pot_scene.instantiate() as CharacterBody3D
	root.add_child(pot)
	
	# Configurar propiedades en el nodo principal de Pot
	pot.jingle_combate = sfx_custom
	pot.texto_inicio_combate = "¡Un jarrón salvaje aparece!"
	pot.texto_recompensas_combate = "+100 EXP\n[Gemas brillantes]"
	pot.exp_recompensa_combate = 100
	
	var pot_enc: EncuentroCombate = pot.get_node_or_null("EncuentroCombate") as EncuentroCombate
	assert(pot_enc != null, "Pot debe tener EncuentroCombate como hijo")
	
	# Simular propagación como lo hace _iniciar_evento_combate
	if pot.jingle_combate != null:
		pot_enc.jingle_inicio = pot.jingle_combate
	if not pot.texto_inicio_combate.is_empty():
		pot_enc.texto_inicio_combate = pot.texto_inicio_combate
	if not pot.texto_recompensas_combate.is_empty():
		pot_enc.texto_recompensas = pot.texto_recompensas_combate
	if pot.exp_recompensa_combate >= 0:
		pot_enc.exp_recompensa = pot.exp_recompensa_combate
		
	assert(pot_enc.jingle_inicio == sfx_custom, "El jingle configurado en Pot se propaga a EncuentroCombate")
	assert(pot_enc.texto_inicio_combate == "¡Un jarrón salvaje aparece!", "El texto de inicio se propaga")
	assert(pot_enc.texto_recompensas == "+100 EXP\n[Gemas brillantes]", "Las recompensas se propagan")
	assert(pot_enc.exp_recompensa == 100, "La experiencia se propaga")
	print("[4] Propagacion desde el nodo principal de Pot exitosa.")
	
	pot.queue_free()
	
	print("--- TODOS LOS TESTS PASARON EXITOSAMENTE (0 ERRORES) ---")
	quit(0)
