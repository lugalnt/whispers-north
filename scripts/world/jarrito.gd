@tool
class_name Jarrito
extends CharacterBody3D

## Enemigo de exploración. Delega la arena al componente EncuentroCombate.
signal inicio_combate(protagonista: CharacterBody3D)
signal estado_cambiado(estado_actual: Estado)

enum Estado { IDLE, ALERT, WALK, ENCOUNTER, RETURN }

const ANIMACIONES: Array[StringName] = [&"Idle", &"Alert", &"Walk", &"Encounter", &"Walk"]
const RUTA_LLAMA: String = "CTRL_Jarro/Flame_Main"

@export_group("Detección y Persecución")
## Radio de detección (metros). Actualiza en tiempo real el área y la vista previa 3D en el editor.
@export_range(0.5, 20.0, 0.25, "or_greater", "suffix:m") var radio_deteccion: float = 4.5:
	set(valor):
		radio_deteccion = maxf(valor, 0.1)
		_sincronizar_area_deteccion()
		_actualizar_preview_editor()
## Distancia plana desde Jarrito a la que abandona la persecución y vuelve al origen.
@export_range(1.0, 35.0, 0.5, "or_greater", "suffix:m") var distancia_perdida: float = 10.0:
	set(valor):
		distancia_perdida = maxf(valor, 0.5)
		_actualizar_preview_editor()
## Dibuja en el visor 3D del editor el anillo cian de detección y el anillo naranja de abandono.
@export var mostrar_rango_editor: bool = true:
	set(valor):
		mostrar_rango_editor = valor
		_actualizar_preview_editor()
@export_range(0.1, 20.0, 0.1, "suffix:m/s") var velocidad: float = 3.4
@export_range(0.1, 50.0, 0.1) var aceleracion: float = 12.0
@export_range(0.1, 30.0, 0.1) var velocidad_giro: float = 8.0
@export var requiere_linea_de_vista: bool = true
@export var altura_ojos: float = 0.8
var _posicion_inicial: Vector3

@export var grupo_protagonista: StringName = &"player"

@export_group("Grupo y detección")
## Los miembros activos de este grupo entran juntos en una única arena.
@export var grupo_encuentro: StringName = &""
@export var sonido_deteccion: AudioStream = preload("res://assets/audio/sfx/snd_mysterygo.wav")
@export_range(-40.0, 6.0) var volumen_deteccion_db: float = -6.0
var _audio_deteccion: AudioStreamPlayer3D
var _sesion_grupo: RefCounted

@export_group("Encuentro")
@export_range(0.1, 30.0, 0.1, "suffix:s") var tiempo_recuperacion: float = 3.0
@export var combate_habilitado: bool = true
var _recuperacion: float = 0.0
var _solicitando: bool = false
var _derrotado: bool = false
var _id_derrota: StringName = &""

@export_group("Dimensiones de colisión")
@export_range(0.1, 5.0, 0.05, "suffix:m") var radio_cuerpo: float = 0.65:
	set(valor):
		radio_cuerpo = maxf(valor, 0.05)
		_sincronizar_area_cuerpo()
@export_range(0.1, 10.0, 0.05, "suffix:m") var altura_cuerpo: float = 1.0:
	set(valor):
		altura_cuerpo = maxf(valor, 0.05)
		_sincronizar_area_cuerpo()
const MARGEN_CONTACTO: float = 0.02
@export_range(0.1, 10.0, 0.1, "suffix:m") var altura_areas: float = 2.5:
	set(valor):
		altura_areas = maxf(valor, 0.1)
		_sincronizar_area_deteccion()

var estado: Estado = Estado.IDLE
var _objetivo: CharacterBody3D
var _gravedad: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))

@onready var _visual: Node3D = $Visual
@onready var _modelo: Node3D = $Visual/Modelo
@onready var _original: AnimationPlayer = $Visual/Modelo/AnimationPlayer
@onready var _cuerpo: AnimationPlayer = $BodyAnimationPlayer
@onready var _fuego: AnimationPlayer = $FlameAnimationPlayer
@onready var _deteccion: Area3D = $DetectionArea
@onready var _encuentro: Area3D = $EncounterArea
@onready var _combate: EncuentroCombate = $EncuentroCombate
var _coordinador: Node = null


func _ready() -> void:
	if Engine.is_editor_hint():
		set_physics_process(false)
		_sincronizar_area_cuerpo()
		_sincronizar_area_deteccion()
		_actualizar_preview_editor()
		return
	var preview_ed := get_node_or_null("_EditorRangoDeteccion")
	if preview_ed:
		preview_ed.queue_free()
	_coordinador = get_node_or_null("/root/CoordinadorEncuentros")
	var mundo: Node = get_parent()
	while mundo != null and not mundo.has_method("get_active_player"):
		mundo = mundo.get_parent()
	if mundo != null and not mundo.scene_file_path.is_empty():
		_id_derrota = StringName("enemigo." + mundo.scene_file_path + ":" + str(mundo.get_path_to(self)))
		if get_node("/root/GameState").tiene_progreso(_id_derrota):
			queue_free()
			return
	_posicion_inicial = global_position
	if grupo_encuentro != &"":
		add_to_group(grupo_encuentro)
	_audio_deteccion = AudioStreamPlayer3D.new()
	_audio_deteccion.name = "SonidoDeteccion"
	_audio_deteccion.stream = sonido_deteccion
	_audio_deteccion.bus = &"SFX"
	_audio_deteccion.volume_db = volumen_deteccion_db
	_audio_deteccion.unit_size = 4.0
	_audio_deteccion.max_distance = 24.0
	add_child(_audio_deteccion)
	# Formas nuevas por instancia: los ajustes nunca alteran recursos compartidos.
	_configurar_cilindro($CollisionShape3D, radio_cuerpo, altura_cuerpo)
	_configurar_cilindro($DetectionArea/CollisionShape3D, radio_deteccion, altura_areas)
	# El sensor coincide con el cuerpo; la tolerancia cubre el margen del motor físico.
	_configurar_cilindro($EncounterArea/CollisionShape3D, radio_cuerpo + MARGEN_CONTACTO, altura_cuerpo)
	if not _preparar_animaciones():
		set_physics_process(false)
		return
	_cuerpo.animation_finished.connect(_al_terminar_animacion)
	_cuerpo.play(&"Idle")
	_fuego.play(&"Flame")
	_combate.combate_iniciado.connect(func(): inicio_combate.emit(_objetivo))


func _configurar_cilindro(colision: CollisionShape3D, radio: float, altura: float) -> void:
	var forma: CylinderShape3D = CylinderShape3D.new()
	forma.resource_local_to_scene = true
	forma.radius = maxf(radio, 0.01)
	forma.height = maxf(altura, 0.01)
	colision.shape = forma
	colision.position.y = forma.height * 0.5


func _sincronizar_area_deteccion() -> void:
	if not is_node_ready():
		return
	var col := get_node_or_null("DetectionArea/CollisionShape3D") as CollisionShape3D
	if col == null:
		return
	var forma := col.shape as CylinderShape3D
	if forma != null and (not Engine.is_editor_hint() or forma.resource_local_to_scene):
		forma.radius = maxf(radio_deteccion, 0.1)
		forma.height = maxf(altura_areas, 0.1)
		col.position.y = forma.height * 0.5


func _sincronizar_area_cuerpo() -> void:
	if not is_node_ready():
		return
	for par in [
		[get_node_or_null("CollisionShape3D") as CollisionShape3D, radio_cuerpo],
		[get_node_or_null("EncounterArea/CollisionShape3D") as CollisionShape3D, radio_cuerpo + MARGEN_CONTACTO],
	]:
		var col := par[0] as CollisionShape3D
		if col == null:
			continue
		var forma := col.shape as CylinderShape3D
		if forma != null and (not Engine.is_editor_hint() or forma.resource_local_to_scene):
			forma.radius = maxf(float(par[1]), 0.05)
			forma.height = maxf(altura_cuerpo, 0.05)
			col.position.y = forma.height * 0.5


func _actualizar_preview_editor() -> void:
	if not Engine.is_editor_hint() or not is_inside_tree():
		return
	var cont := get_node_or_null("_EditorRangoDeteccion") as Node3D
	if not mostrar_rango_editor:
		if cont:
			cont.hide()
		return
	if cont == null:
		cont = _crear_preview_editor()
	cont.show()
	var disco := cont.get_node_or_null("DiscoDeteccion") as MeshInstance3D
	if disco and disco.mesh is CylinderMesh:
		var cyl := disco.mesh as CylinderMesh
		cyl.top_radius = radio_deteccion
		cyl.bottom_radius = radio_deteccion
	var anillos := cont.get_node_or_null("Anillos") as MeshInstance3D
	if anillos and anillos.mesh is ImmediateMesh:
		_redibujar_anillos_editor(anillos.mesh as ImmediateMesh)


func _crear_preview_editor() -> Node3D:
	var cont := Node3D.new()
	cont.name = "_EditorRangoDeteccion"

	var disco := MeshInstance3D.new()
	disco.name = "DiscoDeteccion"
	disco.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cyl := CylinderMesh.new()
	cyl.top_radius = radio_deteccion
	cyl.bottom_radius = radio_deteccion
	cyl.height = 0.02
	cyl.radial_segments = 48
	disco.mesh = cyl
	var mat_disco := StandardMaterial3D.new()
	mat_disco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_disco.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_disco.albedo_color = Color(0.15, 0.85, 1.0, 0.12)
	mat_disco.cull_mode = BaseMaterial3D.CULL_DISABLED
	disco.material_override = mat_disco
	disco.position.y = 0.04
	cont.add_child(disco)

	var anillos := MeshInstance3D.new()
	anillos.name = "Anillos"
	anillos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	anillos.mesh = ImmediateMesh.new()
	var mat_lin := StandardMaterial3D.new()
	mat_lin.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_lin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_lin.vertex_color_use_as_albedo = true
	anillos.material_override = mat_lin
	anillos.position.y = 0.06
	cont.add_child(anillos)

	add_child(cont)
	return cont


func _redibujar_anillos_editor(imm: ImmediateMesh) -> void:
	imm.clear_surfaces()
	imm.surface_begin(Mesh.PRIMITIVE_LINES)
	var pasos := 64
	var c_det := Color(0.2, 0.95, 1.0, 0.95)
	for i in pasos:
		var a0 := TAU * float(i) / float(pasos)
		var a1 := TAU * float(i + 1) / float(pasos)
		imm.surface_set_color(c_det)
		imm.surface_add_vertex(Vector3(cos(a0) * radio_deteccion, 0.0, sin(a0) * radio_deteccion))
		imm.surface_add_vertex(Vector3(cos(a1) * radio_deteccion, 0.0, sin(a1) * radio_deteccion))
	var r_aba := maxf(distancia_perdida, radio_deteccion + 0.5)
	var c_aba := Color(1.0, 0.65, 0.15, 0.55)
	for i in range(0, pasos, 2):
		var a0 := TAU * float(i) / float(pasos)
		var a1 := TAU * float(i + 1) / float(pasos)
		imm.surface_set_color(c_aba)
		imm.surface_add_vertex(Vector3(cos(a0) * r_aba, 0.0, sin(a0) * r_aba))
		imm.surface_add_vertex(Vector3(cos(a1) * r_aba, 0.0, sin(a1) * r_aba))
	imm.surface_end()


func _preparar_animaciones() -> bool:
	# El reproductor importado queda como fuente de solo lectura. Sus clips
	# incluyen pistas estáticas cruzadas: hay que quitarlas de las COPIAS.
	_original.stop()
	_original.active = false
	_original.set_process(false)
	_original.set_physics_process(false)
	for nombre in [&"Idle", &"Alert", &"Walk", &"Encounter"]:
		if not _original.has_animation(nombre):
			push_error("Jarrito: falta la animación %s." % nombre)
			return false
	if not _original.has_animation(&"Flame"):
		push_error("Jarrito: falta la animación Flame.")
		return false

	_cuerpo.root_node = _cuerpo.get_path_to(_modelo)
	_fuego.root_node = _fuego.get_path_to(_modelo)
	var biblioteca_cuerpo: AnimationLibrary = AnimationLibrary.new()
	for nombre in [&"Idle", &"Alert", &"Walk", &"Encounter"]:
		var animacion: Animation = _copiar_pistas(_original.get_animation(nombre), false)
		animacion.loop_mode = Animation.LOOP_LINEAR if nombre in [&"Idle", &"Walk"] else Animation.LOOP_NONE
		biblioteca_cuerpo.add_animation(nombre, animacion)
	_cuerpo.add_animation_library(&"", biblioteca_cuerpo)

	var biblioteca_fuego: AnimationLibrary = AnimationLibrary.new()
	var llama: Animation = _copiar_pistas(_original.get_animation(&"Flame"), true)
	llama.loop_mode = Animation.LOOP_LINEAR
	biblioteca_fuego.add_animation(&"Flame", llama)
	_fuego.add_animation_library(&"", biblioteca_fuego)
	return true


func _copiar_pistas(fuente: Animation, solo_fuego: bool) -> Animation:
	var copia: Animation = fuente.duplicate() as Animation
	for indice in range(copia.get_track_count() - 1, -1, -1):
		var ruta: String = String(copia.track_get_path(indice).get_concatenated_names())
		var es_fuego: bool = ruta == RUTA_LLAMA or ruta.begins_with(RUTA_LLAMA + "/")
		if es_fuego != solo_fuego:
			copia.remove_track(indice)
	return copia


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_recuperacion = maxf(0.0, _recuperacion - delta)
	if not is_on_floor():
		velocity.y -= _gravedad * delta
	# También cubre eliminación del componente/corrutina antes de devolver resultado.
	if _solicitando or _sesion_grupo != null:
		if not _coordinador.ocupado() or not is_instance_valid(_combate):
			recuperar_encuentro()
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if _coordinador.ocupado() or _recuperacion > 0.0 or _derrotado or not combate_habilitado:
		if estado != Estado.IDLE:
			_cambiar_estado(Estado.IDLE)
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if estado not in [Estado.WALK, Estado.RETURN]:
		velocity.x = move_toward(velocity.x, 0.0, aceleracion * delta)
		velocity.z = move_toward(velocity.z, 0.0, aceleracion * delta)

	if _objetivo_valido() and not _coordinador.disponible(_objetivo):
		# No perseguir durante diálogo, transición ni protección al salir de combate.
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	# El contacto inicia la reserva incluso durante Alert, sin esperar animaciones.
	if _iniciar_por_contacto():
		return
	if estado == Estado.IDLE:
		_buscar_protagonista()
		if estado == Estado.IDLE and _distancia_plana(_posicion_inicial) > 0.2:
			_cambiar_estado(Estado.RETURN)
	elif estado == Estado.RETURN:
		_buscar_protagonista()
		if estado == Estado.RETURN:
			if _distancia_plana(_posicion_inicial) <= 0.2:
				_cambiar_estado(Estado.IDLE)
			else:
				_mover_hacia(_posicion_inicial, delta, 0.7)
	elif estado != Estado.ENCOUNTER:
		var limite_perdida: float = maxf(distancia_perdida, radio_deteccion + 0.5)
		if not _objetivo_valido() or _distancia_plana(_objetivo.global_position) > limite_perdida:
			_objetivo = null
			_cambiar_estado(Estado.RETURN)
		elif estado == Estado.WALK:
			_perseguir(delta)

	move_and_slide()


func _es_protagonista(candidato: Node3D) -> bool:
	if not candidato is CharacterBody3D or not candidato.is_in_group(grupo_protagonista):
		return false
	if not candidato.is_visible_in_tree() or not candidato.is_physics_processing():
		return false
	# World tiene dos versiones del jugador; solo perseguir la activa.
	var mundo: Node = get_tree().current_scene
	if mundo != null and mundo.has_method("get_active_player"):
		return candidato == mundo.call("get_active_player")
	return true


func _objetivo_valido() -> bool:
	return is_instance_valid(_objetivo) and _es_protagonista(_objetivo)


func _buscar_protagonista() -> void:
	if not combate_habilitado:
		return
	for candidato in _deteccion.get_overlapping_bodies():
		if _es_protagonista(candidato) and _coordinador.disponible(candidato) and _puede_ver(candidato):
			_objetivo = candidato as CharacterBody3D
			_cambiar_estado(Estado.ALERT)
			return


func _perseguir(delta: float) -> void:
	_mover_hacia(_objetivo.global_position, delta)


func _mover_hacia(destino: Vector3, delta: float, factor: float = 1.0) -> void:
	var direccion: Vector3 = destino - global_position
	direccion.y = 0.0
	if direccion.length_squared() < 0.0001:
		return
	direccion = direccion.normalized()
	velocity.x = move_toward(velocity.x, direccion.x * velocidad * factor, aceleracion * delta)
	velocity.z = move_toward(velocity.z, direccion.z * velocidad * factor, aceleracion * delta)
	# Orientar el contenedor, sin sobrescribir CTRL_Jarro animado. Frente: -Z.
	var angulo: float = atan2(-direccion.x, -direccion.z)
	_visual.rotation.y = lerp_angle(_visual.rotation.y, angulo, minf(velocidad_giro * delta, 1.0))


func _cambiar_estado(nuevo_estado: Estado) -> void:
	if estado == nuevo_estado:
		return
	estado = nuevo_estado
	velocity.x = 0.0
	velocity.z = 0.0
	_cuerpo.play(ANIMACIONES[estado])
	if estado == Estado.ALERT and _audio_deteccion and sonido_deteccion:
		_audio_deteccion.play()
	estado_cambiado.emit(estado)


func _al_terminar_animacion(nombre: StringName) -> void:
	if estado == Estado.ALERT and nombre == &"Alert":
		if _objetivo_valido():
			_cambiar_estado(Estado.WALK)
		else:
			_cambiar_estado(Estado.IDLE)



func _iniciar_por_contacto() -> bool:
	for candidato in _encuentro.get_overlapping_bodies():
		if _es_protagonista(candidato) and _coordinador.disponible(candidato):
			_objetivo = candidato as CharacterBody3D
			_cambiar_estado(Estado.ENCOUNTER)
			_solicitar_encuentro()
			return _solicitando
	return false

func _en_alcance_de_encuentro() -> bool:
	return combate_habilitado and _objetivo_valido() and _encuentro.overlaps_body(_objetivo)


func _solicitar_encuentro() -> void:
	if not is_instance_valid(_combate) or not _en_alcance_de_encuentro():
		recuperar_encuentro()
		return
	var miembros := _miembros_encuentro()
	var enemigos_grupo: Array[PackedScene] = []
	for miembro in miembros:
		if not miembro._combate.enemigos.is_empty():
			enemigos_grupo.append(miembro._combate.enemigos[0])
	if enemigos_grupo.is_empty():
		recuperar_encuentro()
		return
	_combate.enemigos = enemigos_grupo
	_combate.exp_recompensa = 20 * miembros.size()
	_combate.texto_recompensas = "¡Victoria!\n+%d EXP" % _combate.exp_recompensa
	var registrar := _registrar_grupo.bind(miembros)
	_combate.reserva_confirmada.connect(registrar, CONNECT_ONE_SHOT)
	_solicitando = true
	var resultado: CombatArena.ResultadoCombate = await _combate.iniciar_combate(_objetivo, _visual, _en_alcance_de_encuentro)
	if _combate.reserva_confirmada.is_connected(registrar):
		_combate.reserva_confirmada.disconnect(registrar)
	if resultado == CombatArena.ResultadoCombate.VICTORIA:
		_retirar_derrotado()
	recuperar_encuentro()


func recuperar_encuentro() -> void:
	_solicitando = false
	_objetivo = null
	_recuperacion = tiempo_recuperacion
	_cambiar_estado(Estado.IDLE)


func _distancia_plana(destino: Vector3) -> float:
	return Vector2(destino.x - global_position.x, destino.z - global_position.z).length()


func _puede_ver(jugador: CharacterBody3D) -> bool:
	if not requiere_linea_de_vista:
		return true
	var desde := global_position + Vector3.UP * altura_ojos
	var hasta := jugador.global_position + Vector3.UP * 0.8
	var consulta := PhysicsRayQueryParameters3D.create(desde, hasta, collision_mask, [get_rid(), jugador.get_rid()])
	return get_world_3d().direct_space_state.intersect_ray(consulta).is_empty()


func _miembros_encuentro() -> Array[Jarrito]:
	var miembros: Array[Jarrito] = [self]
	if grupo_encuentro == &"":
		return miembros
	for nodo in get_tree().get_nodes_in_group(grupo_encuentro):
		if nodo is Jarrito and nodo != self and not nodo._derrotado and nodo.combate_habilitado and not nodo.is_queued_for_deletion():
			miembros.append(nodo)
	return miembros


func _registrar_grupo(sesion: RefCounted, miembros: Array[Jarrito]) -> void:
	for miembro in miembros:
		if not is_instance_valid(miembro):
			continue
		miembro._sesion_grupo = sesion
		sesion.recordar_visual(miembro._visual)
		miembro._visual.hide()
		sesion.finalizada.connect(miembro._finalizar_grupo.bind(sesion), CONNECT_ONE_SHOT)


func _finalizar_grupo(sesion: RefCounted) -> void:
	if not sesion.cancelada and sesion.resultado == CombatArena.ResultadoCombate.VICTORIA:
		_retirar_derrotado()
	_sesion_grupo = null
	recuperar_encuentro()

func _retirar_derrotado() -> void:
	if _derrotado: return
	_derrotado = true
	combate_habilitado = false
	hide()
	set_deferred("collision_layer", 0)
	if _id_derrota != &"": get_node("/root/GameState").marcar_progreso(_id_derrota)
	# Diferir para que el encuentro termine de restaurar controles y recursos.
	queue_free.call_deferred()


