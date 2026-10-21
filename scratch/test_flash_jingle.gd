extends SceneTree

func _init() -> void:
	print("--- TEST FLASH Y JINGLE DE COMBATE ---")

	var enc = EncuentroCombate.new()
	assert(enc != null, "EncuentroCombate instanciado")
	print("1. Propiedades por defecto:")
	print("   - flash_activo: ", enc.flash_activo)
	print("   - color_flash: ", enc.color_flash)
	print("   - cantidad_flashes: ", enc.cantidad_flashes)
	print("   - duracion_flash: ", enc.duracion_flash)
	print("   - jingle_inicio: ", enc.jingle_inicio.resource_path)

	# Modificar propiedades
	enc.color_flash = Color.RED
	enc.cantidad_flashes = 3
	enc.duracion_flash = 0.05
	var nuevo_jingle: AudioStream = load("res://assets/audio/sfx/snd_bell_bounce_short.wav")
	enc.jingle_inicio = nuevo_jingle
	print("2. Propiedades personalizadas:")
	print("   - nuevo color_flash: ", enc.color_flash)
	print("   - nueva cantidad_flashes: ", enc.cantidad_flashes)
	print("   - nuevo jingle: ", enc.jingle_inicio.resource_path)

	# Comprobar CombatArena
	var arena_scene = load("res://scenes/combat/CombatArena.tscn")
	var arena: CombatArena = arena_scene.instantiate()
	arena.auto_iniciar_si_esta_vacio = false
	root.add_child(arena)
	arena.aplicar_configuracion_encuentro(null, null, "", -1, enc.jingle_inicio)
	assert(arena.jingle_inicio == nuevo_jingle, "CombatArena debe recibir el jingle configurado")
	print("3. CombatArena recibió jingle_inicio correctamente.")

	arena.queue_free()
	enc.queue_free()

	print("--- TEST FLASH Y JINGLE COMPLETADO CON ÉXITO ---")
	quit(0)
