extends Sprite3D
## Vistas estáticas del padre: frente, derecha, espalda e izquierda.
const HOJA := preload("res://assets/sprites/player/Erland (Padre)/nordic_v1/erland_idle_directions.png")
const ALTURA := 1.9
var _vistas: Array[AtlasTexture] = []
var _vista := -1

func _ready() -> void:
	var imagen := HOJA.get_image()
	for celda in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		var origen: Vector2i = celda * 627
		var limites := imagen.get_region(Rect2i(origen, Vector2i(627, 627))).get_used_rect()
		var atlas := AtlasTexture.new()
		atlas.atlas = HOJA
		atlas.region = Rect2(limites.position + origen, limites.size)
		atlas.filter_clip = true
		_vistas.append(atlas)
	_mostrar(0)

func _process(_delta: float) -> void:
	var mundo := get_tree().current_scene
	if mundo == null or not mundo.has_method("get_active_player"):
		return
	var jugador: Node3D = mundo.get_active_player()
	var camara := get_viewport().get_camera_3d()
	if not is_instance_valid(jugador) or camara == null:
		return
	var hacia: Vector3 = jugador.global_position - get_parent().global_position
	hacia.y = 0
	if hacia.length() > 2.5 or hacia.length() < 0.15:
		_mostrar(0)
		return
	var derecha := camara.global_basis.x
	var frente := camara.global_basis.z
	frente.y = 0
	frente = frente.normalized()
	var x := hacia.dot(derecha)
	var z := hacia.dot(frente)
	_mostrar((1 if x > 0 else 3) if absf(x) > absf(z) else (0 if z > 0 else 2))

func _mostrar(indice: int) -> void:
	if indice == _vista:
		return
	_vista = indice
	texture = _vistas[indice]
	pixel_size = ALTURA / texture.get_height()
	position.y = ALTURA * 0.5 + 0.05

