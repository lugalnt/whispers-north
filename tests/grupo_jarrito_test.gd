extends SceneTree

var fallos := 0

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

func ejecutar() -> void:
	var gestor: Node = root.get_node("CoordinadorEncuentros")
	for resultado in [2, 0, -1]:
		var mundo := Node3D.new()
		root.add_child(mundo)
		current_scene = mundo
		var piso := CSGBox3D.new()
		piso.size = Vector3(50, 1, 50)
		piso.position.y = -0.5
		piso.use_collision = true
		mundo.add_child(piso)
		var camara := Camera3D.new()
		camara.position = Vector3(0, 3, 8)
		mundo.add_child(camara)
		camara.make_current()
		var jugador: Node3D = load("res://scenes/player/player.tscn").instantiate()
		jugador.position = Vector3(1.6, 1.2, 0)
		mundo.add_child(jugador)
		var miembros: Array[Jarrito] = []
		for i in 3:
			var j: Jarrito = load("res://scenes/world/Entities/Jarrito.tscn").instantiate()
			j.grupo_encuentro = &"prueba_trio"
			j.velocidad = 0.0
			j.position = Vector3(-i * 2, 0.1, 0)
			mundo.add_child(j)
			miembros.append(j)
		gestor._proteccion = 0.0
		await cuadros(4)
		comprobar(not gestor.ocupado(), "Cercanía sin contacto no inicia combate")
		var sonido := miembros[0]._audio_deteccion.playing
		jugador.position.x = 1.24
		await cuadros(4)
		comprobar(gestor.ocupado(), "Contacto inicia inmediatamente sin esperar Alert ni Encounter")
		for i in 400:
			for j in miembros:
				sonido = sonido or j._audio_deteccion.playing
			if gestor.ocupado() and is_instance_valid(gestor.activa.arena) and gestor.activa.fase == 1:
				break
			await cuadros(1)
		comprobar(sonido, "Detección reproduce audio")
		if not gestor.ocupado() or not is_instance_valid(gestor.activa.arena):
			comprobar(false, "Se inicia el encuentro grupal")
			quit(1)
			return
		var arena: Node = gestor.activa.arena
		comprobar(arena.enemigos.size() == 3, "Una arena contiene los tres Jarritos")
		var pantalla: Vector2 = root.get_visible_rect().size
		var posiciones: Array[Vector2] = []
		for enemigo in arena.enemigos:
			var pie: Vector2 = arena.camara.unproject_position(enemigo.global_position)
			var cabeza: Vector2 = arena.camara.unproject_position(enemigo.punto_cabeza())
			comprobar(pie.x > pantalla.x * 0.06 and pie.x < pantalla.x * 0.9 and pie.y < pantalla.y * 0.91 and cabeza.y > pantalla.y * 0.07, "Enemigo completo dentro del encuadre")
			for anterior in posiciones:
				comprobar(pie.distance_to(anterior) > pantalla.y * 0.12, "Formación mantiene separación visible entre enemigos")
			posiciones.append(pie)
		for j in miembros:
			comprobar(not j._visual.visible and j._sesion_grupo == gestor.activa, "Miembro oculto y unido a la misma sesión")
		var sprite: AnimatedSprite3D = arena.aliados[0].visual
		comprobar(sprite.sprite_frames.get_frame_texture(arena.aliados[0].anim_reposo, 0).get_height() == 32, "Combate usa 32x32 aunque mundo usa 16x16")
		if resultado == 2 and DisplayServer.get_name() != "headless":
			await create_timer(0.8).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("wotn_trio.png"))
		if resultado == -1:
			# Eliminar al iniciador debe restaurar los otros dos miembros.
			gestor.activa.propietario.get_parent().queue_free()
		else:
			arena.combate_terminado.emit(resultado)
		for i in 400:
			if not gestor.ocupado():
				break
			await cuadros(1)
		await cuadros(3)
		comprobar(not gestor.ocupado() and not jugador.is_interacting, "Finalizar libera sesión y controles")
		for j in miembros:
			if is_instance_valid(j):
				comprobar(j._visual.visible and j._sesion_grupo == null, "Visual restaurado tras cierre")
				comprobar(j._derrotado == (resultado == 0), "Victoria afecta al grupo; huida/cancelación permite reintento")
		mundo.queue_free()
		await cuadros(5)
		current_scene = null
	print("RESULTADO GRUPO: ", fallos, " fallos")
	quit(1 if fallos else 0)
