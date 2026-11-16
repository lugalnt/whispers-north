extends Node3D
## Cierra únicamente el perímetro de la unión de suelos, no sus juntas internas.
var regiones: Array[Rect2] = []
var altura_suelo := 0.0

func _ready() -> void:
	var pisos: Array[CSGBox3D] = []
	for nodo in get_parent().get_children():
		if nodo is CSGBox3D and String(nodo.name).begins_with("Piso"):
			pisos.append(nodo)
	if pisos.is_empty(): return
	var xs: Array[float] = []
	var zs: Array[float] = []
	for piso in pisos:
		var tam: Vector3 = piso.size * piso.global_basis.get_scale()
		var centro: Vector3 = piso.global_position
		var rect := Rect2(Vector2(centro.x - tam.x / 2, centro.z - tam.z / 2), Vector2(tam.x, tam.z))
		regiones.append(rect)
		for x in [rect.position.x, rect.end.x]:
			if not xs.has(x): xs.append(x)
		for z in [rect.position.y, rect.end.y]:
			if not zs.has(z): zs.append(z)
		altura_suelo = centro.y + tam.y / 2
		# Extensión exclusivamente visual: el límite jugable conserva su colisión.
		var fondo := MeshInstance3D.new()
		var plano := PlaneMesh.new()
		plano.size = Vector2(tam.x + 100, tam.z + 100)
		fondo.mesh = plano
		var mat: StandardMaterial3D = piso.material.duplicate()
		mat.albedo_color = Color(0.6, 0.68, 0.64, 1)
		mat.uv1_triplanar = true
		mat.uv1_scale = Vector3.ONE * 0.25
		fondo.material_override = mat
		fondo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(fondo)
		fondo.global_position = Vector3(centro.x, altura_suelo - 0.08 - pisos.find(piso) * 0.01, centro.z)
	xs.sort()
	zs.sort()
	for i in range(xs.size() - 1):
		for j in range(zs.size() - 1):
			var centro := Vector2((xs[i] + xs[i+1]) / 2, (zs[j] + zs[j+1]) / 2)
			if not contiene(centro): continue
			var ancho := xs[i+1] - xs[i]
			var largo := zs[j+1] - zs[j]
			for lado in [-1, 1]:
				var x := xs[i] if lado < 0 else xs[i+1]
				if not contiene(Vector2(x + lado * 0.02, centro.y)):
					_pared(Vector3(x, altura_suelo + 2, centro.y), Vector3(0.3, 4, largo + 0.2))
				var z := zs[j] if lado < 0 else zs[j+1]
				if not contiene(Vector2(centro.x, z + lado * 0.02)):
					_pared(Vector3(centro.x, altura_suelo + 2, z), Vector3(ancho + 0.2, 4, 0.3))

	_crear_bosque_distante()

func contiene(punto: Vector2) -> bool:
	for rect in regiones:
		if rect.has_point(punto): return true
	return false

func _pared(pos: Vector3, tam: Vector3) -> void:
	var cuerpo := StaticBody3D.new()
	cuerpo.collision_layer = 1
	cuerpo.collision_mask = 0
	var colision := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tam
	colision.shape = forma
	cuerpo.add_child(colision)
	add_child(cuerpo)
	cuerpo.global_position = pos

func _crear_bosque_distante() -> void:
	var rutas := [
		"res://assets/sprites/environment/nordic_props_v1/nordic_pine.png",
		"res://assets/sprites/environment/trees/tree1_snowy.png",
		"res://assets/sprites/environment/trees/tree1.png",
		"res://assets/sprites/environment/nordic_props_v1/dense_bush.png",
		"res://assets/sprites/environment/nordic_props_v1/grass_tuft.png",
		"res://assets/sprites/environment/nordic_props_v1/mossy_rock.png",
		"res://assets/sprites/environment/nordic_props_v1/snow_bank.png"]
	var texturas: Array[Texture2D] = []
	var recortes: Array[Rect2i] = []
	for ruta in rutas:
		var textura: Texture2D = load(ruta)
		texturas.append(textura)
		recortes.append(textura.get_image().get_used_rect())
	var contorno := regiones[0]
	for rect in regiones: contorno = contorno.merge(rect)
	var bosque := Node3D.new()
	bosque.name = "BosqueDistante"
	add_child(bosque)
	var rng := RandomNumberGenerator.new()
	rng.seed = 16112026 + (37 if get_parent().scene_file_path.ends_with("World_Town.tscn") else 0)
	var area := contorno.grow(34)
	var posiciones: Array[Vector2] = []
	# Muestreo continuo: nunca alinear troncos en una cuadrícula.
	# Los grupos añaden densidad local sin producir anillos regulares.
	for intento in 2600:
		var punto := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		if not _zona_bosque(punto): continue
		var libre := true
		for otro in posiciones:
			if otro.distance_squared_to(punto) < 5.0:
				libre = false
				break
		if not libre: continue
		posiciones.append(punto)
		var especie := 0 if rng.randf() < 0.68 else (1 if rng.randf() < 0.7 else 2)
		var altura := rng.randf_range(4.3, 8.8)
		if rng.randf() < 0.12: altura *= 1.25
		_sprite_bosque(bosque, texturas[especie], recortes[especie], punto, altura, rng, false)
		# Sotobosque en pequeños grupos, no un objeto idéntico por árbol.
		if rng.randf() < 0.62:
			for miembro in rng.randi_range(2, 4):
				var decor := punto + Vector2(rng.randf_range(-2.5, 2.5), rng.randf_range(-2.5, 2.5))
				if not _zona_bosque(decor): continue
				var tipo := rng.randi_range(3, 6)
				var alto := rng.randf_range(0.45, 1.2) if tipo != 3 else rng.randf_range(0.9, 1.8)
				_sprite_bosque(bosque, texturas[tipo], recortes[tipo], decor, alto, rng, true)
		if posiciones.size() >= 650: break
	bosque.set_meta("arboles", posiciones.size())
	bosque.set_meta("decoraciones", bosque.get_child_count() - posiciones.size())

func _zona_bosque(punto: Vector2) -> bool:
	var cerca := false
	for rect in regiones:
		if rect.grow(9).has_point(punto): return false
		cerca = cerca or rect.grow(32).has_point(punto)
	return cerca

func _sprite_bosque(bosque: Node3D, textura: Texture2D, recorte: Rect2i, punto: Vector2, altura: float, rng: RandomNumberGenerator, bajo: bool) -> void:
	var sprite := Sprite3D.new()
	sprite.texture = textura
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	sprite.pixel_size = altura / maxf(recorte.size.y, 1)
	sprite.flip_h = rng.randf() < 0.5
	sprite.scale.x = rng.randf_range(0.82, 1.12)
	var tono := rng.randf_range(0.82, 1.05)
	sprite.modulate = Color(0.52 * tono, 0.65 * tono, 0.64 * tono, 1) if not bajo else Color(0.65 * tono, 0.73 * tono, 0.68 * tono, 1)
	bosque.add_child(sprite)
	var pie := (textura.get_height() * 0.5 - recorte.end.y) * sprite.pixel_size
	sprite.global_position = Vector3(punto.x, altura_suelo - pie - 0.12, punto.y)
