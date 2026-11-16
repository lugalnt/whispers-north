extends SceneTree
var fallos := 0
var muestras := 0
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var rutas := {
		"World": [[Vector2(0,-19),Vector2(0,25)],[Vector2(-30,25),Vector2(39,25)]],
		"World_Town": [[Vector2(-28,4),Vector2(48,4)],[Vector2(-16,18),Vector2(43,18)],[Vector2(-20,-10),Vector2(46,-10)]],
		"World_House": [[Vector2(-3,0),Vector2(3,0)],[Vector2(35,0.5),Vector2(45,0.5)]],
		"World_Cave": [[Vector2(0,0),Vector2(84,0)]],
		"World_ForestRuins": [[Vector2(8,61),Vector2(75,61)],[Vector2(39,61),Vector2(39,23)],[Vector2(26,40),Vector2(39,40)],[Vector2(39,47),Vector2(50,47)],[Vector2(25,25),Vector2(39,25)],[Vector2(13,13),Vector2(28,13)],[Vector2(39,23),Vector2(70,23)],[Vector2(65,16),Vector2(96,16)]]}
	for nombre in rutas:
		var zona = load("res://scenes/world/"+nombre+".tscn").instantiate()
		root.add_child(zona)
		current_scene = zona
		await create_timer(0.6).timeout
		var jugador = zona.get_active_player()
		jugador.set_physics_process(false)
		var guardia: Node
		for n in zona.get_children():
			if n.get_script() == load("res://scripts/world/world_presentation.gd"): guardia = n
		for ruta in rutas[nombre]:
			var pasos: int = ceili(ruta[0].distance_to(ruta[1]))
			for i in range(pasos+1):
				var punto: Vector2 = ruta[0].lerp(ruta[1],float(i)/maxi(pasos,1))
				jugador.global_position = Vector3(punto.x,1.6 if nombre == "World" else 1.1,punto.y)
				# Un metro de avance cada 0.2 segundos a velocidad normal.
				guardia._process(1.0 if i == 0 else 0.2)
				muestras += 1
				if not guardia._encuadra(root.get_camera_3d(),jugador,0.01):
					fallos += 1
					print("FAIL ruta ",nombre," ",punto)
				var cam := root.get_camera_3d()
				for quieto in 4: guardia._process(1.0 if i == 0 else 0.2)
				if root.get_camera_3d() != cam and guardia._encuadra(cam,jugador,0.08):
					# Se permite terminar la selección pendiente, pero debe estabilizarse.
					cam = root.get_camera_3d()
					for quieto in 4: guardia._process(1.0 if i == 0 else 0.2)
					if root.get_camera_3d() != cam: fallos += 1
		zona.queue_free()
		await process_frame
	print("RESULTADO RUTAS: ",muestras," muestras; ",fallos," fallos")
	quit(1 if fallos else 0)
