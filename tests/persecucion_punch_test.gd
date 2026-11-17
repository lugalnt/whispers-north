extends SceneTree

var fallos := 0
var golpe_terminado := false

func _initialize() -> void:
	ejecutar.call_deferred()

func comprobar(valor: bool, texto: String) -> void:
	if valor:
		print("PASS ", texto)
	else:
		fallos += 1
		push_error("FAIL " + texto)

func cuadros(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame

func golpear(aliado: Battler, victima: Battler, arena: Node) -> void:
	await aliado.acciones[0].ejecutar(aliado, [victima], arena)
	golpe_terminado = true

func ejecutar() -> void:
	var mundo := Node3D.new()
	root.add_child(mundo)
	current_scene = mundo
	var piso := CSGBox3D.new()
	piso.size = Vector3(100, 1, 100)
	piso.position.y = -0.5
	piso.use_collision = true
	mundo.add_child(piso)
	var jugador: CharacterBody3D = load("res://scenes/player/player_32.tscn").instantiate()
	jugador.position = Vector3(8, 1.3, 0)
	mundo.add_child(jugador)
	var jarrito: Jarrito = load("res://scenes/world/Entities/Jarrito.tscn").instantiate()
	mundo.add_child(jarrito)
	var muro := CSGBox3D.new()
	muro.size = Vector3(0.5, 6, 8)
	muro.position = Vector3(4, 2, 0)
	muro.use_collision = true
	mundo.add_child(muro)
	await cuadros(10)
	comprobar(is_equal_approx(jarrito.radio_deteccion, 4.5), "Radio de detección predeterminado reducido a 4.5 m")
	muro.queue_free()
	await cuadros(10)
	comprobar(jarrito.estado == Jarrito.Estado.IDLE, "Con radio 4.5 m no detecta al jugador a 8 m")
	muro = CSGBox3D.new()
	muro.size = Vector3(0.5, 6, 8)
	muro.position = Vector3(4, 2, 0)
	muro.use_collision = true
	mundo.add_child(muro)
	jarrito.radio_deteccion = 9.0
	jarrito.distancia_perdida = 18.0
	await cuadros(60)
	comprobar(jarrito.estado == Jarrito.Estado.IDLE, "Muro bloquea detección")
	muro.queue_free()
	await cuadros(150)
	comprobar(jarrito.estado == Jarrito.Estado.WALK and jarrito.position.x > 0.5, "Al subir slider a 9 m detecta a 8 m y persigue físicamente")
	jugador.is_interacting = true
	var posicion := jarrito.position
	await cuadros(20)
	comprobar(jarrito.position.distance_to(posicion) < 0.1, "Diálogo detiene persecución")
	jugador.is_interacting = false
	jugador.position.x = 40
	await cuadros(3)
	comprobar(jarrito.estado == Jarrito.Estado.RETURN, "Perder al jugador inicia regreso")
	await cuadros(220)
	comprobar(jarrito.estado == Jarrito.Estado.IDLE and absf(jarrito.position.x) < 0.3, "Regresa al origen y descansa")
	comprobar(jarrito.get_node("FlameAnimationPlayer").is_playing(), "Llama sigue independiente")
	mundo.queue_free()
	await cuadros(3)
	current_scene = null

	var arena: Node3D = load("res://scenes/combat/tests/JarritoCombatTest.tscn").instantiate()
	arena.auto_iniciar_si_esta_vacio = false
	root.add_child(arena)
	current_scene = arena
	arena.inicializar([load("res://scenes/combat/battlers/PlayerBattler.tscn")], [arena.escena_battler_enemigo_defecto])
	var aliado: Battler = arena.aliados[0]
	var sprite := aliado.visual as AnimatedSprite3D
	for ruta in ["res://scenes/player/player.tscn", "res://scenes/player/player_32.tscn"]:
		var campo: Node = load(ruta).instantiate()
		var originales: SpriteFrames = campo.get_node("Sprite2_5D").sprite_frames
		aliado.copiar_sprite_de(campo)
		var esperado := 7
		comprobar(sprite.sprite_frames.get_frame_count(&"punch_down_site") == esperado, "Atlas correcto " + ruta.get_file())
		var cuadro := sprite.sprite_frames.get_frame_texture(&"punch_down_site", 0) as AtlasTexture
		comprobar(cuadro.get_height() == 32 and cuadro.atlas.resource_path.ends_with("/finn_punch.png"), "Ataque siempre usa atlas personalizado de 32x32")
		comprobar(not originales.has_animation(&"punch_down_site"), "No modifica SpriteFrames del mundo")
		comprobar(not sprite.sprite_frames.get_animation_loop(&"punch_down_site"), "Puñetazo no hace bucle")
		aliado.reproducir(aliado.anim_ataque)
		await cuadros(12)
		aliado.reproducir(aliado.anim_ataque)
		comprobar(sprite.frame == 0, "Ataques consecutivos reinician cuadro")
		campo.free()
	var victima: Battler = arena.enemigos[0]
	victima.hp = 99
	var antes := victima.hp
	golpear(aliado, victima, arena)
	var vio_punch := false
	for i in 400:
		if golpe_terminado:
			break
		if sprite.animation == &"punch_down_site" and sprite.frame == 3:
			if not vio_punch and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("wotn_punch.png"))
			vio_punch = true
		await cuadros(1)
	comprobar(golpe_terminado and vio_punch, "Golpear reproduce el puñetazo real y termina")
	comprobar(victima.hp < antes, "Golpear aplica daño")
	comprobar(sprite.animation == aliado.anim_reposo and aliado.global_position.is_equal_approx(aliado.posicion_base), "Regresa a base y reposo")
	arena.queue_free()
	await cuadros(3)
	print("RESULTADO PERSECUCION Y PUNCH: ", fallos, " fallos")
	quit(1 if fallos else 0)
