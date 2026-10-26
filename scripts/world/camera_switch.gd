@tool
class_name CameraSwitch
extends Area3D

## Conmutador de cámaras inteligente y visual para Whispers of the North.
## Diseñado para colocarse entre sectores o zonas del mapa para alternar cámaras de forma fluida.
## Muestra etiquetas visuales 3D en el editor para ver de inmediato qué cámaras conecta.

signal camara_cambiada(camara_nueva: Camera3D, camara_anterior: Camera3D)

enum ModoSwitch {
	ALTERNAR_A_B,         ## Si la actual es A pasa a B; si es B pasa a A. Si ninguna es actual, activa la más lógica.
	DIRECCIONAL,          ## Detecta si el jugador cruza hacia adelante (+Z local) o atrás (-Z local).
	ZONA_FIJA             ## Al entrar en este volumen, activa siempre una cámara específica fija.
}

@export_group("Configuración de Cámaras")
## Modo de funcionamiento del switch.
@export var modo: ModoSwitch = ModoSwitch.ALTERNAR_A_B:
	set(val):
		modo = val
		_actualizar_etiqueta_editor()

## Número de la Cámara A (ej: 1 para Camera1). Si está en un contenedor 'Cameras', la encuentra automáticamente.
@export var camara_a_num: int = 1:
	set(val):
		camara_a_num = val
		_actualizar_etiqueta_editor()

## Número de la Cámara B (ej: 2 para Camera2).
@export var camara_b_num: int = 2:
	set(val):
		camara_b_num = val
		_actualizar_etiqueta_editor()

@export_group("Asignación Directa (Opcional)")
## Asignación directa arrastrando desde el árbol de escena (prioridad sobre los números).
@export var camara_a_nodo: Camera3D = null:
	set(val):
		camara_a_nodo = val
		_actualizar_etiqueta_editor()

@export var camara_b_nodo: Camera3D = null:
	set(val):
		camara_b_nodo = val
		_actualizar_etiqueta_editor()

@export_group("Herramientas de Colocación (Editor)")
## Activa esta casilla en el Inspector para teletransportar el switch justo al centro entre la Cámara A y la Cámara B.
@export var centrar_entre_camaras: bool = false:
	set(val):
		if val:
			_auto_centrar_entre_camaras()
		centrar_entre_camaras = false

## Activa esta casilla para rotar el switch automáticamente perpendicular a la dirección entre las dos cámaras.
@export var alinear_con_camaras: bool = false:
	set(val):
		if val:
			_auto_alinear_con_camaras()
		alinear_con_camaras = false

## Si escalaste el nodo con la herramienta Escalar (S), esto absorbe la escala en el tamaño real y la resetea a 1,1,1.
@export var normalizar_escala_ahora: bool = false:
	set(val):
		if val:
			normalizar_escala()
		normalizar_escala_ahora = false

## Tamaño rápido de la caja de colisión (ajusta el CollisionShape3D hijo automáticamente).
@export var tamano_trigger: Vector3 = Vector3(6.0, 3.0, 1.2):
	set(val):
		tamano_trigger = val
		_actualizar_tamano_colision()

@export_group("Visualización en Editor")
## Muestra una etiqueta 3D flotante con el nombre de las cámaras. Por defecto desactivada para no saturar la vista.
@export var mostrar_etiqueta_editor: bool = false:
	set(val):
		mostrar_etiqueta_editor = val
		if _label_editor:
			_label_editor.visible = Engine.is_editor_hint() and mostrar_etiqueta_editor

## Muestra un volumen translúcido en el editor para ver exactamente el área y ancho que cubre este switch.
@export var mostrar_volumen_editor: bool = true:
	set(val):
		mostrar_volumen_editor = val
		_actualizar_volumen_editor()

## Muestra líneas guía 3D en el editor conectando este switch directamente con la Cámara A y la Cámara B.
@export var mostrar_lineas_a_camaras: bool = false:
	set(val):
		mostrar_lineas_a_camaras = val
		_actualizar_lineas_editor()

## Color de depuración vibrante para la etiqueta y el volumen en el editor (por defecto: Magenta Neón Debug).
@export var color_etiqueta: Color = Color(1.0, 0.08, 0.58):
	set(val):
		color_etiqueta = val
		_actualizar_etiqueta_editor()
		_actualizar_volumen_editor()

@export var altura_etiqueta: float = 3.2:
	set(val):
		altura_etiqueta = val
		if _label_editor:
			_label_editor.position.y = altura_etiqueta

@export_group("Previsualización de Cámaras (Editor)")
## Activa esta casilla para mover la cámara del editor a la posición y ángulo exactos de la Cámara A.
@export var mirar_como_camara_a: bool = false:
	set(val):
		if val and Engine.is_editor_hint():
			_mirar_desde_camara_num(camara_a_nodo, camara_a_num)
		mirar_como_camara_a = false

## Activa esta casilla para mover la cámara del editor a la posición y ángulo exactos de la Cámara B.
@export var mirar_como_camara_b: bool = false:
	set(val):
		if val and Engine.is_editor_hint():
			_mirar_desde_camara_num(camara_b_nodo, camara_b_num)
		mirar_como_camara_b = false

@export_group("Opciones Avanzadas")
## Si es true, la primera cámara del juego se inicializa automáticamente si ninguna está activa.
@export var inicializar_primera_camara: bool = false
## Tiempo de enfriamiento en segundos entre cambios de cámara para evitar parpadeos rápidos en el borde.
@export var cooldown_cambio: float = 0.25

var _ultimo_tiempo_cambio: float = -999.0
var _label_editor: Label3D = null
var _mesh_editor: MeshInstance3D = null
var _lines_editor: MeshInstance3D = null

func _ready() -> void:
	# Parsear números desde el nombre si no se han configurado explícitamente (ej: Switch_1_2)
	_auto_detectar_por_nombre()
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	if not scale.is_equal_approx(Vector3.ONE):
		normalizar_escala()
	
	_actualizar_tamano_colision()
	
	if Engine.is_editor_hint():
		_asegurar_etiqueta_editor()
		_actualizar_etiqueta_editor()
		_asegurar_volumen_editor()
		_actualizar_volumen_editor()
		_asegurar_lineas_editor()
		_actualizar_lineas_editor()
		_conectar_forma_colision()
	else:
		# En juego, asegurar que no se vean los elementos de debug del editor
		if has_node("EditorLabel"):
			$EditorLabel.hide()
			$EditorLabel.queue_free()
		if has_node("EditorVolume"):
			$EditorVolume.hide()
			$EditorVolume.queue_free()
		if has_node("EditorLines"):
			$EditorLines.hide()
			$EditorLines.queue_free()
		
		# Asegurar colisión de detección (capas estándar)
		collision_layer = 0
		collision_mask = 1 # Capa del jugador
		
		if inicializar_primera_camara:
			call_deferred("_verificar_camara_inicial")

func _auto_detectar_por_nombre() -> void:
	if camara_a_nodo == null and camara_a_num == 1 and camara_b_num == 2:
		# Si tiene los valores por defecto, intentar leer el nombre del nodo
		var reg = RegEx.new()
		reg.compile("(\\d+)[^\\d]+(\\d+)")
		var match_res = reg.search(name)
		if match_res:
			camara_a_num = match_res.get_string(1).to_int()
			camara_b_num = match_res.get_string(2).to_int()

func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if not _es_jugador(body):
		return
	
	var tiempo_actual = Time.get_ticks_msec() / 1000.0
	if tiempo_actual - _ultimo_tiempo_cambio < cooldown_cambio:
		return
	
	var cam_a = _resolver_camara(camara_a_nodo, camara_a_num)
	var cam_b = _resolver_camara(camara_b_nodo, camara_b_num)
	
	if cam_a == null and cam_b == null:
		push_warning("CameraSwitch '%s' no pudo encontrar ninguna de las dos cámaras." % name)
		return
	
	match modo:
		ModoSwitch.ZONA_FIJA:
			var objetivo = cam_a if cam_a else cam_b
			if objetivo and not objetivo.current:
				_activar_camara(objetivo)
		
		ModoSwitch.DIRECCIONAL:
			_cambiar_por_direccion(body, cam_a, cam_b)
		
		ModoSwitch.ALTERNAR_A_B, _:
			_cambiar_por_alternancia(cam_a, cam_b)

func _cambiar_por_alternancia(cam_a: Camera3D, cam_b: Camera3D) -> void:
	if cam_a and cam_b:
		if cam_a.current:
			_activar_camara(cam_b, cam_a)
		elif cam_b.current:
			_activar_camara(cam_a, cam_b)
		else:
			# Si ninguna de las dos es la actual, activar la más cercana al switch
			var dist_a = global_position.distance_squared_to(cam_a.global_position)
			var dist_b = global_position.distance_squared_to(cam_b.global_position)
			if dist_a < dist_b:
				_activar_camara(cam_a)
			else:
				_activar_camara(cam_b)
	elif cam_a and not cam_a.current:
		_activar_camara(cam_a)
	elif cam_b and not cam_b.current:
		_activar_camara(cam_b)

func _cambiar_por_direccion(body: Node3D, cam_a: Camera3D, cam_b: Camera3D) -> void:
	# Vector hacia donde mira o se mueve el jugador relativo al switch
	var dir_cruce = Vector3.FORWARD
	if "velocity" in body and body.velocity.length_squared() > 0.1:
		dir_cruce = body.velocity.normalized()
	elif "last_input_dir" in body:
		dir_cruce = Vector3(body.last_input_dir.x, 0, body.last_input_dir.y).normalized()
	
	var forward_switch = -global_transform.basis.z.normalized()
	var dot = dir_cruce.dot(forward_switch)
	
	# Si cruza hacia adelante (+forward), va hacia B; si cruza hacia atrás, va hacia A
	if dot > 0.0:
		if cam_b and not cam_b.current:
			_activar_camara(cam_b, cam_a)
	else:
		if cam_a and not cam_a.current:
			_activar_camara(cam_a, cam_b)

func _activar_camara(nueva_cam: Camera3D, previa: Camera3D = null) -> void:
	if nueva_cam == null or nueva_cam.current:
		return
	
	nueva_cam.make_current()
	_ultimo_tiempo_cambio = Time.get_ticks_msec() / 1000.0
	camara_cambiada.emit(nueva_cam, previa)

func _resolver_camara(nodo_directo: Camera3D, num: int) -> Camera3D:
	if nodo_directo != null and is_instance_valid(nodo_directo):
		return nodo_directo
	
	if num <= 0:
		return null
	
	var root_nodo: Node = null
	if Engine.is_editor_hint():
		if is_inside_tree() and get_tree() and get_tree().edited_scene_root:
			root_nodo = get_tree().edited_scene_root
		elif owner:
			root_nodo = owner
	else:
		if is_inside_tree() and get_tree() and get_tree().current_scene:
			root_nodo = get_tree().current_scene
		elif owner:
			root_nodo = owner
	
	if root_nodo == null:
		var actual: Node = self
		while actual.get_parent() != null and not (actual.get_parent() is Window):
			actual = actual.get_parent()
		root_nodo = actual
	
	if root_nodo == null:
		return null
	
	var posibles_nombres = ["Camera%d" % num, "Camera_%d" % num, "Cam%d" % num, "Cam_%d" % num]
	var posibles_contenedores = ["Cameras", "Camaras", "Cameras3D", "Cams"]
	
	for contenedor in posibles_contenedores:
		var cont_node = root_nodo.get_node_or_null(contenedor)
		if cont_node:
			for nom in posibles_nombres:
				var cam = cont_node.get_node_or_null(nom)
				if cam is Camera3D:
					return cam
	
	for nom in posibles_nombres:
		var cam = root_nodo.get_node_or_null(nom)
		if cam is Camera3D:
			return cam
	
	for nom in posibles_nombres:
		var encontrada = root_nodo.find_child(nom, true, false)
		if encontrada is Camera3D:
			return encontrada
	
	return null

func _es_jugador(nodo: Node) -> bool:
	if nodo == null or nodo.is_in_group("npc") or nodo.name.to_lower().contains("npc"):
		return false
	if nodo.is_in_group("player"):
		return true
	var script = nodo.get_script()
	if script and script.resource_path.ends_with("player.gd"):
		return true
	var lower_name = nodo.name.to_lower()
	return lower_name.contains("player") or lower_name.contains("eric")

func _verificar_camara_inicial() -> void:
	var viewport = get_viewport()
	if viewport and viewport.get_camera_3d() == null:
		var cam_1 = _resolver_camara(camara_a_nodo, 1)
		if cam_1:
			cam_1.make_current()

# --- Funciones de Asistencia de Colocación (Editor) ---
func _auto_centrar_entre_camaras() -> void:
	var cam_a = _resolver_camara(camara_a_nodo, camara_a_num)
	var cam_b = _resolver_camara(camara_b_nodo, camara_b_num)
	if cam_a and cam_b:
		var pos_a = cam_a.global_position if cam_a.is_inside_tree() else cam_a.position
		var pos_b = cam_b.global_position if cam_b.is_inside_tree() else cam_b.position
		var pos_medio = (pos_a + pos_b) * 0.5
		var curr_y = global_position.y if is_inside_tree() else position.y
		if abs(curr_y) < 5.0:
			pos_medio.y = curr_y
		else:
			pos_medio.y = 1.5
		if is_inside_tree():
			global_position = pos_medio
		else:
			position = pos_medio
		print("[CameraSwitch] Posicionado entre %s y %s en: %s" % [cam_a.name, cam_b.name, str(pos_medio)])
	elif cam_a:
		var pos_a = cam_a.global_position if cam_a.is_inside_tree() else cam_a.position
		if is_inside_tree():
			global_position = pos_a
		else:
			position = pos_a
	elif cam_b:
		var pos_b = cam_b.global_position if cam_b.is_inside_tree() else cam_b.position
		if is_inside_tree():
			global_position = pos_b
		else:
			position = pos_b

func _auto_alinear_con_camaras() -> void:
	var cam_a = _resolver_camara(camara_a_nodo, camara_a_num)
	var cam_b = _resolver_camara(camara_b_nodo, camara_b_num)
	if cam_a and cam_b:
		var pos_a = cam_a.global_position if cam_a.is_inside_tree() else cam_a.position
		var pos_b = cam_b.global_position if cam_b.is_inside_tree() else cam_b.position
		var dir = (pos_b - pos_a)
		dir.y = 0.0
		if dir.length_squared() > 0.001 and is_inside_tree():
			look_at(global_position + dir.normalized(), Vector3.UP)
			print("[CameraSwitch] Orientado perpendicularmente a la transición.")

func _asegurar_forma_unica() -> void:
	var col = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col:
		if col.shape == null:
			var box = BoxShape3D.new()
			box.resource_local_to_scene = true
			box.size = tamano_trigger
			col.shape = box
		elif not col.shape.resource_local_to_scene:
			col.shape = col.shape.duplicate()
			col.shape.resource_local_to_scene = true

func _actualizar_tamano_colision() -> void:
	_asegurar_forma_unica()
	var col = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col and col.shape is BoxShape3D:
		col.shape.size = tamano_trigger
		col.position.y = tamano_trigger.y * 0.5
	if Engine.is_editor_hint():
		_actualizar_volumen_editor()

func normalizar_escala() -> void:
	if not scale.is_equal_approx(Vector3.ONE) and scale.length_squared() > 0.001:
		tamano_trigger.x *= abs(scale.x)
		tamano_trigger.y *= abs(scale.y)
		tamano_trigger.z *= abs(scale.z)
		scale = Vector3.ONE
		_actualizar_tamano_colision()
		_actualizar_volumen_editor()
		if Engine.is_editor_hint():
			update_gizmos()
		print("[CameraSwitch] Escala absorbida en tamano_trigger (%s) y reseteada a 1,1,1" % str(tamano_trigger))

func _conectar_forma_colision() -> void:
	var col = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col and col.shape:
		if not col.shape.changed.is_connected(_on_shape_changed):
			col.shape.changed.connect(_on_shape_changed)

func _on_shape_changed() -> void:
	if not Engine.is_editor_hint():
		return
	var col = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if col and col.shape is BoxShape3D:
		if not tamano_trigger.is_equal_approx(col.shape.size):
			tamano_trigger = col.shape.size
			col.position.y = tamano_trigger.y * 0.5
			_actualizar_volumen_editor()
			update_gizmos()

# --- Funciones Visuales para el Editor ---
func _asegurar_etiqueta_editor() -> void:
	_label_editor = get_node_or_null("EditorLabel") as Label3D
	if _label_editor == null:
		_label_editor = Label3D.new()
		_label_editor.name = "EditorLabel"
		_label_editor.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_label_editor.no_depth_test = true
		_label_editor.fixed_size = true
		_label_editor.render_priority = 100
		_label_editor.outline_render_priority = 99
		_label_editor.font_size = 24
		_label_editor.outline_size = 8
		_label_editor.outline_modulate = Color.BLACK
		_label_editor.position = Vector3(0, altura_etiqueta, 0)
		add_child(_label_editor)

func _actualizar_etiqueta_editor() -> void:
	if not Engine.is_editor_hint():
		return
	_asegurar_etiqueta_editor()
	if _label_editor == null:
		return
	
	_label_editor.visible = mostrar_etiqueta_editor
	_label_editor.modulate = color_etiqueta
	_label_editor.position.y = altura_etiqueta
	
	var nom_a: String = String(camara_a_nodo.name) if camara_a_nodo else ("Cam" + str(camara_a_num))
	var nom_b: String = String(camara_b_nodo.name) if camara_b_nodo else ("Cam" + str(camara_b_num))
	
	match modo:
		ModoSwitch.ZONA_FIJA:
			_label_editor.text = "📷 [ %s ]" % nom_a
		ModoSwitch.DIRECCIONAL:
			_label_editor.text = "📷 [ %s ➔ %s ]" % [nom_a, nom_b]
		ModoSwitch.ALTERNAR_A_B, _:
			_label_editor.text = "📷 [ %s ⇄ %s ]" % [nom_a, nom_b]

func _asegurar_volumen_editor() -> void:
	_mesh_editor = get_node_or_null("EditorVolume") as MeshInstance3D
	if _mesh_editor == null:
		_mesh_editor = MeshInstance3D.new()
		_mesh_editor.name = "EditorVolume"
		_mesh_editor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var box = BoxMesh.new()
		box.size = tamano_trigger
		_mesh_editor.mesh = box
		
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(color_etiqueta.r, color_etiqueta.g, color_etiqueta.b, 0.22)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.no_depth_test = false
		_mesh_editor.material_override = mat
		_mesh_editor.position = Vector3(0, tamano_trigger.y * 0.5, 0)
		add_child(_mesh_editor)

func _actualizar_volumen_editor() -> void:
	if not Engine.is_editor_hint():
		return
	_asegurar_volumen_editor()
	if _mesh_editor == null:
		return
	
	_mesh_editor.visible = mostrar_volumen_editor
	if _mesh_editor.mesh is BoxMesh:
		_mesh_editor.mesh.size = tamano_trigger
	_mesh_editor.position = Vector3(0, tamano_trigger.y * 0.5, 0)
	if _mesh_editor.material_override is StandardMaterial3D:
		_mesh_editor.material_override.albedo_color = Color(color_etiqueta.r, color_etiqueta.g, color_etiqueta.b, 0.22)

func _asegurar_lineas_editor() -> void:
	_lines_editor = get_node_or_null("EditorLines") as MeshInstance3D
	if _lines_editor == null:
		_lines_editor = MeshInstance3D.new()
		_lines_editor.name = "EditorLines"
		_lines_editor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_lines_editor.mesh = ImmediateMesh.new()
		
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
		mat.vertex_color_use_as_albedo = true
		mat.no_depth_test = true
		_lines_editor.material_override = mat
		add_child(_lines_editor)

func _actualizar_lineas_editor() -> void:
	if not Engine.is_editor_hint():
		return
	_asegurar_lineas_editor()
	if _lines_editor == null:
		return
	
	_lines_editor.visible = mostrar_lineas_a_camaras
	if not mostrar_lineas_a_camaras:
		return
	if not is_inside_tree():
		return
	
	var gt: Transform3D = global_transform
	if absf(gt.basis.determinant()) < 0.0001:
		return
	
	var cam_a = _resolver_camara(camara_a_nodo, camara_a_num)
	var cam_b = _resolver_camara(camara_b_nodo, camara_b_num)
	var imm: ImmediateMesh = _lines_editor.mesh as ImmediateMesh
	if imm:
		imm.clear_surfaces()
		if cam_a or cam_b:
			var inv_gt: Transform3D = gt.affine_inverse()
			imm.surface_begin(Mesh.PRIMITIVE_LINES)
			var origen_local = Vector3(0, tamano_trigger.y * 0.5, 0)
			if cam_a:
				var pos_a = cam_a.global_position if cam_a.is_inside_tree() else cam_a.position
				var local_a = inv_gt * pos_a
				imm.surface_set_color(Color(0.2, 0.85, 1.0)) # Azul/Cian hacia Cam A
				imm.surface_add_vertex(origen_local)
				imm.surface_add_vertex(local_a)
			if cam_b:
				var pos_b = cam_b.global_position if cam_b.is_inside_tree() else cam_b.position
				var local_b = inv_gt * pos_b
				imm.surface_set_color(Color(1.0, 0.85, 0.1)) # Amarillo hacia Cam B
				imm.surface_add_vertex(origen_local)
				imm.surface_add_vertex(local_b)
			imm.surface_end()

func _mirar_desde_camara_num(nodo_directo: Camera3D, num: int) -> void:
	var cam = _resolver_camara(nodo_directo, num)
	if cam == null:
		push_warning("[CameraSwitch] No se pudo encontrar la cámara para previsualizar (Num: %d)." % num)
		return
	
	if Engine.has_singleton("EditorInterface"):
		var ei = Engine.get_singleton("EditorInterface")
		var vp = ei.get_editor_viewport_3d(0)
		if vp:
			var ed_cam = vp.get_camera_3d()
			if ed_cam:
				ed_cam.global_transform = cam.global_transform
				ed_cam.fov = cam.fov
				print("[CameraSwitch] Visor 3D del editor colocado en la perspectiva de '%s'." % cam.name)
