extends CharacterBody3D

const SPEED = 5.0
@onready var anim_sprite = $Sprite2_5D

# Estado de interacción: bloquea el movimiento mientras suena la animación de interactuar
var is_interacting: bool = false
# Última dirección de entrada (para saber hacia dónde mira el personaje). Por defecto: abajo
var last_input_dir: Vector2 = Vector2(0, 1)

# Obtenemos la gravedad estándar del proyecto
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	add_to_group("player")
	# Las animaciones de interacción se reproducen una sola vez (para poder esperar a que terminen)
	var frames: SpriteFrames = anim_sprite.sprite_frames
	if frames:
		for anim_name in frames.get_animation_names():
			if String(anim_name).begins_with("interact_"):
				frames.set_animation_loop(anim_name, false)

func _physics_process(delta):
	# 1. APLICAR GRAVEDAD (Para que no flote ni se resbale)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Durante una interacción el personaje se queda quieto reproduciendo su animación
	if is_interacting:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	# 2. MOVIMIENTO RELATIVO A LA CÁMARA
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = Vector3.ZERO
	
	# Busca la cámara actual en la escena
	var camera = get_viewport().get_camera_3d()
	
	if camera != null:
		# Calcula el movimiento basado en hacia dónde mira la cámara
		var cam_forward = -camera.global_transform.basis.z
		var cam_right = camera.global_transform.basis.x
		
		# Ignoramos la altura (Y) de la cámara para que no vuele si la cámara mira hacia abajo
		cam_forward.y = 0
		cam_right.y = 0
		cam_forward = cam_forward.normalized()
		cam_right = cam_right.normalized()
		
		direction = (cam_right * input_dir.x + cam_forward * -input_dir.y).normalized()
	else:
		# Fallback por si no hay cámara
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# 3. APLICAR VELOCIDAD Y ANIMACIÓN
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		update_animation(input_dir)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		anim_sprite.stop() 
		# Ojo: si prefieres que tenga animación de respirar cuando esté quieto, usa: anim_sprite.play("idle")

	move_and_slide()

func update_animation(input_dir: Vector2):
	last_input_dir = input_dir
	var dir_info = _resolve_direction(input_dir)
	anim_sprite.flip_h = dir_info.flip
	anim_sprite.play("walk_" + dir_info.suffix)

# Convierte un vector de entrada (8 direcciones) en sufijo de animación y flip horizontal
func _resolve_direction(input_dir: Vector2) -> Dictionary:
	var angle = rad_to_deg(input_dir.angle())
	
	if angle >= -22.5 and angle < 22.5:
		return {"suffix": "side", "flip": false}
	elif angle >= 22.5 and angle < 67.5:
		return {"suffix": "down_side", "flip": false}
	elif angle >= 67.5 and angle < 112.5:
		return {"suffix": "down", "flip": false}
	elif angle >= 112.5 and angle < 157.5:
		return {"suffix": "down_side", "flip": true}
	elif angle >= 157.5 or angle < -157.5:
		return {"suffix": "side", "flip": true}
	elif angle >= -157.5 and angle < -112.5:
		return {"suffix": "up_side", "flip": true}
	elif angle >= -112.5 and angle < -67.5:
		return {"suffix": "up", "flip": false}
	return {"suffix": "up_side", "flip": false}

# Convierte una dirección del mundo (plano XZ) al espacio de entrada relativo a la cámara
func _world_dir_to_input(world_dir: Vector3) -> Vector2:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return Vector2(world_dir.x, world_dir.z)
	var cam_forward = -camera.global_transform.basis.z
	var cam_right = camera.global_transform.basis.x
	cam_forward.y = 0
	cam_right.y = 0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()
	return Vector2(world_dir.dot(cam_right), -world_dir.dot(cam_forward))

# Reproduce la animación de interacción (interact_*) mirando hacia target_position (si se indica).
# Se puede usar con await: termina cuando acaba la animación. Si el modelo no tiene
# animaciones de interacción (p. ej. el de 32x32 por ahora), regresa de inmediato.
func play_interact(target_position = null) -> void:
	if is_interacting:
		return
	
	var frames: SpriteFrames = anim_sprite.sprite_frames
	if frames == null or not frames.has_animation("interact_down"):
		return
	
	# Orientar al personaje hacia el objeto con el que interactúa
	if target_position is Vector3:
		var to_target: Vector3 = target_position - global_position
		to_target.y = 0
		if to_target.length() > 0.05:
			last_input_dir = _world_dir_to_input(to_target.normalized())
	
	var dir_info = _resolve_direction(last_input_dir)
	var anim_name = "interact_" + dir_info.suffix
	if not frames.has_animation(anim_name):
		return
	
	is_interacting = true
	anim_sprite.flip_h = dir_info.flip
	anim_sprite.play(anim_name)
	await anim_sprite.animation_finished
	
	# Dejar al personaje en pose de reposo mirando hacia la misma dirección
	anim_sprite.play("walk_" + dir_info.suffix)
	anim_sprite.stop()
	is_interacting = false

# Función invocada por la puerta para cambiar la versión del personaje entre 16x16 y 32x32
func toggle_sprite_size() -> void:
	var world = get_tree().current_scene
	if world and world.has_method("toggle_player_character"):
		world.toggle_player_character()

# --- Menú de Pausa Global para el Jugador ---
@export var escena_menu_pausa: PackedScene = preload("res://scenes/ui/PauseMenu.tscn")
var _menu_pausa: PauseMenu = null

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not event.is_echo():
		if is_interacting:
			return
		var menu = _asegurar_menu_pausa()
		if menu and not menu.visible:
			get_viewport().set_input_as_handled()
			# Sincronizar rata en GameState
			var tiene_rata: bool = false
			for child in get_children():
				if child.name.begins_with("Rat") or child.is_in_group("rat"):
					tiene_rata = true
					break
			var gs = _obtener_game_state()
			if gs:
				gs.tiene_rata = tiene_rata
			menu.abrir_menu()

func _asegurar_menu_pausa() -> PauseMenu:
	if _menu_pausa != null and is_instance_valid(_menu_pausa):
		return _menu_pausa
	
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var root: Node = tree.root if tree else null
	if root == null:
		var p = get_parent()
		while p != null:
			if p.get_parent() == null:
				root = p
				break
			p = p.get_parent()
	
	if root:
		var existente = root.find_child("PauseMenu", true, false)
		if existente is PauseMenu:
			_menu_pausa = existente
			return _menu_pausa
	
	if escena_menu_pausa:
		_menu_pausa = escena_menu_pausa.instantiate() as PauseMenu
		var cur_scene = tree.current_scene if tree else null
		if cur_scene:
			cur_scene.add_child(_menu_pausa)
		elif root:
			root.add_child(_menu_pausa)
	return _menu_pausa

func _obtener_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var root: Node = null
	if is_inside_tree() and get_tree():
		root = get_tree().root
	elif Engine.get_main_loop() and "root" in Engine.get_main_loop():
		root = Engine.get_main_loop().root
	else:
		var p = get_parent()
		while p != null:
			if p.has_node("GameState"):
				return p.get_node("GameState")
			if p.get_parent() == null:
				root = p
				break
			p = p.get_parent()
	
	if root and root.has_node("GameState"):
		return root.get_node("GameState")
	if root and not root.has_node("GameState"):
		var gs_res = load("res://scripts/core/game_state.gd")
		if gs_res:
			var gs_inst = gs_res.new()
			gs_inst.name = "GameState"
			root.add_child(gs_inst)
			return gs_inst
	return null
