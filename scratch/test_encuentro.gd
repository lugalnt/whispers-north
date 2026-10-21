extends SceneTree

func _init() -> void:
	print("--- INICIANDO TEST DE ENCUENTRO COMBATE ---")
	
	# 1. Test class_name EncuentroCombate instantiation
	var encuentro = EncuentroCombate.new()
	assert(encuentro != null, "EncuentroCombate debe instanciarse correctamente")
	print("1. EncuentroCombate instanciado con éxito.")
	print("   - Activo por defecto: ", encuentro.activo)
	print("   - Aliados por defecto: ", encuentro.aliados.size())
	print("   - Enemigos por defecto: ", encuentro.enemigos.size())
	print("   - EXP por defecto: ", encuentro.exp_recompensa)
	print("   - Texto recompensas: ", encuentro.texto_recompensas.replace("\n", " | "))

	# 2. Test Pot.tscn loading and child EncuentroCombate
	var pot_scene: PackedScene = load("res://scenes/world/Entities/Pot.tscn")
	assert(pot_scene != null, "Pot.tscn debe cargar")
	var pot_instance = pot_scene.instantiate()
	root.add_child(pot_instance)
	
	var child_encuentro = pot_instance.get_node_or_null("EncuentroCombate")
	assert(child_encuentro != null, "Pot.tscn debe tener nodo hijo 'EncuentroCombate'")
	assert(child_encuentro is EncuentroCombate, "El nodo hijo debe ser de tipo EncuentroCombate")
	print("2. Pot.tscn instanciado y contiene hijo EncuentroCombate correctamente.")
	print("   - pot._obtener_encuentro(): ", pot_instance._obtener_encuentro())
	print("   - child_encuentro: ", child_encuentro)
	assert(pot_instance._obtener_encuentro() == child_encuentro, "pot._obtener_encuentro() debe devolver child_encuentro")
	print("   - pot.encuentro_combate vinculado: true")

	# 3. Test dynamic customization via inspector properties
	child_encuentro.exp_recompensa = 999
	child_encuentro.texto_recompensas = "¡Victoria Épica!\n+999 EXP\nObtuviste: [Corona de Oro]"
	print("3. Propiedades editadas dinámicamente:")
	print("   - Nueva EXP: ", child_encuentro.exp_recompensa)
	print("   - Nuevo Texto: ", child_encuentro.texto_recompensas.replace("\n", " | "))

	# 4. Test CombatArena dynamic configuration
	var arena_scene: PackedScene = load("res://scenes/combat/CombatArena.tscn")
	var arena: CombatArena = arena_scene.instantiate() as CombatArena
	arena.auto_iniciar_si_esta_vacio = false
	root.add_child(arena)
	arena.aplicar_configuracion_encuentro(null, null, child_encuentro.texto_recompensas, child_encuentro.exp_recompensa)
	print("4. CombatArena recibió la configuración dinámica:")
	print("   - arena.exp_victoria: ", arena.exp_victoria)
	print("   - arena.texto_recompensas: ", arena.texto_recompensas.replace("\n", " | "))
	assert(arena.exp_victoria == 999, "La experiencia debe coincidir con la configurada")
	assert(arena.texto_recompensas == child_encuentro.texto_recompensas, "El texto debe coincidir")

	# 5. Test initialization with custom enemies/allies array
	arena.inicializar(child_encuentro.aliados, child_encuentro.enemigos, null)
	assert(arena.aliados.size() == 1, "Debe tener 1 aliado instanciado")
	assert(arena.enemigos.size() == 1, "Debe tener 1 enemigo instanciado")
	print("5. Arena inicializada con combatientes:")
	print("   - Aliados: ", arena.aliados[0].nombre, " HP:", arena.aliados[0].hp)
	print("   - Enemigos: ", arena.enemigos[0].nombre, " HP:", arena.enemigos[0].hp)

	# Clean up
	arena.queue_free()
	pot_instance.queue_free()
	encuentro.queue_free()

	print("--- TODOS LOS TESTS DE ENCUENTRO COMBATE PASARON SATISFACTORIAMENTE ---")
	quit(0)
