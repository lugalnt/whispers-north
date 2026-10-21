extends SceneTree

func _init() -> void:
	print("--- TEST DE MODIFICACIÓN SIMPLE DE ASSETS ---")

	# 1. Modificar Fondo y Música en EncuentroCombate
	var encuentro: EncuentroCombate = EncuentroCombate.new()
	var test_tex: Texture2D = load("res://assets/sprites/environment/materials/pokemon_grass.png")
	var test_music: AudioStream = load("res://assets/audio/music/MusicaMenu.mp3")
	
	encuentro.textura_fondo = test_tex
	encuentro.musica_combate = test_music
	print("1. EncuentroCombate configurado con nuevos assets:")
	print("   - Textura fondo cambiada: ", encuentro.textura_fondo.resource_path)
	print("   - Música cambiada: ", encuentro.musica_combate.resource_path)

	# 2. Comprobar que CombatArena recibe y aplica la textura y música
	var arena_scene: PackedScene = load("res://scenes/combat/CombatArena.tscn")
	var arena: CombatArena = arena_scene.instantiate()
	arena.auto_iniciar_si_esta_vacio = false
	root.add_child(arena)
	
	arena.aplicar_configuracion_encuentro(encuentro.musica_combate, encuentro.textura_fondo, "Recompensa Test", 50)
	var fondo_sprite: Sprite3D = arena.nodo_escenario.get_node_or_null("FondoSprite") as Sprite3D
	assert(fondo_sprite != null, "FondoSprite debe existir en la arena")
	assert(fondo_sprite.texture == test_tex, "La textura del fondo debe ser la nueva")
	assert(arena.musica_combate == test_music, "La música debe ser la nueva")
	print("2. CombatArena aplicó los assets visuales y de audio con éxito.")

	# 3. Comprobar que en Battler se pueden cambiar sprites y nombres de animación
	var player_scene: PackedScene = load("res://scenes/combat/battlers/PlayerBattler.tscn")
	var player_battler: Battler = player_scene.instantiate()
	root.add_child(player_battler)
	
	# Cambiar animaciones en el inspector
	player_battler.anim_ataque = &"nueva_animacion_ataque"
	player_battler.copiar_sprite_del_jugador = false
	print("3. Battler permite cambiar nombres de animación y desactivar copia de sprites:")
	print("   - anim_ataque: ", player_battler.anim_ataque)
	print("   - copiar_sprite_del_jugador: ", player_battler.copiar_sprite_del_jugador)

	# 4. Comprobar que BattlerAction permite cambiar SFX y tiempos de impacto
	var golpe: AccionGolpe = AccionGolpe.new()
	var sfx_nuevo: AudioStream = load("res://assets/audio/sfx/snd_glassbreak.wav")
	golpe.sonido_golpe = sfx_nuevo
	golpe.tiempo_impacto = 0.8
	golpe.bonus_exito = 10
	print("4. BattlerAction permite reconfigurar SFX y tiempos:")
	print("   - sonido_golpe: ", golpe.sonido_golpe.resource_path)
	print("   - tiempo_impacto: ", golpe.tiempo_impacto)
	print("   - bonus_exito: ", golpe.bonus_exito)

	# Limpieza
	arena.queue_free()
	player_battler.queue_free()
	encuentro.queue_free()

	print("--- TODOS LOS ASSETS SON MODIFICABLES DE FORMA SENCILLA Y DIRECTA ---")
	quit(0)
