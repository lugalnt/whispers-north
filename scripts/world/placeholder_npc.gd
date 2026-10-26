class_name PlaceholderNPC
extends CharacterBody3D

## Controlador de NPC de prueba con soporte para orientación visual hacia el jugador,
## recompensas de estadísticas (+1 ataque con fanfarria) y efecto de explosión realista.

@export_group("Visión y Reacción")
## Si es true, el NPC gira su sprite para mirar al jugador cuando este entra en el radio.
@export var mirar_al_jugador: bool = true

## Radio en metros dentro del cual el NPC detecta al jugador y gira para mirarlo.
@export var radio_vision: float = 4.5

## Margen de distancia adicional antes de dejar de mirar para evitar parpadeos en el borde.
@export var radio_desenfoque: float = 5.5

## Si es true, el NPC mantiene la mirada fija hacia el jugador durante los diálogos.
@export var mantener_mirada_en_dialogo: bool = true

@export_group("Efecto de Explosión (NPC Exp)")
## Si es true, el NPC explota de forma cómica al terminar su diálogo.
@export var explotar_al_terminar_dialogo: bool = false
@export var sfx_explosion: AudioStream = preload("res://assets/audio/sfx/snd_badexplosion.wav")
@export var textura_explosion: Texture2D = null
@export var escala_explosion: float = 0.05
@export var fps_explosion: float = 18.0

@export_group("Recompensas (NPC Útil)")
## Si es true, al terminar cada diálogo aumenta el stat de ataque del jugador por 'aumento_ataque'.
@export var aumentar_ataque_al_terminar: bool = false
@export var aumento_ataque: int = 1
@export var sfx_recompensa: AudioStream = preload("res://assets/audio/sfx/snd_moss_fanfare.wav")
## Si es true, muestra una notificación visual en pantalla y sobre el jugador al otorgar la recompensa.
@export var mostrar_mensaje_recompensa: bool = true
## Texto del mensaje mostrado al otorgar la recompensa.
@export var mensaje_recompensa: String = "Te sientes un poquito más fuerte"
## Duración en segundos que permanece visible la notificación en pantalla.
@export var duracion_toast: float = 3.6

@export_group("Desbloqueo de Ataque (NPC Útil)")
## Si es true, al agotar las interacciones del diálogo desbloquea un nuevo ataque para el jugador en combate
@export var desbloquear_ataque_al_terminar: bool = false
@export var id_ataque_a_desbloquear: String = "barrida_vortice"
@export var nombre_ataque_desbloqueado: String = "Barrida Torbellino"

@onready var sprite: AnimatedSprite3D = get_node_or_null("Sprite2_5D") as AnimatedSprite3D

var _anim_reposo: StringName = &"interact_down"
var _flip_reposo: bool = false
var _frame_reposo: int = 0
var _mirando_al_jugador: bool = false
var _en_dialogo: bool = false
var _esta_explotando: bool = false

func _ready() -> void:
	add_to_group("npc")
	
	var sp = _obtener_sprite()
	if sp:
		_anim_reposo = sp.animation
		_flip_reposo = sp.flip_h
		_frame_reposo = sp.frame
		sp.stop()
		sp.frame = _frame_reposo
	
	# Conectar con InteraccionDialogo si existe como hijo
	var dialogo = find_child("InteraccionDialogo", false, false)
	if dialogo:
		if dialogo.has_signal("dialogo_iniciado"):
			dialogo.dialogo_iniciado.connect(_on_dialogo_iniciado)
		if dialogo.has_signal("dialogo_terminado"):
			dialogo.dialogo_terminado.connect(_on_dialogo_terminado)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not mirar_al_jugador or _esta_explotando:
		return
	
	var jugador = _obtener_jugador()
	if jugador == null or not is_instance_valid(jugador):
		if _mirando_al_jugador:
			restaurar_pose_defecto()
		return
	
	var dist_sq = global_position.distance_squared_to(jugador.global_position)
	
	if _en_dialogo and mantener_mirada_en_dialogo:
		mirar_hacia(jugador.global_position)
		return
	
	if dist_sq <= (radio_vision * radio_vision):
		_mirando_al_jugador = true
		mirar_hacia(jugador.global_position)
	elif _mirando_al_jugador and dist_sq > (radio_desenfoque * radio_desenfoque):
		restaurar_pose_defecto()

func _obtener_sprite() -> AnimatedSprite3D:
	if sprite == null:
		sprite = get_node_or_null("Sprite2_5D") as AnimatedSprite3D
	return sprite

## Gira el sprite del NPC para mirar hacia una posición 3D usando el primer frame de la animación interact correspondiente
func mirar_hacia(pos_objetivo: Vector3) -> void:
	if _esta_explotando:
		return
	var sp = _obtener_sprite()
	if sp == null:
		return
	
	var my_pos = global_position if is_inside_tree() else position
	var to_target: Vector3 = pos_objetivo - my_pos
	to_target.y = 0.0
	if to_target.length_squared() < 0.01:
		return
	
	var in_dir: Vector2 = _world_dir_to_camera_input(to_target.normalized())
	var dir_info = _resolve_direction(in_dir)
	var anim_name = "interact_" + dir_info.suffix
	
	if sp.sprite_frames and sp.sprite_frames.has_animation(anim_name):
		sp.animation = anim_name
		sp.flip_h = dir_info.flip
		sp.frame = 0
		sp.stop()

## Restaura la pose y orientación de reposo original configurada en el editor
func restaurar_pose_defecto() -> void:
	if _esta_explotando:
		return
	_mirando_al_jugador = false
	var sp = _obtener_sprite()
	if sp:
		sp.animation = _anim_reposo
		sp.flip_h = _flip_reposo
		sp.frame = _frame_reposo
		sp.stop()

func _on_dialogo_iniciado() -> void:
	if _esta_explotando:
		return
	_en_dialogo = true
	var jugador = _obtener_jugador()
	if jugador:
		mirar_hacia(jugador.global_position)

func _on_dialogo_terminado() -> void:
	if _esta_explotando:
		return
	_en_dialogo = false
	
	if aumentar_ataque_al_terminar:
		_otorgar_aumento_ataque()
	
	if desbloquear_ataque_al_terminar:
		_comprobar_desbloqueo_ataque()
	
	if explotar_al_terminar_dialogo:
		explotar()
		return
	
	var jugador = _obtener_jugador()
	if jugador:
		var dist_sq = global_position.distance_squared_to(jugador.global_position)
		if dist_sq > (radio_vision * radio_vision):
			restaurar_pose_defecto()
	else:
		restaurar_pose_defecto()

func _comprobar_desbloqueo_ataque() -> void:
	var dialogo = find_child("InteraccionDialogo", false, false)
	var interacciones_agotadas: bool = false
	if dialogo != null:
		if ("maximo_interacciones" in dialogo) and ("_contador_interacciones" in dialogo):
			if dialogo._contador_interacciones >= dialogo.maximo_interacciones or not dialogo.activo:
				interacciones_agotadas = true
		elif not dialogo.activo:
			interacciones_agotadas = true
	else:
		interacciones_agotadas = true
	
	if interacciones_agotadas:
		var gs = _obtener_game_state()
		if gs and gs.has_method("desbloquear_accion") and not gs.tiene_accion(id_ataque_a_desbloquear):
			gs.desbloquear_accion(id_ataque_a_desbloquear)
			print("[PlaceholderNPC] ¡Ataque '%s' desbloqueado para el jugador!" % nombre_ataque_desbloqueado)
			if mostrar_mensaje_recompensa:
				_mostrar_mensaje_notificacion("¡Nuevo Ataque Desbloqueado!", "'%s' listo para usar en combate" % nombre_ataque_desbloqueado)

## Ejecuta la explosión cómica del NPC con la animación de realistic explosion y sonido
func explotar() -> void:
	if _esta_explotando:
		return
	_esta_explotando = true
	print("[PlaceholderNPC] ¡%s explota con realistic explosion!" % name)
	
	# Desactivar interacción y colisiones del NPC
	var dialogo = find_child("InteraccionDialogo", false, false)
	if dialogo and dialogo.has_method("desactivar"):
		dialogo.desactivar()
	
	var col = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col:
		col.set_deferred("disabled", true)
	
	var sp = _obtener_sprite()
	if sp:
		sp.hide()
	
	# Reproducir sonido de bad explosion en la raíz de la escena para no cortarlo
	if sfx_explosion:
		var sfx_node := AudioStreamPlayer.new()
		sfx_node.stream = sfx_explosion
		sfx_node.bus = &"SFX"
		sfx_node.process_mode = Node.PROCESS_MODE_ALWAYS
		if is_inside_tree() and get_tree() and get_tree().root:
			get_tree().root.add_child(sfx_node)
			sfx_node.play()
			sfx_node.finished.connect(sfx_node.queue_free)
		elif is_inside_tree():
			add_child(sfx_node)
			sfx_node.play()
			sfx_node.finished.connect(sfx_node.queue_free)
	
	# Crear y reproducir el sprite animado de Realistic Explosion
	var tex_exp = _obtener_textura_explosion()
	if tex_exp:
		var anim_exp := AnimatedSprite3D.new()
		anim_exp.name = "RealisticExplosion"
		anim_exp.pixel_size = escala_explosion
		anim_exp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		anim_exp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		anim_exp.position = Vector3(0, 1.4, 0)
		
		var sf := SpriteFrames.new()
		sf.add_animation("explode")
		sf.set_animation_speed("explode", fps_explosion)
		sf.set_animation_loop("explode", false)
		
		# 17 frames de 71x100
		for i in range(17):
			var atlas := AtlasTexture.new()
			atlas.atlas = tex_exp
			atlas.region = Rect2(i * 71, 0, 71, 100)
			sf.add_frame("explode", atlas)
		
		anim_exp.sprite_frames = sf
		add_child(anim_exp)
		anim_exp.play("explode")
		
		anim_exp.animation_finished.connect(func():
			queue_free()
		)
	else:
		queue_free()

## Otorga +1 de Ataque al jugador en GameState y reproduce la fanfarria
func _otorgar_aumento_ataque() -> void:
	var gs = _obtener_game_state()
	if gs:
		if gs.has_method("aumentar_ataque"):
			gs.aumentar_ataque(aumento_ataque)
		elif gs.stats:
			gs.stats.ataque += aumento_ataque
			gs.stats_modificadas.emit()
		var atk_total = gs.stats.ataque if gs.stats else 0
		print("[PlaceholderNPC] ¡Ataque aumentado +%d! Ataque actual: %d" % [aumento_ataque, atk_total])
	
	if sfx_recompensa:
		var sfx_node := AudioStreamPlayer.new()
		sfx_node.stream = sfx_recompensa
		sfx_node.bus = &"SFX"
		sfx_node.process_mode = Node.PROCESS_MODE_ALWAYS
		if is_inside_tree() and get_tree() and get_tree().root:
			get_tree().root.add_child(sfx_node)
			sfx_node.play()
			sfx_node.finished.connect(sfx_node.queue_free)
		elif is_inside_tree():
			add_child(sfx_node)
			sfx_node.play()
			sfx_node.finished.connect(sfx_node.queue_free)
	
	# Mostrar mensaje visual / notificación en pantalla y en el mundo 3D
	if mostrar_mensaje_recompensa and not mensaje_recompensa.is_empty():
		_mostrar_mensaje_notificacion(mensaje_recompensa, "+%d Ataque" % aumento_ataque)

## Muestra una notificación visual en pantalla con estilo nórdico / RPG
func _mostrar_mensaje_notificacion(texto: String, detalle: String = "") -> void:
	var tree = get_tree() if is_inside_tree() else (Engine.get_main_loop() as SceneTree)
	var root: Node = tree.root if tree else null
	if root == null:
		var p = get_parent()
		while p != null:
			if p.get_parent() == null:
				root = p
				break
			p = p.get_parent()
	if root == null:
		return
	
	# 1. Notificación en pantalla (CanvasLayer)
	var canvas := CanvasLayer.new()
	canvas.name = "NotificacionRecompensa"
	canvas.layer = 105
	root.add_child(canvas)
	
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_WIDE)
	margin.offset_top = 40.0
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(margin)
	
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(center)
	
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.11, 0.16, 0.94)
	sb.border_color = Color(0.95, 0.82, 0.35, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.shadow_color = Color(0.0, 0.0, 0.0, 0.6)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 22.0
	sb.content_margin_right = 22.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hbox)
	
	var icono := Label.new()
	icono.text = "⚔️"
	icono.add_theme_font_size_override("font_size", 22)
	hbox.add_child(icono)
	
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(vbox)
	
	var lbl_texto := Label.new()
	lbl_texto.text = texto
	lbl_texto.add_theme_font_size_override("font_size", 18)
	lbl_texto.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88))
	lbl_texto.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	lbl_texto.add_theme_constant_override("shadow_offset_y", 1)
	vbox.add_child(lbl_texto)
	
	if not detalle.is_empty():
		var lbl_det := Label.new()
		lbl_det.text = detalle
		lbl_det.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_det.add_theme_font_size_override("font_size", 13)
		lbl_det.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55))
		vbox.add_child(lbl_det)
	
	panel.pivot_offset = Vector2(panel.size.x * 0.5, 0)
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	
	var tw := canvas.create_tween()
	if tw:
		tw.set_parallel(true)
		tw.tween_property(panel, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.tween_property(panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(margin, "offset_top", 48.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tw.chain().tween_interval(duracion_toast)
		tw.chain().set_parallel(true)
		tw.tween_property(panel, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.tween_property(margin, "offset_top", 30.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(canvas.queue_free)
	
	# 2. Texto flotante 3D sobre el jugador
	var jugador = _obtener_jugador()
	if jugador and is_instance_valid(jugador) and is_inside_tree() and get_parent():
		var lbl3d := Label3D.new()
		lbl3d.text = "+%d ATQ" % aumento_ataque
		lbl3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl3d.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		lbl3d.pixel_size = 0.008
		lbl3d.modulate = Color(0.45, 0.95, 0.55)
		lbl3d.outline_modulate = Color(0, 0, 0, 0.9)
		lbl3d.outline_size = 6
		lbl3d.position = jugador.position + Vector3(0, 1.8, 0)
		get_parent().add_child(lbl3d)
		
		var tw3d := lbl3d.create_tween()
		if tw3d:
			tw3d.set_parallel(true)
			tw3d.tween_property(lbl3d, "position:y", lbl3d.position.y + 0.7, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw3d.tween_property(lbl3d, "modulate:a", 0.0, 0.5).set_delay(1.0)
			tw3d.chain().tween_callback(lbl3d.queue_free)

func _obtener_textura_explosion() -> Texture2D:
	if textura_explosion != null:
		return textura_explosion
	if ResourceLoader.exists("res://assets/sprites/vfx/realistic_explosion.png"):
		var t = load("res://assets/sprites/vfx/realistic_explosion.png")
		if t is Texture2D:
			return t
	if FileAccess.file_exists("res://assets/sprites/vfx/realistic_explosion.png"):
		var img = Image.load_from_file("res://assets/sprites/vfx/realistic_explosion.png")
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	return null

func _world_dir_to_camera_input(world_dir: Vector3) -> Vector2:
	var camera = get_viewport().get_camera_3d() if (is_inside_tree() and get_viewport()) else null
	if camera == null:
		return Vector2(world_dir.x, world_dir.z)
	
	var cam_forward = -camera.global_transform.basis.z
	var cam_right = camera.global_transform.basis.x
	cam_forward.y = 0.0
	cam_right.y = 0.0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()
	return Vector2(world_dir.dot(cam_right), -world_dir.dot(cam_forward))

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

func _obtener_jugador() -> Node3D:
	if not is_inside_tree():
		return null
	var nodos = get_tree().get_nodes_in_group("player")
	for n in nodos:
		if is_instance_valid(n) and n is Node3D and n != self:
			return n as Node3D
	var cur_scene = get_tree().current_scene
	if cur_scene and cur_scene.has_method("get_active_player"):
		return cur_scene.get_active_player() as Node3D
	var p = get_tree().root.find_child("Player", true, false)
	if p is Node3D and p != self:
		return p
	return null

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
