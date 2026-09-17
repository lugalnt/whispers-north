extends CharacterBody3D

const SPEED = 5.0
@onready var anim_sprite = $Sprite2_5D

# Obtenemos la gravedad estándar del proyecto
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	# 1. APLICAR GRAVEDAD (Para que no flote ni se resbale)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. MOVIMIENTO RELATIVO A LA CÁMARA
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
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
	var angle = rad_to_deg(input_dir.angle())
	anim_sprite.flip_h = false
	
	if angle >= -22.5 and angle < 22.5:
		anim_sprite.play("walk_side")
	elif angle >= 22.5 and angle < 67.5:
		anim_sprite.play("walk_down_side")
	elif angle >= 67.5 and angle < 112.5:
		anim_sprite.play("walk_down")
	elif angle >= 112.5 and angle < 157.5:
		anim_sprite.play("walk_down_side")
		anim_sprite.flip_h = true
	elif angle >= 157.5 or angle < -157.5:
		anim_sprite.play("walk_side")
		anim_sprite.flip_h = true
	elif angle >= -157.5 and angle < -112.5:
		anim_sprite.play("walk_up_side")
		anim_sprite.flip_h = true
	elif angle >= -112.5 and angle < -67.5:
		anim_sprite.play("walk_up")
	elif angle >= -67.5 and angle < -22.5:
		anim_sprite.play("walk_up_side")
