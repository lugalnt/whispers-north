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
		var fondo: float = (float(tex.get_height()) * 0.5 - float(rect.end.y) + sprite.offset.y) * sprite.pixel_size * sprite.global_basis.get_scale().y
		sprite.global_position.y = hit.position.y - fondo - 0.06
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
		if not cam.has_meta("sector_centro"):
			_espera_cambio = maxf(_espera_cambio, 0.45)
	elif jugador.global_position.distance_to(_pos_ancla_cam) > 1.5 and not _encuadra(cam, jugador, 0.04):
		_espera_cambio = 0.0
	# Encuadres inmutables: mantener la cámara actual mientras encuadre bien al jugador,
	# evitando saltos rápidos por cámaras intermedias en caminos rectos.
	if not ("is_interacting" in jugador and jugador.is_interacting):
		_espera_cambio = maxf(0.0, _espera_cambio - _delta)
	var centro := jugador.global_position + Vector3.UP * 0.45
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
	# Atenuar vegetación que tapa al personaje, manteniendo el resto del bosque.
	var pantalla := cam.unproject_position(centro)
	for sprite in vegetacion:
		if not is_instance_valid(sprite) or not sprite.is_visible_in_tree(): continue
		var alto := sprite.texture.get_height() * sprite.pixel_size * sprite.global_basis.get_scale().y
		var ancho := sprite.texture.get_width() * sprite.pixel_size * sprite.global_basis.get_scale().x
		var a := cam.unproject_position(sprite.global_position + Vector3.UP * alto * 0.5 - cam.global_basis.x * ancho * 0.5)
		var b := cam.unproject_position(sprite.global_position - Vector3.UP * alto * 0.5 + cam.global_basis.x * ancho * 0.5)
		var tapa := Rect2(a, b - a).abs().grow(10).has_point(pantalla) and cam.global_position.distance_squared_to(sprite.global_position) < cam.global_position.distance_squared_to(centro)
		sprite.transparency = move_toward(sprite.transparency, 0.35 if tapa else 0.0, _delta * 1.5)




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
