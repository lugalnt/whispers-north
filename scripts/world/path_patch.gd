@tool
class_name PathPatch
extends Node3D
## Convierte una escena 2D pintada con TileMapLayer (ej. Path.tscn) en un
## parche plano 3D (Sprite3D en el suelo), usando un SubViewport interno.
##
## Uso:
##   1. Pinta tu camino en una escena 2D con un TileMapLayer (tileset de caminos).
##   2. En el mundo 3D añade un nodo `PathPatch` y asigna esa escena a `source_scene`.
##   3. Muévelo / rótalo / escálalo con las herramientas normales del editor 3D.
##
## El viewport, el Sprite3D y la copia de la escena fuente se crean por código
## como hijos internos: no se guardan en la escena, solo `source_scene` y los
## parámetros exportados. Así cada instancia es independiente y ligera.

## Escena 2D con uno o más TileMapLayer ya pintados.
@export var source_scene: PackedScene:
	set(value):
		source_scene = value
		_rebuild()

## Tamaño en metros de UN tile en el mundo 3D. Para escalar el parche completo
## puedes usar esto o simplemente la escala del nodo (Scale).
@export_range(0.05, 16.0, 0.05, "or_greater") var meters_per_tile: float = 0.5:
	set(value):
		meters_per_tile = value
		_apply_pixel_size()

## Tiles vacíos extra alrededor del dibujo (por si quieres margen).
@export_range(0, 16) var padding_tiles: int = 0:
	set(value):
		padding_tiles = value
		_rebuild()

## Si el parche recibe iluminación de la escena.
@export var shaded: bool = true:
	set(value):
		shaded = value
		if _sprite:
			_sprite.shaded = value

## Prioridad de render. Negativo = se dibuja debajo (evita z-fighting con el suelo).
@export var render_priority: int = -1:
	set(value):
		render_priority = value
		if _sprite:
			_sprite.render_priority = value

## En juego, congela el viewport tras renderizar una vez (ahorra GPU).
@export var freeze_at_runtime: bool = true

## Recarga la escena fuente (úsalo tras editar y guardar la escena 2D).
@warning_ignore("unused_private_class_variable")
@export_tool_button("Refrescar", "Reload") var _refresh_button = _rebuild

const MAX_VIEWPORT_SIZE := 4096

var _viewport: SubViewport
var _sprite: Sprite3D
var _holder: Node2D
var _tile_size := Vector2i(8, 8)


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.gui_disable_input = true
	_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport, false, Node.INTERNAL_MODE_FRONT)

	_sprite = Sprite3D.new()
	_sprite.axis = Vector3.AXIS_Y
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sprite.shaded = shaded
	_sprite.render_priority = render_priority
	_sprite.texture = _viewport.get_texture()
	add_child(_sprite, false, Node.INTERNAL_MODE_BACK)

	_rebuild()


func _rebuild() -> void:
	# Los setters pueden llamarse antes de _ready (al cargar la escena).
	if not is_node_ready() or _viewport == null:
		return

	if is_instance_valid(_holder):
		_holder.free()
	_holder = null

	if source_scene == null:
		_sprite.visible = false
		return

	var source := source_scene.instantiate()
	_holder = Node2D.new()
	_holder.add_child(source)
	_viewport.add_child(_holder)

	# Ignora transformaciones de la raíz (p. ej. el scale=4 de Path.tscn): aquí
	# el tamaño en el mundo lo controlan meters_per_tile y la escala del nodo.
	if source is Node2D:
		var source_2d := source as Node2D
		source_2d.position = Vector2.ZERO
		source_2d.scale = Vector2.ONE

	var bounds := _compute_pixel_bounds(source)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		_sprite.visible = false
		push_warning("PathPatch '%s': la escena fuente no tiene tiles pintados." % name)
		return

	bounds = bounds.grow(padding_tiles * _tile_size.x)
	var size := Vector2i(bounds.size)
	if size.x > MAX_VIEWPORT_SIZE or size.y > MAX_VIEWPORT_SIZE:
		push_warning("PathPatch '%s': dibujo demasiado grande (%s), se recorta a %d px." % [name, size, MAX_VIEWPORT_SIZE])
		size = size.clamp(Vector2i.ONE, Vector2i(MAX_VIEWPORT_SIZE, MAX_VIEWPORT_SIZE))

	_holder.position = -bounds.position
	_viewport.size = size
	_sprite.visible = true
	_apply_pixel_size()

	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_freeze_after_render()


func _apply_pixel_size() -> void:
	if _sprite:
		_sprite.pixel_size = meters_per_tile / float(_tile_size.x)


## Unión (en píxeles) de las áreas usadas de todos los TileMapLayer de la fuente.
func _compute_pixel_bounds(source: Node) -> Rect2:
	var result := Rect2()
	var has_any := false
	for layer: TileMapLayer in _find_layers(source):
		if layer.tile_set == null:
			continue
		var used := layer.get_used_rect()
		if used.size == Vector2i.ZERO:
			continue
		var ts := layer.tile_set.tile_size
		if not has_any:
			_tile_size = ts
		var offset := Vector2.ZERO if layer == source else layer.position
		var rect := Rect2(Vector2(used.position * ts) + offset, Vector2(used.size * ts))
		result = rect if not has_any else result.merge(rect)
		has_any = true
	return result


func _find_layers(node: Node) -> Array[TileMapLayer]:
	var found: Array[TileMapLayer] = []
	if node is TileMapLayer:
		found.append(node)
	for child in node.get_children():
		found.append_array(_find_layers(child))
	return found


func _freeze_after_render() -> void:
	if Engine.is_editor_hint() or not freeze_at_runtime:
		return
	# Espera a que los tiles se dibujen antes de congelar el viewport.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if is_instance_valid(_viewport):
		_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
