extends Node
## Ajustes visuales: no mueve las colisiones, marcadores ni las cámaras de combate.
var vegetacion: Array[Sprite3D] = []
var bases: Dictionary = {}
var zona: Node3D
var _espera_cambio := 0.0
var _cam_previa: Camera3D = null
var _pos_ancla_cam: Vector3 = Vector3.ZERO

func _ready() -> void:
	zona = get_parent()
	process_priority = 90
	if DisplayServer.get_name() == "headless":
		get_viewport().size = Vector2i(1140, 650)
	if zona.scene_file_path.get_file() in ["World.tscn", "World_Town.tscn"]:
		var limites_mundo := preload("res://scripts/world/world_boundary.gd").new()
		limites_mundo.name = "LimitesMundo"
		zona.add_child(limites_mundo)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var excluidos: Array[RID] = []
	for body in zona.find_children("*", "CollisionObject3D", true, false):
		excluidos.append(body.get_rid())
	var limites: Dictionary = {}
	for sprite in zona.find_children("*", "Sprite3D", true, false):
		if sprite.get_parent() and sprite.get_parent().name == "BosqueGenerado":
			vegetacion.append(sprite)
			continue
		var fuente: Node = sprite
		while fuente != zona and fuente.scene_file_path.is_empty(): fuente = fuente.get_parent()
		if not (fuente.scene_file_path.get_file() in ["Tree.tscn", "Tree_Pine.tscn", "Bush.tscn"] or "/NordicProps/" in fuente.scene_file_path or "/NordicDecor/" in fuente.scene_file_path): continue
		if sprite.texture == null: continue
		if "/NordicDecor/" in fuente.scene_file_path:
			sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
			sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
			continue # Atlas ya recortado y apoyado al suelo en el prefab.
		var tex: Texture2D = sprite.texture
		if not limites.has(tex): limites[tex] = tex.get_image().get_used_rect()
		var rect: Rect2i = limites[tex]
		var query := PhysicsRayQueryParameters3D.create(sprite.global_position + Vector3.UP * 5, sprite.global_position - Vector3.UP * 40, 1, excluidos)
		var hit := zona.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): continue
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		var escala_y_spr: float = sprite.global_basis.y.length()
		var fondo: float = (float(tex.get_height()) * 0.5 - float(rect.end.y) + sprite.offset.y) * sprite.pixel_size * escala_y_spr
		var hundimiento_manual: float = minf(0.0, fuente.position.y) * escala_y_spr
		sprite.global_position.y = hit.position.y - fondo - 0.06 + hundimiento_manual
		# Proyectar la silueta recortada por alfa sobre el suelo.
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
		vegetacion.append(sprite)

func _process(_delta: float) -> void:
	if not zona.has_method("get_active_player"): return
	var jugador: Node3D = zona.get_active_player()
	var cam := get_viewport().get_camera_3d()
	if jugador == null or cam == null or not jugador.is_visible_in_tree(): return
	# Las cámaras de exploración pertenecen directamente a la zona.
	if cam.get_parent() != zona and cam.get_parent().name != "Cameras": return
	if cam != _cam_previa:
		_cam_previa = cam
		_pos_ancla_cam = jugador.global_position
		if not cam.has_meta("sector_centro") and _encuadra(cam, jugador, 0.05):
			_espera_cambio = maxf(_espera_cambio, 0.45)
	elif jugador.global_position.distance_to(_pos_ancla_cam) > 1.5 and not _encuadra(cam, jugador, 0.05):
		_espera_cambio = 0.0
	# En World.tscn durante gameplay normal el cambio lo gobiernan SwitchC_1_2..SwitchC_5_6 y Bush.
	var es_world: bool = zona.scene_file_path.get_file() == "World.tscn"
	var centro := jugador.global_position + Vector3.UP * 0.45
	if es_world and not jugador.is_physics_processing():
		var cam_zona := _camara_por_switches_world(jugador.global_position)
		if cam_zona != null and cam_zona != cam:
			cam_zona.make_current()
			cam = cam_zona
			_cam_previa = cam
	elif not es_world:
		if not ("is_interacting" in jugador and jugador.is_interacting):
			_espera_cambio = maxf(0.0, _espera_cambio - _delta)
		if _espera_cambio <= 0.0 and not _encuadra(cam, jugador, 0.05):
			var sector := _sector_preferido(jugador, cam)
			if sector != null and sector != cam:
				sector.make_current()
				cam = sector
				_cam_previa = cam
				_pos_ancla_cam = jugador.global_position
				_espera_cambio = 0.45
		if _espera_cambio <= 0.0 and not _encuadra(cam, jugador, 0.05):
			var mejor: Camera3D = null
			var puntuacion := INF
			for candidata in zona.find_children("*", "Camera3D", true, false):
				if candidata.get_parent() != zona and candidata.get_parent().name != "Cameras": continue
				if candidata == cam or not _encuadra(candidata, jugador, 0.08): continue
				var uv: Vector2 = candidata.unproject_position(centro) / get_viewport().get_visible_rect().size
				var valor: float = uv.distance_squared_to(Vector2(0.5, 0.5)) + candidata.global_position.distance_to(centro) * 0.001
				if valor < puntuacion:
					puntuacion = valor
					mejor = candidata
			if mejor != null:
				mejor.make_current()
				cam = mejor
				_cam_previa = cam
				_pos_ancla_cam = jugador.global_position
				_espera_cambio = 0.65
	# Atenuar vegetación que tapa al personaje o se interpone frente al lente de la cámara.
	var p_jug := cam.to_local(centro)
	var d_jug := -p_jug.z
	for sprite in vegetacion:
		if not is_instance_valid(sprite) or not sprite.is_visible_in_tree(): continue
		var escala_y := sprite.global_basis.y.length()
		var escala_x := maxf(sprite.global_basis.x.length(), escala_y * 0.85)
		var alto := sprite.texture.get_height() * sprite.pixel_size * escala_y
		var ancho := sprite.texture.get_width() * sprite.pixel_size * escala_x
		var p_spr := cam.to_local(sprite.global_position)
		var d_spr := -p_spr.z
		var tapa := false
		if d_spr > 0.15 and d_spr < d_jug - 0.15 and d_jug > 0.5:
			var t_ray := d_spr / d_jug
			var x_ray := p_jug.x * t_ray
			var y_ray := p_jug.y * t_ray
			tapa = absf(x_ray - p_spr.x) <= (ancho * 0.42 + 0.25) and absf(y_ray - p_spr.y) <= (alto * 0.45 + 0.30)
		if not tapa and es_world and cam.name in ["Camera4", "Camera5"] and d_spr > 0.05 and d_spr < 4.5:
			# En Camera4/Camera5 atenuar solo árboles pegados al lente que taparían el sendero.
			if absf(p_spr.x) <= d_spr * 0.55 + 0.45:
				tapa = true
		sprite.transparency = move_toward(sprite.transparency, (0.78 if es_world else 0.68) if tapa else 0.0, _delta * 3.2)
		sprite.modulate.a = 1.0 - sprite.transparency
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED if sprite.transparency > 0.02 else SpriteBase3D.ALPHA_CUT_DISCARD


func _camara_por_switches_world(pos: Vector3) -> Camera3D:
	var nombre := "Camera2"
	if pos.z < 4.98 and pos.x > -10.0:
		nombre = "Camera1"
	elif pos.x < -15.48:
		nombre = "Camera6"
	elif pos.x < -7.98:
		nombre = "Camera5"
	elif pos.x > 24.86:
		nombre = "Camera4"
	elif pos.x > 5.14:
		nombre = "Camera3"
	return zona.get_node_or_null(nombre) as Camera3D




func _encuadra(cam: Camera3D, jugador: Node3D, margen: float) -> bool:
	var area := get_viewport().get_visible_rect().size
	var seguro := Rect2(area * margen, area * (1.0 - 2.0 * margen))
	for altura in [-0.8, 1.1]:
		var punto: Vector3 = jugador.global_position + Vector3.UP * float(altura)
		if cam.is_position_behind(punto) or not seguro.has_point(cam.unproject_position(punto)): return false
	return true

func _sector_preferido(jugador: Node3D, actual: Camera3D) -> Camera3D:
	# Si una cámara principal cercana (Camera1..N) encuadra bien al jugador, priorizarla
	# para evitar saltar a un Sector_* justo antes de entrar al volumen de esa cámara principal.
	var area := get_viewport().get_visible_rect().size
	var centro_jug := jugador.global_position + Vector3.UP * 0.45
	var mejor_principal: Camera3D = null
	var mejor_uv_principal := INF
	for cam in zona.find_children("*", "Camera3D", true, false):
		if cam.get_parent() != zona and cam.get_parent().name != "Cameras": continue
		if cam.has_meta("sector_centro") or cam == actual: continue
		if cam.global_position.distance_to(centro_jug) > 20.0: continue
		if not _encuadra(cam, jugador, 0.14): continue
		var uv: Vector2 = cam.unproject_position(centro_jug) / area
		var d := uv.distance_squared_to(Vector2(0.5, 0.5))
		if d < mejor_uv_principal:
			mejor_uv_principal = d
			mejor_principal = cam
	if mejor_principal != null:
		return mejor_principal

	var punto := Vector2(jugador.global_position.x, jugador.global_position.z)
	for margen_req in [0.14, 0.08]:
		var mejor: Camera3D = null
		var valor_mejor := INF
		var valor_actual := INF
		for cam in zona.find_children("*", "Camera3D", true, false):
			if not cam.has_meta("sector_centro"): continue
			var centro: Vector2 = cam.get_meta("sector_centro")
			var radio: Vector2 = cam.get_meta("sector_radio")
			var distancia := (punto - centro) / radio
			if absf(distancia.x) > 1.15 or absf(distancia.y) > 1.15: continue
			if not _encuadra(cam, jugador, margen_req): continue
			var valor := distancia.length_squared()
			if cam == actual: valor_actual = valor
			if valor < valor_mejor:
				mejor = cam
				valor_mejor = valor
		if mejor != null:
			# Histéresis espacial: no alternar al detenerse junto al límite entre dos tramos.
			if valor_actual < INF and valor_actual <= valor_mejor + 0.22: return actual
			return mejor
	return null
