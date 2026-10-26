class_name InteraccionDialogo
extends Area3D

## Nodo de interacción de diálogo altamente configurable para NPCs, carteles, cofres y objetos interactuables.
## Diseñado para añadirse con un solo clic a cualquier entidad 3D o usarse como zona de disparo.
## Integra el addon Dialogue Manager con estética nórdica, cinemáticas, orientación y prompts 3D.

signal dialogo_iniciado()
signal dialogo_terminado()
signal jugador_entro_en_rango()
signal jugador_salio_de_rango()

const NordicBalloonScene = preload("res://scenes/dialogue/NordicDialogueBalloon.tscn")
static var _interactuables_en_rango: Array[InteraccionDialogo] = []

@export_group("Estado y Activación")
## Si es false, la interacción está inactiva y no responderá a inputs ni zonas.
@export var activo: bool = true
## Si es true, inicia el diálogo automáticamente cuando el jugador entra al área (útil para cinemáticas o eventos).
@export var auto_iniciar_al_entrar: bool = false
## Si es true, el nodo se desactiva permanentemente tras completar la conversación.
@export var deshabilitar_tras_interactuar: bool = false
## Número máximo de veces que puede interactuarse (-1 = infinito).
@export var maximo_interacciones: int = -1

@export_group("Diálogo Principal (.dialogue)")
## Archivo de diálogo compilado por Dialogue Manager (.dialogue).
@export var recurso_dialogo: DialogueResource = null
## Título de la sección o cue en el archivo .dialogue (por defecto "start").
@export var titulo_o_cue: String = "start"

@export_group("Diálogo Rápido (Inspector)")
## Nombre del personaje o entidad que habla (ej: "Aldeana Freya", "Cartel Antiguo", "Estatua").
@export var nombre_hablante: String = ""
## Retrato visual 2D para la caja de texto (opcional).
@export var retrato_hablante: Texture2D = null
## Líneas de texto directas para conversaciones simples sin necesidad de crear archivos .dialogue.
## Se usan automáticamente si 'recurso_dialogo' es null.
@export_multiline var lineas_rapidas: Array[String] = []

@export_group("Comportamiento y Cinemática")
## Si es true, bloquea el movimiento del jugador mientras dure el diálogo.
@export var bloquear_jugador: bool = true
## Si es true, gira a Eric para que mire hacia el interactuable al iniciar la conversación.
@export var orientar_jugador_al_hablar: bool = true
## Si es true, gira al NPC o entidad hacia el jugador durante la charla.
@export var orientar_npc_al_jugador: bool = true
## Nodo visual específico del NPC a girar (si es null, intenta usar el nodo padre).
@export var nodo_visual_a_girar: Node3D = null

@export_group("Indicador Visual Flotante (Prompt 3D)")
## Muestra una etiqueta 3D animada al aproximarse el jugador.
@export var mostrar_indicador: bool = true
## Texto que se muestra en el indicador flotante (ej: "[E] Hablar", "[E] Examinar", "[E] Leer").
@export var texto_indicador: String = "[E] Hablar"
## Desplazamiento relativo en altura para el indicador flotante.
@export var offset_indicador: Vector3 = Vector3(0.0, 2.2, 0.0)
## Color del texto del indicador flotante.
@export var color_indicador: Color = Color(1.0, 0.9, 0.4)

@export_group("Radio y Detección 3D")
## Radio en metros de la zona de interacción (se aplica si no se añade un CollisionShape3D hijo manualmente).
@export var radio_interaccion: float = 2.2

@export_group("Audio")
## Sonido reproducido al presionar interactuar o iniciar el diálogo.
@export var sfx_iniciar: AudioStream = preload("res://assets/audio/sfx/snd_mysterygo.wav")
## Sonido de escritura / murmullo de voz para este hablante (opcional).
@export var sfx_voz_hablante: AudioStream = null

@export_group("Objeto Interactuable (Cofres, Puertas, etc.)")
## Activa el soporte para objetos interactuables del mundo (cofres, jarrones, puertas, palancas).
## Si es false, se auto-detecta si el nodo padre es un cofre o tiene lógica de apertura/interacción.
@export var es_objeto_interactuable: bool = false
## Al terminar el diálogo, ejecuta automáticamente la acción de interacción en el objeto padre (ej. abrir cofre).
@export var activar_objeto_al_terminar: bool = true
## Permite que el evento 'interact' pase también al padre inmediatamente (no consume con set_input_as_handled).
@export var pasar_input_al_padre: bool = false
## Si el objeto padre ya fue abierto o activado, no reproduce el diálogo y permite la interacción directa del objeto.
@export var ignorar_si_padre_abierto: bool = true
## Desactiva permanentemente este diálogo una vez que el objeto padre haya sido abierto o activado.
@export var desactivar_tras_abrir_objeto: bool = true
## Nombre de método personalizado a invocar en el objeto padre al terminar el diálogo (si está vacío, busca abrir, interactuar o activar).
@export var metodo_personalizado_padre: String = ""

@export_group("Globo de Diálogo Personalizado")
## Escena de globo de diálogo a utilizar (si es null, usa el elegante globo nórdico por defecto).
@export var escena_globo: PackedScene = NordicBalloonScene

# Variables internas
var _jugador_en_rango: Node3D = null
var _jugador_activo: Node3D = null
var _en_dialogo: bool = false
var _contador_interacciones: int = 0
var _indicador_label: Label3D = null
var _tiempo_acumulado: float = 0.0
var _rotacion_original_npc: Vector3 = Vector3.ZERO
var _recurso_generado_cache: DialogueResource = null
var _recurso_activo_dialogo: DialogueResource = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	
	_asegurar_forma_colision()
	_crear_indicador_flotante()
	
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)
	
	_conectar_dialogue_manager()

func _exit_tree() -> void:
	if self in _interactuables_en_rango:
		_interactuables_en_rango.erase(self)
	_desconectar_dialogue_manager()

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not mostrar_indicador or _indicador_label == null:
		return
	
	var bloqueado_por_padre: bool = _padre_es_interactuable() and ignorar_si_padre_abierto and _padre_esta_abierto()
	if activo and not _en_dialogo and _jugador_en_rango != null and not bloqueado_por_padre:
		_tiempo_acumulado += delta * 4.0
		_indicador_label.position.y = offset_indicador.y + sin(_tiempo_acumulado) * 0.08
		_indicador_label.modulate.a = move_toward(_indicador_label.modulate.a, 1.0, delta * 5.0)
		_indicador_label.show()
	else:
		_indicador_label.modulate.a = move_toward(_indicador_label.modulate.a, 0.0, delta * 6.0)
		if _indicador_label.modulate.a <= 0.01:
			_indicador_label.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not activo or _en_dialogo or auto_iniciar_al_entrar or _jugador_en_rango == null:
		return
	if maximo_interacciones >= 0 and _contador_interacciones >= maximo_interacciones:
		return
	
	# Si es un objeto interactuable y ya está abierto, dejar pasar el evento al padre
	if _padre_es_interactuable() and ignorar_si_padre_abierto and _padre_esta_abierto():
		return
	
	# La acción interact está configurada en project.godot (teclado 'E', 'Z', Enter, Espacio y Gamepad 'A')
	if event.is_action_pressed("interact") and not event.is_echo():
		if _es_el_interactuable_mas_cercano(_jugador_en_rango):
			if not (_padre_es_interactuable() and pasar_input_al_padre):
				get_viewport().set_input_as_handled()
			iniciar_dialogo(_jugador_en_rango)

## Inicia el diálogo configurado (se puede llamar manualmente desde script, botón o evento)
func iniciar_dialogo(jugador_ref: Node3D = null) -> void:
	if not activo or _en_dialogo:
		return
	if maximo_interacciones >= 0 and _contador_interacciones >= maximo_interacciones:
		return
	
	_jugador_activo = jugador_ref if jugador_ref else _jugador_en_rango
	if _jugador_activo == null:
		_jugador_activo = _buscar_jugador()
	
	_en_dialogo = true
	dialogo_iniciado.emit()
	
	# 1. Congelar y orientar jugador
	if _jugador_activo and is_instance_valid(_jugador_activo):
		if bloquear_jugador:
			if "is_interacting" in _jugador_activo:
				_jugador_activo.is_interacting = true
			if "velocity" in _jugador_activo:
				_jugador_activo.velocity = Vector3.ZERO
		
		if orientar_jugador_al_hablar:
			_orientar_personaje_hacia(_jugador_activo, global_position)
	
	# 2. Orientar NPC o entidad hacia el jugador
	if orientar_npc_al_jugador and _jugador_activo:
		_orientar_npc_hacia(_jugador_activo.global_position)
	
	# 3. SFX de inicio
	if sfx_iniciar:
		_reproducir_sfx(sfx_iniciar)
	
	# 4. Ocultar indicador
	if _indicador_label:
		_indicador_label.hide()
		_indicador_label.modulate.a = 0.0
	
	# 5. Resolver recurso de diálogo
	var recurso_final: DialogueResource = _obtener_recurso_dialogo()
	var cue_final: String = titulo_o_cue if recurso_dialogo else "start"
	
	if recurso_final == null:
		push_warning("InteraccionDialogo en '%s' no tiene diálogo configurado." % name)
		_finalizar_dialogo()
		return
	
	# 6. Preparar estados adicionales disponibles para el diálogo
	var game_state = _obtener_game_state()
	var extra_states: Array = [
		self,
		get_parent(),
		game_state,
		{
			"hablante": nombre_hablante,
			"retrato": retrato_hablante,
			"sfx_voz": sfx_voz_hablante,
			"interaccion": self
		}
	]
	
	# 7. Lanzar globo de diálogo
	_recurso_activo_dialogo = recurso_final
	var dm = _obtener_dialogue_manager()
	if dm:
		_conectar_dialogue_manager()
		var balloon_scene = escena_globo if escena_globo else NordicBalloonScene
		dm.show_dialogue_balloon_scene(balloon_scene, recurso_final, cue_final, extra_states)
	else:
		push_error("Autoload DialogueManager no encontrado en el proyecto.")
		_finalizar_dialogo()

func _finalizar_dialogo() -> void:
	_en_dialogo = false
	_contador_interacciones += 1
	var jugador_guardado = _jugador_activo
	
	# Restaurar jugador
	if _jugador_activo and is_instance_valid(_jugador_activo):
		if bloquear_jugador and "is_interacting" in _jugador_activo:
			_jugador_activo.is_interacting = false
	_jugador_activo = null
	
	# Restaurar orientación del NPC
	if orientar_npc_al_jugador:
		_restaurar_orientacion_npc()
	
	dialogo_terminado.emit()
	
	# Si es objeto interactuable y tiene configurado activar al terminar:
	if _padre_es_interactuable() and activar_objeto_al_terminar:
		_jugador_activo = jugador_guardado
		call_deferred("_ejecutar_interaccion_en_padre")
	elif deshabilitar_tras_interactuar or (maximo_interacciones >= 0 and _contador_interacciones >= maximo_interacciones):
		desactivar()
	elif _jugador_en_rango != null and mostrar_indicador and _indicador_label:
		_indicador_label.show()

## Desactiva el nodo de interacción
func desactivar() -> void:
	activo = false
	if _indicador_label:
		_indicador_label.hide()
		_indicador_label.modulate.a = 0.0
	if self in _interactuables_en_rango:
		_interactuables_en_rango.erase(self)

## Activa el nodo de interacción
func activar() -> void:
	activo = true
	if _jugador_en_rango != null and mostrar_indicador and _indicador_label:
		_indicador_label.show()

## Cambia el cue o rama a ejecutar en la próxima conversación
func cambiar_cue(nuevo_cue: String) -> void:
	titulo_o_cue = nuevo_cue

## Actualiza las líneas de texto rápido en tiempo de ejecución
func cambiar_lineas_rapidas(nuevas_lineas: Array[String], nuevo_hablante: String = "") -> void:
	lineas_rapidas = nuevas_lineas
	if not nuevo_hablante.is_empty():
		nombre_hablante = nuevo_hablante
	_recurso_generado_cache = null

# ---------------------------------------------------------------------------
# Métodos Auxiliares
# ---------------------------------------------------------------------------

func _obtener_recurso_dialogo() -> DialogueResource:
	if recurso_dialogo != null:
		return recurso_dialogo
	
	if lineas_rapidas.size() > 0:
		if _recurso_generado_cache != null:
			return _recurso_generado_cache
		
		var texto_compilado: String = "~ start\n"
		var prefix: String = (nombre_hablante + ": ") if not nombre_hablante.is_empty() else ""
		for linea in lineas_rapidas:
			texto_compilado += prefix + linea + "\n"
		texto_compilado += "=> END\n"
		
		var dm = Engine.get_singleton("DialogueManager") if Engine.has_singleton("DialogueManager") else null
		if dm and dm.has_method("create_resource_from_text"):
			_recurso_generado_cache = dm.create_resource_from_text(texto_compilado) as DialogueResource
			return _recurso_generado_cache
	
	return null

func _asegurar_forma_colision() -> void:
	for c in get_children():
		if c is CollisionShape3D:
			return
	
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var esfera := SphereShape3D.new()
	esfera.radius = radio_interaccion
	col.shape = esfera
	add_child(col)

func _crear_indicador_flotante() -> void:
	if not mostrar_indicador:
		return
	
	_indicador_label = Label3D.new()
	_indicador_label.name = "IndicadorVisual"
	_indicador_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_indicador_label.position = offset_indicador
	_indicador_label.text = texto_indicador
	_indicador_label.font_size = 22
	_indicador_label.outline_size = 6
	_indicador_label.outline_modulate = Color.BLACK
	_indicador_label.modulate = color_indicador
	_indicador_label.modulate.a = 0.0
	_indicador_label.no_depth_test = true
	_indicador_label.render_priority = 10
	add_child(_indicador_label)
	_indicador_label.hide()

func _es_el_interactuable_mas_cercano(jugador: Node3D) -> bool:
	if jugador == null or not is_instance_valid(jugador) or _jugador_en_rango != jugador:
		return false
	
	# Filtrar interactuables destruidos o inactivos
	_interactuables_en_rango = _interactuables_en_rango.filter(
		func(i): return is_instance_valid(i) and i.is_inside_tree() and i.activo and not i._en_dialogo and i._jugador_en_rango != null
	)
	
	if _interactuables_en_rango.size() <= 1:
		return true
	
	var pos_j: Vector3 = jugador.global_position
	var mi_dist: float = global_position.distance_squared_to(pos_j)
	for otro in _interactuables_en_rango:
		if otro != self:
			if otro.global_position.distance_squared_to(pos_j) < mi_dist:
				return false
	return true

func _on_body_entered(body: Node3D) -> void:
	if not activo or body == self or body == get_parent():
		return
	if _es_jugador(body):
		_jugador_en_rango = body
		if self not in _interactuables_en_rango:
			_interactuables_en_rango.append(self)
		jugador_entro_en_rango.emit()
		
		if auto_iniciar_al_entrar and not _en_dialogo:
			call_deferred("iniciar_dialogo", body)

func _on_body_exited(body: Node3D) -> void:
	if _jugador_en_rango == body:
		_jugador_en_rango = null
		if self in _interactuables_en_rango:
			_interactuables_en_rango.erase(self)
		jugador_salio_de_rango.emit()

func _es_jugador(node: Node) -> bool:
	if node == null or node == self or node == get_parent():
		return false
	if node.is_in_group("npc") or node.name.to_lower().contains("npc"):
		return false
	if node.is_in_group("player"):
		return true
	var script = node.get_script()
	if script and script.resource_path.ends_with("player.gd"):
		return true
	var lower_name = node.name.to_lower()
	return lower_name.contains("player") or lower_name.contains("eric")

func _buscar_jugador() -> Node3D:
	var tree := get_tree()
	if tree == null:
		return null
	var nodos_player = tree.get_nodes_in_group("player")
	for p in nodos_player:
		if p is Node3D and is_instance_valid(p) and p != self and p != get_parent():
			return p as Node3D
	var cur_scene = tree.current_scene
	if cur_scene and cur_scene.has_method("get_active_player"):
		return cur_scene.get_active_player() as Node3D
	var player_directo = tree.root.find_child("Player", true, false)
	if player_directo is Node3D and player_directo != self and player_directo != get_parent():
		return player_directo
	return null

func _orientar_personaje_hacia(personaje: Node3D, destino: Vector3) -> void:
	var to_dest: Vector3 = destino - personaje.global_position
	to_dest.y = 0
	if to_dest.length() < 0.05:
		return
	
	if personaje.has_method("_world_dir_to_input") and personaje.has_method("_resolve_direction"):
		var in_dir: Vector2 = personaje._world_dir_to_input(to_dest.normalized())
		if "last_input_dir" in personaje:
			personaje.last_input_dir = in_dir
		var dir_info = personaje._resolve_direction(in_dir)
		var sp = personaje.get_node_or_null("Sprite2_5D")
		if sp and sp is AnimatedSprite3D:
			sp.flip_h = dir_info.flip
			sp.play("walk_" + dir_info.suffix)
			sp.stop()

func _orientar_npc_hacia(pos_jugador: Vector3) -> void:
	var target_node: Node3D = nodo_visual_a_girar if nodo_visual_a_girar else (get_parent() as Node3D)
	if target_node == null:
		return
	
	if target_node.has_method("mirar_hacia"):
		target_node.mirar_hacia(pos_jugador)
		return
	
	_rotacion_original_npc = target_node.rotation
	
	var sprite: Sprite3D = target_node as Sprite3D
	if sprite == null:
		sprite = target_node.find_child("Sprite3D", true, false) as Sprite3D
	
	if sprite != null and sprite.billboard != BaseMaterial3D.BILLBOARD_DISABLED:
		# En sprites con billboard, giramos mediante flip_h
		sprite.flip_h = (pos_jugador.x < target_node.global_position.x)
	else:
		var dir: Vector3 = pos_jugador - target_node.global_position
		dir.y = 0
		if dir.length() > 0.05:
			target_node.look_at(target_node.global_position + dir, Vector3.UP)

func _restaurar_orientacion_npc() -> void:
	var target_node: Node3D = nodo_visual_a_girar if nodo_visual_a_girar else (get_parent() as Node3D)
	if target_node:
		if target_node.has_method("restaurar_pose_defecto"):
			target_node.restaurar_pose_defecto()
		else:
			target_node.rotation = _rotacion_original_npc

func _reproducir_sfx(stream: AudioStream) -> void:
	if stream == null or not is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"SFX"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _obtener_game_state():
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var root = get_tree().root if is_inside_tree() else null
	if root and root.has_node("GameState"):
		return root.get_node("GameState")
	return null

func _conectar_dialogue_manager() -> void:
	var dm = _obtener_dialogue_manager()
	if dm and not dm.dialogue_ended.is_connected(_on_dialogue_manager_ended):
		dm.dialogue_ended.connect(_on_dialogue_manager_ended)

func _desconectar_dialogue_manager() -> void:
	var dm = _obtener_dialogue_manager()
	if dm and dm.dialogue_ended.is_connected(_on_dialogue_manager_ended):
		dm.dialogue_ended.disconnect(_on_dialogue_manager_ended)

func _obtener_dialogue_manager():
	if Engine.has_singleton("DialogueManager"):
		return Engine.get_singleton("DialogueManager")
	var root = get_tree().root if is_inside_tree() else null
	if root and root.has_node("DialogueManager"):
		return root.get_node("DialogueManager")
	return null

func _on_dialogue_manager_ended(res_fin: DialogueResource) -> void:
	if _en_dialogo and (_recurso_activo_dialogo == null or res_fin == _recurso_activo_dialogo):
		_recurso_activo_dialogo = null
		_finalizar_dialogo()

func _padre_es_interactuable() -> bool:
	if es_objeto_interactuable:
		return true
	var padre = get_parent()
	if padre == null:
		return false
	return padre.is_in_group("cofre") or "esta_abierto" in padre or padre.has_method("abrir") or padre.has_method("interactuar") or padre.has_method("_fase_1_abrir_y_saltar")

func _padre_esta_abierto() -> bool:
	var padre = get_parent()
	if padre == null:
		return false
	if "esta_abierto" in padre and padre.esta_abierto == true:
		return true
	if "abierto" in padre and padre.abierto == true:
		return true
	if "activado" in padre and padre.activado == true:
		return true
	return false

func _ejecutar_interaccion_en_padre() -> void:
	var padre = get_parent()
	if padre == null or not is_instance_valid(padre):
		return
	
	if _padre_esta_abierto():
		return
	
	if not metodo_personalizado_padre.is_empty() and padre.has_method(metodo_personalizado_padre):
		padre.call(metodo_personalizado_padre)
	elif padre.has_method("abrir"):
		padre.call("abrir", _jugador_activo)
	elif padre.has_method("interactuar"):
		padre.call("interactuar", _jugador_activo)
	elif padre.has_method("_fase_1_abrir_y_saltar"):
		padre.call("_fase_1_abrir_y_saltar")
	elif padre.has_method("activar"):
		padre.call("activar")
	
	if desactivar_tras_abrir_objeto:
		desactivar()
