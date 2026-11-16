extends Node
## Ajustes visuales: no mueve las colisiones, marcadores ni las cámaras de combate.
var vegetacion: Array[Sprite3D] = []
var bases: Dictionary = {}
var zona: Node3D

func _ready() -> void:
	zona = get_parent()
	process_priority = 90
	await get_tree().physics_frame
	await get_tree().physics_frame
	var excluidos: Array[RID] = []
	for body in zona.find_children("*", "CollisionObject3D", true, false):
		excluidos.append(body.get_rid())
	var limites: Dictionary = {}
	for sprite in zona.find_children("*", "Sprite3D", true, false):
		var fuente: Node = sprite
		while fuente != zona and fuente.scene_file_path.is_empty(): fuente = fuente.get_parent()
		if not (fuente.scene_file_path.get_file() in ["Tree.tscn", "Tree_Pine.tscn", "Bush.tscn"] or "/NordicProps/" in fuente.scene_file_path): continue
		if sprite.texture == null: continue
		var tex: Texture2D = sprite.texture
		if not limites.has(tex): limites[tex] = tex.get_image().get_used_rect()
		var rect: Rect2i = limites[tex]
		var query := PhysicsRayQueryParameters3D.create(sprite.global_position + Vector3.UP * 5, sprite.global_position - Vector3.UP * 40, 1, excluidos)
		var hit := zona.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty(): continue
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		var fondo: float = (float(tex.get_height()) * 0.5 - float(rect.end.y) + sprite.offset.y) * sprite.pixel_size * sprite.global_basis.get_scale().y
		sprite.global_position.y = hit.position.y - fondo + 0.015
		vegetacion.append(sprite)

func _process(_delta: float) -> void:
	if not zona.has_method("get_active_player"): return
	var jugador: Node3D = zona.get_active_player()
	var cam := get_viewport().get_camera_3d()
	if jugador == null or cam == null or not jugador.is_visible_in_tree(): return
	# Las cámaras de exploración pertenecen directamente a la zona.
	if cam.get_parent() != zona and cam.get_parent().name != "Cameras": return
	if not bases.has(cam): bases[cam] = cam.global_transform
	var area := get_viewport().get_visible_rect().size
	var centro := jugador.global_position + Vector3.UP * 0.45
	var punto := cam.unproject_position(centro)
	var seguro := Rect2(area * Vector2(0.2, 0.2), area * Vector2(0.6, 0.55))
	if cam.is_position_behind(centro) or not seguro.has_point(punto):
		var base: Transform3D = bases[cam]
		var altura := clampf(cam.global_position.y - centro.y, 1.5, 10.0)
		var atras := Vector3(base.basis.z.x, 0, base.basis.z.z).normalized()
		if atras.is_zero_approx(): atras = Vector3.BACK
		cam.global_position = centro + atras * altura * 1.732 + Vector3.UP * altura
		cam.look_at(centro)
	# Atenuar vegetación que tapa al personaje, manteniendo el resto del bosque.
	var pantalla := cam.unproject_position(centro)
	for sprite in vegetacion:
		if not is_instance_valid(sprite) or not sprite.is_visible_in_tree(): continue
		var alto := sprite.texture.get_height() * sprite.pixel_size * sprite.global_basis.get_scale().y
		var ancho := sprite.texture.get_width() * sprite.pixel_size * sprite.global_basis.get_scale().x
		var a := cam.unproject_position(sprite.global_position + Vector3.UP * alto * 0.5 - cam.global_basis.x * ancho * 0.5)
		var b := cam.unproject_position(sprite.global_position - Vector3.UP * alto * 0.5 + cam.global_basis.x * ancho * 0.5)
		var tapa := Rect2(a, b - a).abs().grow(10).has_point(pantalla) and cam.global_position.distance_squared_to(sprite.global_position) < cam.global_position.distance_squared_to(centro)
		sprite.transparency = 0.8 if tapa else 0.0



