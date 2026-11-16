extends SceneTree

var fallos: int = 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func comprobar(valor: bool, mensaje: String) -> void:
	if valor:
		print("PASS ", mensaje)
	else:
		fallos += 1
		push_error(mensaje)


func pulsar_qte(arena: Node, anticipado: bool) -> void:
	var comando: ComandoAccion = arena.comando
	for i in range(180):
		if comando.esta_activo():
			break
		await physics_frame
	comprobar(comando.esta_activo() and comando._mostrar_indicador and comando.is_visible_in_tree(), "Indicador de esquive activo y visible")
	if not comando.esta_activo():
		return
	comprobar(is_equal_approx(arena.enemigos[0].global_position.z, arena.aliados[0].global_position.z), "Embestida se alinea en profundidad con el protagonista")
	if not anticipado and "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/jarrito_qte_preview.png")
	if not anticipado:
		while comando._t < comando._impacto - 0.10:
			await process_frame
	var evento := InputEventAction.new()
	evento.action = &"interact"
	evento.pressed = true
	comando._unhandled_input(evento)
	comprobar(comando._resultado == (ComandoAccion.Resultado.ANTICIPADO if anticipado else ComandoAccion.Resultado.EXITO), "QTE clasifica la pulsación")
	if not anticipado:
		await create_timer(0.08).timeout
		var victima: Battler = arena.aliados[0]
		comprobar(victima.visual.position.y > victima._pos_visual.y, "Acierto inicia salto de esquive")


func _ejecutar() -> void:
	var datos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://assets/creatures/Jarro/combat/Jarro_Combat.json"))
	var frames: SpriteFrames = load("res://data/combat/jarrito_frames.tres")
	var total := 0
	for tag in datos.meta.frameTags:
		var anim := StringName(str(tag.name).to_lower())
		comprobar(frames.get_frame_count(anim) == tag.to - tag.from + 1, str(anim) + " conteo")
		comprobar(frames.get_animation_loop(anim) == (anim == &"idle"), str(anim) + " bucle")
		for i in range(frames.get_frame_count(anim)):
			var original: Dictionary = datos.frames[int(tag.from) + i]
			var tex := frames.get_frame_texture(anim, i) as AtlasTexture
			comprobar(tex.region == Rect2(original.frame.x, original.frame.y, 64, 64), "%s/%s región completa" % [anim, i])
			var ms := frames.get_frame_duration(anim, i) / frames.get_animation_speed(anim) * 1000.0
			comprobar(is_equal_approx(ms, float(original.duration)), "%s/%s duración JSON" % [anim, i])
			total += 1
	comprobar(total == 19, "19 cuadros")
	var mundo: Node = load("res://scenes/world/Entities/Jarrito.tscn").instantiate()
	comprobar(mundo.get_node("EncuentroCombate").enemigos[0].resource_path.ends_with("JarritoBattler.tscn"), "Encuentro Jarrito configurado")
	mundo.free()
	var arena: Node3D = load("res://scenes/combat/tests/JarritoCombatTest.tscn").instantiate()
	arena.auto_iniciar_si_esta_vacio = false
	root.add_child(arena)
	arena.inicializar([load("res://scenes/combat/battlers/PlayerBattler.tscn")], [arena.escena_battler_enemigo_defecto])
	var jarrito: Battler = arena.enemigos[0]
	var sprite := jarrito.visual as AnimatedSprite3D
	comprobar(is_zero_approx(sprite.position.y - (32.0 - 10.0) * sprite.pixel_size), "Base visible del Jarrito apoyada en el suelo sin margen transparente")
	jarrito.position.z = -2.8
	jarrito.posicion_base = jarrito.global_position
	comprobar(sprite != null and sprite.is_visible_in_tree(), "Sprite visible en arena real")
	comprobar(sprite.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST and sprite.transparent, "Nearest y transparencia")
	comprobar(jarrito.bando == Battler.Bando.ENEMIGO and not sprite.flip_h, "Orientación enemiga")
	await create_timer(1.2).timeout
	comprobar(sprite.animation == &"idle" and sprite.is_playing(), "Idle sigue en bucle tras dos ciclos")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/jarrito_combat_preview.png")
	for anim in [&"attack", &"hurt"]:
		jarrito.reproducir(anim)
		await jarrito.esperar_animacion()
		comprobar(not sprite.is_playing() and sprite.frame == frames.get_frame_count(anim) - 1, str(anim) + " termina en último cuadro")
		jarrito.reproducir(anim)
		comprobar(sprite.frame == 0, str(anim) + " se puede repetir desde inicio")
		await jarrito.esperar_animacion()
	jarrito.quedarse_quieto()
	var antes: int = arena.aliados[0].hp
	await jarrito.acciones[0].ejecutar(jarrito, [arena.aliados[0]], arena)
	comprobar(arena.aliados[0].hp < antes, "Embestida aplica daño si no se pulsa el QTE")
	arena.aliados[0].curar(999)
	antes = arena.aliados[0].hp
	pulsar_qte(arena, false)
	await jarrito.acciones[0].ejecutar(jarrito, [arena.aliados[0]], arena)
	comprobar(arena.aliados[0].hp == antes, "Esquive acertado evita el daño")
	pulsar_qte(arena, true)
	await jarrito.acciones[0].ejecutar(jarrito, [arena.aliados[0]], arena)
	comprobar(arena.aliados[0].hp < antes, "Pulsar demasiado pronto no evita el daño")
	comprobar(jarrito.global_position.is_equal_approx(jarrito.posicion_base) and sprite.animation == &"idle", "Embestida retorna a base e idle")
	jarrito.recibir_danio(1)
	await jarrito.animar_herido()
	comprobar(sprite.animation == &"idle" and sprite.modulate == Color.WHITE, "Hurt vuelve a idle sin alterar llama por HP")
	jarrito.recibir_danio(jarrito.hp)
	# La señal derrotado dispara animar_derrota a través de la arena.
	await create_timer(1.1).timeout
	jarrito.quedarse_quieto()
	jarrito.animar_herido()
	comprobar(not jarrito.reproducir(&"attack"), "Derrota bloquea animaciones posteriores")
	comprobar(sprite.animation == &"defeat" and sprite.frame == 5 and not sprite.is_playing(), "Defeat conserva último cuadro sin idle")
	var pot: Battler = load("res://scenes/combat/battlers/PotBattler.tscn").instantiate()
	root.add_child(pot)
	comprobar(pot.acciones[0] is AccionEmbestida and not pot.visual is AnimatedSprite3D, "Pot mantiene modelo y acción originales")
	pot.queue_free()
	arena.queue_free()
	await process_frame
	print("RESULTADO JARRITO: ", fallos, " fallos")
	quit(1 if fallos else 0)
