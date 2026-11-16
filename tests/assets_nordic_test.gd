extends SceneTree

var fallos := 0
func _initialize() -> void:
	ejecutar.call_deferred()

func comprobar(ok: bool, texto: String) -> void:
	if ok: print("PASS ", texto)
	else:
		fallos += 1
		push_error(texto)

func capturar(nombre: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("wotn_assets_" + nombre + ".png"))

func ejecutar() -> void:
	var gs = root.get_node("GameState")
	gs.nueva_partida()
	for id in ["queso_nordico", "fragmento_ceramica", "llave_antigua", "pan_centeno", "bayas_bosque", "espada_corta", "hacha_lenador", "cristal_bosque", "monedas_laton"]:
		var item := ItemDatabase.obtener_item(id)
		comprobar(item != null and item.icono != null and "/nordic_v1/" in item.icono.resource_path, "Icono integrado: " + id)
	for zona in ["World_House", "World_Town", "World_ForestRuins"]:
		var escena: Node = load("res://scenes/world/" + zona + ".tscn").instantiate()
		root.add_child(escena)
		current_scene = escena
		await capturar(zona)
		comprobar(root.get_camera_3d() != null, "Escena renderiza: " + zona)
		escena.queue_free()
		await process_frame
	current_scene = null
	var mundo := Node3D.new()
	root.add_child(mundo)
	var cam := Camera3D.new()
	mundo.add_child(cam)
	cam.position = Vector3(0, 3, 9)
	cam.look_at(Vector3(0, 0.8, 0))
	cam.make_current()
	for i in 2:
		var cofre: Node3D = load("res://scenes/world/Entities/Chest.tscn").instantiate()
		cofre.position.x = -1.5 + i * 3
		mundo.add_child(cofre)
		cofre.get_node("StaticBody3D/Closed").visible = i == 0
		cofre.get_node("StaticBody3D/Open").visible = i == 1
		var sprite: Sprite3D = cofre.get_node("StaticBody3D/Closed")
		comprobar(sprite.pixel_size * sprite.texture.get_width() < 2.0, "Cofre mantiene tamaño del mundo")
	var pickup: ItemPickup3D = load("res://scenes/world/Entities/ItemPickup.tscn").instantiate()
	mundo.add_child(pickup)
	comprobar(is_equal_approx(pickup.sprite.pixel_size * pickup.sprite.texture.get_width(), 0.96), "Icono de alta resolución normalizado como recogible")
	await capturar("cofres")
	mundo.queue_free()
	await process_frame
	var menu: Node = load("res://scenes/ui/MainMenu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await capturar("menu")
	menu.queue_free()
	await process_frame
	print("RESULTADO ASSETS: ", fallos, " fallos")
	quit(1 if fallos else 0)
