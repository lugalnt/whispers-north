@tool
class_name ItemPickup3D
extends Area3D

## Objeto interactivo / coleccionable en el mundo 3D.
## Totalmente configurable desde el Inspector de Godot:
## - Arrastra cualquier InventoryItem (.tres) al campo 'item'.
## - El sprite 3D se actualiza automáticamente en el editor y en el juego.
## - Puede recogerse automáticamente al tocarlo o pulsando la tecla/botón 'interact'.

signal recogido(item: InventoryItem, cantidad: int)

@export_group("Objeto a Recoger")
## Recurso de ítem (.tres) asignado a este coleccionable del mundo
@export var item: InventoryItem:
	set(nuevo_item):
		item = nuevo_item
		_actualizar_visual()

## Cantidad otorgada al recoger este objeto
@export_range(1, 999, 1) var cantidad: int = 1

@export_group("Comportamiento")
## Si es true, se recoge al entrar en contacto con el jugador. Si es false, requiere pulsar 'interact'.
@export var auto_recoger: bool = true
## Tiempo de inmunidad antes de poder ser recogido (evita que se recoja instantáneamente tras un combate o drop)
@export var tiempo_espera_recoleccion: float = 0.6
## Si es true, el ítem flota suavemente arriba y abajo
@export var animar_flotacion: bool = true
@export var velocidad_flotacion: float = 3.0
@export var amplitud_flotacion: float = 0.12
## Tiempo en segundos antes de desaparecer (0 = nunca desaparece)
@export var tiempo_vida: float = 0.0

@export_group("Visual y Efectos")
@export var sfx_recoger: AudioStream = preload("res://assets/audio/sfx/snd_item.wav")
@export var mostrar_texto_flotante: bool = true
@export var formato_texto_recogido: String = "+%d %s"
@export var color_texto: Color = Color(1.0, 0.88, 0.3)

@onready var sprite: Sprite3D = $Sprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _pos_y_base: float = 0.0
var _tiempo_acumulado: float = 0.0
var _ya_recogido: bool = false
var _puede_recogerse: bool = false
var _jugador_en_rango: Node3D = null

func _ready() -> void:
	_pos_y_base = position.y
	_actualizar_visual()
	
	# Tamaño base más pequeño de 32x32 píxeles (escala 0.5 respecto al sprite original de 64x64)
	if scale == Vector3.ONE:
		scale = Vector3(0.5, 0.5, 0.5)
	
	if Engine.is_editor_hint():
		return
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	if tiempo_espera_recoleccion > 0.0:
		_puede_recogerse = false
		get_tree().create_timer(tiempo_espera_recoleccion).timeout.connect(_activar_recoleccion)
	else:
		_puede_recogerse = true
	
	if tiempo_vida > 0.0:
		get_tree().create_timer(tiempo_vida).timeout.connect(func():
			if not _ya_recogido and is_instance_valid(self):
				var tw = create_tween()
				tw.tween_property(self, "scale", Vector3.ONE * 0.001, 0.3)
				tw.tween_callback(queue_free)
		)

func _activar_recoleccion() -> void:
	if _ya_recogido or not is_instance_valid(self):
		return
	_puede_recogerse = true
	if not is_inside_tree():
		return
	for body in get_overlapping_bodies():
		if _es_jugador(body):
			if auto_recoger:
				recoger(body)
				return
			else:
				_jugador_en_rango = body

func _process(delta: float) -> void:
	if animar_flotacion and not Engine.is_editor_hint():
		_tiempo_acumulado += delta * velocidad_flotacion
		position.y = _pos_y_base + sin(_tiempo_acumulado) * amplitud_flotacion

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or _ya_recogido or auto_recoger or not _puede_recogerse:
		return
	if _jugador_en_rango and event.is_action_pressed("interact") and not event.is_echo():
		get_viewport().set_input_as_handled()
		recoger(_jugador_en_rango)

func _actualizar_visual() -> void:
	if not is_instance_valid(sprite):
		sprite = get_node_or_null("Sprite3D") as Sprite3D
	if sprite != null:
		if item != null and item.icono != null:
			sprite.texture = item.icono
		elif sprite.texture == null:
			sprite.texture = preload("res://assets/sprites/items/placeholder.png")

func _on_body_entered(body: Node3D) -> void:
	if _ya_recogido:
		return
	if _es_jugador(body):
		if not _puede_recogerse:
			return
		if auto_recoger:
			recoger(body)
		else:
			_jugador_en_rango = body

func _on_body_exited(body: Node3D) -> void:
	if _jugador_en_rango == body:
		_jugador_en_rango = null

func _es_jugador(node: Node) -> bool:
	if node == null:
		return false
	return node.is_in_group("player") or node is CharacterBody3D or node.name.to_lower().contains("player") or node.name.to_lower().contains("eric")

## Ejecuta la recolección del objeto, lo agrega al inventario y muestra retroalimentación visual/sonora
func recoger(_jugador: Node3D = null) -> void:
	if _ya_recogido:
		return
	_ya_recogido = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	
	var item_a_entregar: InventoryItem = item
	if item_a_entregar == null:
		item_a_entregar = load("res://data/items/queso_nordico.tres") as InventoryItem
	
	# 1. Agregar a GameState
	var gs = _obtener_game_state()
	if gs and gs.has_method("agregar_item"):
		gs.agregar_item(item_a_entregar, cantidad)
	elif gs and "inventario" in gs and gs.inventario != null:
		gs.inventario.agregar(item_a_entregar, cantidad)
	
	# 2. SFX
	_reproducir_sfx(sfx_recoger)
	
	# 3. Notificación / texto flotante
	if mostrar_texto_flotante and item_a_entregar != null and is_inside_tree():
		var texto = formato_texto_recogido % [cantidad, item_a_entregar.nombre]
		_mostrar_texto_flotante_mundo(texto, global_position + Vector3.UP * 0.8)
	
	recogido.emit(item_a_entregar, cantidad)
	
	# 4. Animación de recogida y eliminación: se expande a 64x64 (escala 1.0) y flota hacia arriba
	if is_inside_tree():
		var tw = create_tween()
		if tw:
			tw.set_parallel(true)
			tw.tween_property(self, "position:y", position.y + 0.45, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.chain().tween_property(self, "scale", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			await tw.finished
	queue_free()

## Spawnea un ItemPickup3D en una posición dada con animación de rebote parabólico
static func spawn_en_posicion(padre: Node, pos: Vector3, item_obj: InventoryItem, cant: int = 1, con_rebote = true) -> Node:
	if padre == null or item_obj == null:
		return null
	var escena_pickup: PackedScene = load("res://scenes/world/Entities/ItemPickup.tscn") as PackedScene
	if escena_pickup == null:
		return null
	
	var pickup = escena_pickup.instantiate()
	pickup.item = item_obj
	pickup.cantidad = cant
	pickup.scale = Vector3(0.5, 0.5, 0.5)
	padre.add_child(pickup)
	pickup.global_position = pos
	
	if con_rebote is bool and con_rebote:
		var destino_x: float = pos.x + randf_range(-1.0, 1.0)
		var destino_z: float = pos.z + randf_range(-1.0, 1.0)
		var destino: Vector3 = Vector3(destino_x, pos.y, destino_z)
		
		var duracion: float = 0.55
		pickup.tiempo_espera_recoleccion = duracion + 0.15
		var tw: Tween = pickup.create_tween()
		tw.set_parallel(true)
		tw.tween_property(pickup, "global_position:x", destino.x, duracion).set_trans(Tween.TRANS_LINEAR)
		tw.tween_property(pickup, "global_position:z", destino.z, duracion).set_trans(Tween.TRANS_LINEAR)
		
		var tw_y: Tween = pickup.create_tween()
		tw_y.tween_property(pickup, "global_position:y", pos.y + 1.2, duracion * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_y.tween_property(pickup, "global_position:y", destino.y, duracion * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw_y.tween_callback(pickup._activar_recoleccion)
	elif con_rebote is Vector3:
		var destino: Vector3 = pos + con_rebote
		var duracion: float = 0.5
		pickup.tiempo_espera_recoleccion = duracion + 0.15
		var tw: Tween = pickup.create_tween()
		tw.tween_property(pickup, "global_position", destino, duracion).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(pickup._activar_recoleccion)
	
	return pickup

func _mostrar_texto_flotante_mundo(texto: String, pos_mundo: Vector3) -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	var canvas := CanvasLayer.new()
	canvas.layer = 95
	get_tree().root.add_child(canvas)
	
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", color_texto)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 5)
	canvas.add_child(lbl)
	
	var cam: Camera3D = get_viewport().get_camera_3d()
	var pos_2d: Vector2
	if cam:
		pos_2d = cam.unproject_position(pos_mundo)
	else:
		pos_2d = get_viewport().get_visible_rect().size * 0.5
	
	lbl.position = pos_2d - Vector2(lbl.size.x * 0.5, 20)
	
	var tw := lbl.create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", pos_2d.y - 60.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4).set_delay(0.5)
	tw.chain().tween_callback(canvas.queue_free)

func _reproducir_sfx(stream: AudioStream) -> void:
	if stream == null or not is_inside_tree():
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	get_tree().root.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func _obtener_game_state():
	var GS = load("res://scripts/core/game_state.gd")
	if GS and GS.instancia != null:
		return GS.instancia
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	if is_inside_tree() and get_tree() and get_tree().root.has_node("GameState"):
		return get_tree().root.get_node("GameState")
	return null
