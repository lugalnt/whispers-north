extends "res://scripts/world/zona_mundo.gd"

## Controlador de la Escena 5: Bosque y Ruinas (World_ForestRuins.tscn).
## Gestiona:
##   - Población visual del bosque sobre las masas de arboleda (manteniendo colisiones exactas).
##   - Inscripciones y estelas rúnicas leíbles con pistas dinámicas de teclado/mando.
##   - Persistencia de los cofres de tesoro de las ruinas en GameState.
##   - Obtención del arma importante (Mandoble de las Ruinas) en el Gran Santuario.
##   - Cinemática, combate contra el jefe (Coloso de las Ruinas) y cierre de la demo.

const ID_COFRE_SE: StringName = &"cofre.ruinas_se"
const ID_COFRE_ESTE: StringName = &"cofre.ruinas_este"
const ID_COFRE_NO: StringName = &"cofre.ruinas_no"

const SfxFanfarria = preload("res://assets/audio/sfx/snd_moss_fanfare.wav")
const SfxRugido = preload("res://assets/audio/sfx/Roar_0.wav")
const SfxItem = preload("res://assets/audio/sfx/snd_item.wav")
const ItemMandoble = preload("res://data/items/mandoble_ruinas.tres")
const TemaNordico = preload("res://assets/sprites/ui/nordic_carved_v1/nordic_gameplay_theme.tres")

var _usa_mando: bool = false
var _secuencia_jefe_activa: bool = false
var _pantalla_fin_demo: CanvasLayer = null

@onready var pedestal_arma: Node3D = get_node_or_null("Ruinas/Pedestal_ArmaGrande")
@onready var espada_visual: Node3D = get_node_or_null("Ruinas/Pedestal_ArmaGrande/EspadaVisual")
@onready var luz_pedestal: OmniLight3D = get_node_or_null("Ruinas/Pedestal_ArmaGrande/LuzPedestal")
@onready var dialogo_pedestal: InteraccionDialogo = get_node_or_null("Ruinas/Pedestal_ArmaGrande/InteraccionDialogo")

@onready var guardian_jefe: Node3D = get_node_or_null("JefeRuinas/Guardian_Jefe")
@onready var visual_jefe: Node3D = get_node_or_null("JefeRuinas/Guardian_Jefe/Visual")
@onready var dialogo_jefe: InteraccionDialogo = get_node_or_null("JefeRuinas/Guardian_Jefe/InteraccionDialogo")
@onready var encuentro_jefe: EncuentroCombate = get_node_or_null("JefeRuinas/Guardian_Jefe/EncuentroCombate")
@onready var trigger_jefe: Area3D = get_node_or_null("JefeRuinas/TriggerCinematicaJefe")

@onready var altar_final: Node3D = get_node_or_null("JefeRuinas/Altar_SantuarioEste")
@onready var dialogo_altar_final: InteraccionDialogo = get_node_or_null("JefeRuinas/Altar_SantuarioEste/InteraccionDialogo")


func _ready() -> void:
	_poblar_bosque_sobre_arboleda()
	super._ready()
	_configurar_cofres()
	_configurar_inscripciones()
	_configurar_pedestal_arma()
	_configurar_jefe()
	_actualizar_indicadores_input()


func _input(event: InputEvent) -> void:
	preload("res://scripts/ui/input_hints.gd").registrar(event)
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and absf(event.axis_value) < 0.3:
			return
		_usa_mando = true
	elif event is InputEventKey or event is InputEventMouseButton:
		_usa_mando = false
	else:
		return
	_actualizar_indicadores_input()


func _control(accion: StringName) -> String:
	return preload("res://scripts/ui/input_hints.gd").accion(accion, _usa_mando)


func _actualizar_indicadores_input() -> void:
	var btn := _control(&"interact")
	var nodo_inscripciones := get_node_or_null("InscripcionesRuinas")
	if nodo_inscripciones:
		for estela in nodo_inscripciones.get_children():
			var dlg := estela.get_node_or_null("InteraccionDialogo") as InteraccionDialogo
			if dlg:
				_fijar_texto_indicador(dlg, "[%s] Leer inscripción" % btn)
	var nodo_cofres := get_node_or_null("CofresRuinas")
	if nodo_cofres:
		for hijo in nodo_cofres.get_children():
			var lbl := hijo.get_node_or_null("IndicadorCofre") as Label3D
			if lbl:
				lbl.text = "[%s] Abrir cofre" % btn
	if dialogo_pedestal:
		var gs = _obtener_game_state()
		if gs and gs.tiene_progreso(gs.OBJETO_IMPORTANTE_RUINAS):
			_fijar_texto_indicador(dialogo_pedestal, "[%s] Examinar pedestal" % btn)
		else:
			_fijar_texto_indicador(dialogo_pedestal, "[%s] Empuñar Mandoble" % btn)
	if dialogo_jefe:
		_fijar_texto_indicador(dialogo_jefe, "[%s] Desafiar al Coloso" % btn)
	if dialogo_altar_final:
		_fijar_texto_indicador(dialogo_altar_final, "[%s] Examinar Sello del Norte" % btn)


func _fijar_texto_indicador(dlg: InteraccionDialogo, texto: String) -> void:
	dlg.texto_indicador = texto
	if is_instance_valid(dlg._indicador_label):
		dlg._indicador_label.text = texto


# ---------------------------------------------------------------------------
# Población determinista del bosque sobre las masas de Arboleda
# ---------------------------------------------------------------------------

func _poblar_bosque_sobre_arboleda() -> void:
	var arboleda := get_node_or_null("Arboleda")
	if arboleda == null or has_node("BosqueGenerado"):
		return

	var rutas_tex := [
		"res://assets/sprites/environment/nordic_props_v1/nordic_pine.png",
		"res://assets/sprites/environment/trees/tree1_snowy.png",
		"res://assets/sprites/environment/trees/tree1.png",
		"res://assets/sprites/environment/nordic_props_v1/dense_bush.png",
		"res://assets/sprites/environment/nordic_props_v1/grass_tuft.png",
		"res://assets/sprites/environment/nordic_props_v1/mossy_rock.png",
		"res://assets/sprites/environment/nordic_props_v1/snow_bank.png",
	]
	var texturas: Array[Texture2D] = []
	var recortes: Array[Rect2i] = []
	for ruta in rutas_tex:
		var tex: Texture2D = load(ruta)
		texturas.append(tex)
		recortes.append(tex.get_image().get_used_rect())

	var contenedor_bosque := Node3D.new()
	contenedor_bosque.name = "BosqueGenerado"
	add_child(contenedor_bosque)

	var colisiones_bosque := StaticBody3D.new()
	colisiones_bosque.name = "ColisionesArboleda"
	colisiones_bosque.collision_layer = 1
	colisiones_bosque.collision_mask = 0
	add_child(colisiones_bosque)

	var mat_sotobosque := StandardMaterial3D.new()
	mat_sotobosque.albedo_texture = load("res://assets/sprites/environment/materials/nordic_v1/cold_grass.png")
	mat_sotobosque.albedo_color = Color(0.52, 0.64, 0.54, 1.0)
	mat_sotobosque.uv1_triplanar = true
	mat_sotobosque.uv1_scale = Vector3(0.3, 0.3, 0.3)
	mat_sotobosque.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	var rects_masas: Array[Rect2] = []
	for hijo in arboleda.get_children():
		if hijo is CSGBox3D:
			var caja := hijo as CSGBox3D
			var pos := caja.position
			var tam := caja.size
			# Transferir la colisión exacta a StaticBody3D para que world_presentation
			# ignore el volumen al hacer raycast y apoye los árboles sobre el suelo.
			var col := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(tam.x, 3.2, tam.z)
			col.shape = shape
			col.position = Vector3(pos.x, 1.6, pos.z)
			colisiones_bosque.add_child(col)

			# Convertir el bloque verde prototipo en un lecho bajo de musgo forestal.
			caja.use_collision = false
			caja.size.y = 0.05
			caja.position.y = 0.025
			caja.material = mat_sotobosque

			rects_masas.append(Rect2(Vector2(pos.x - tam.x * 0.5, pos.z - tam.z * 0.5), Vector2(tam.x, tam.z)))

	var rng := RandomNumberGenerator.new()
	rng.seed = 20261116
	var troncos: Array[Vector2] = []

	for rect in rects_masas:
		var interno := rect.grow(-0.55)
		if interno.size.x <= 0.4 or interno.size.y <= 0.4:
			interno = rect
		var area_m2: float = maxf(1.0, rect.size.x * rect.size.y)
		var intentos: int = clampi(int(area_m2 * 0.55), 4, 180)
		for _i in intentos:
			var p := Vector2(
				rng.randf_range(interno.position.x, interno.end.x),
				rng.randf_range(interno.position.y, interno.end.y)
			)
			# No invadir la boca de la cueva en la esquina inferior izquierda
			if p.x < 6.5 and p.y > 53.0 and p.y < 69.0:
				continue
			var libre := true
			for otro in troncos:
				if otro.distance_squared_to(p) < 5.2:
					libre = false
					break
			if not libre:
				continue
			troncos.append(p)
			var especie: int = 0 if rng.randf() < 0.62 else (1 if rng.randf() < 0.65 else 2)
			var altura: float = rng.randf_range(3.6, 6.2)
			_instanciar_sprite_bosque(contenedor_bosque, texturas[especie], recortes[especie], p, altura, rng, false)

			if rng.randf() < 0.45:
				var offset_decor := p + Vector2(rng.randf_range(-1.4, 1.4), rng.randf_range(-1.2, 1.2))
				if rect.has_point(offset_decor):
					var tipo_d: int = rng.randi_range(3, 6)
					var alto_d: float = rng.randf_range(0.42, 0.95) if tipo_d != 3 else rng.randf_range(0.85, 1.35)
					_instanciar_sprite_bosque(contenedor_bosque, texturas[tipo_d], recortes[tipo_d], offset_decor, alto_d, rng, true)


func _instanciar_sprite_bosque(padre: Node3D, textura: Texture2D, recorte: Rect2i, punto: Vector2, altura: float, rng: RandomNumberGenerator, es_bajo: bool) -> void:
	var sprite := Sprite3D.new()
	sprite.texture = textura
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	sprite.pixel_size = altura / maxf(float(recorte.size.y), 1.0)
	sprite.flip_h = rng.randf() < 0.5
	sprite.scale.x = rng.randf_range(0.86, 1.12)
	var tono := rng.randf_range(0.86, 1.04)
	sprite.modulate = Color(0.76 * tono, 0.84 * tono, 0.82 * tono, 1.0) if not es_bajo else Color(0.82 * tono, 0.88 * tono, 0.84 * tono, 1.0)
	padre.add_child(sprite)
	var pie: float = (float(textura.get_height()) * 0.5 - float(recorte.end.y)) * sprite.pixel_size
	sprite.position = Vector3(punto.x, -pie - 0.05, punto.y)


# ---------------------------------------------------------------------------
# Cofres y Tesoros de las Ruinas
# ---------------------------------------------------------------------------

func _configurar_cofres() -> void:
	var gs = _obtener_game_state()
	var mapa_cofres := {
		"CofresRuinas/Cofre_RuinaSE": ID_COFRE_SE,
		"CofresRuinas/Cofre_RuinaEste": ID_COFRE_ESTE,
		"CofresRuinas/Cofre_RuinasNO": ID_COFRE_NO,
	}
	for ruta in mapa_cofres:
		var cofre := get_node_or_null(ruta) as Node3D
		if cofre == null:
			continue
		var id_flag: StringName = mapa_cofres[ruta]
		_crear_indicador_cofre(cofre)
		if gs != null and gs.tiene_progreso(id_flag):
			cofre.esta_abierto = true
			var cerrado := cofre.get_node_or_null("StaticBody3D/Closed") as Node3D
			var abierto := cofre.get_node_or_null("StaticBody3D/Open") as Node3D
			if cerrado:
				cerrado.hide()
			if abierto:
				abierto.show()
		else:
			if cofre.has_signal("recompensas_entregadas"):
				cofre.recompensas_entregadas.connect(_al_abrir_cofre_ruinas.bind(cofre, id_flag))


func _crear_indicador_cofre(cofre: Node3D) -> void:
	if cofre.has_node("IndicadorCofre"):
		return
	var lbl := Label3D.new()
	lbl.name = "IndicadorCofre"
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, 1.35, 0)
	lbl.text = "[%s] Abrir cofre" % _control(&"interact")
	lbl.font_size = 22
	lbl.outline_size = 6
	lbl.outline_modulate = Color.BLACK
	lbl.modulate = Color(1.0, 0.9, 0.4, 0.0)
	lbl.no_depth_test = true
	lbl.render_priority = 10
	lbl.hide()
	cofre.add_child(lbl)


func _process(delta: float) -> void:
	var nodo_cofres := get_node_or_null("CofresRuinas")
	if nodo_cofres == null:
		return
	for cofre in nodo_cofres.get_children():
		var lbl := cofre.get_node_or_null("IndicadorCofre") as Label3D
		if lbl == null:
			continue
		var mostrar: bool = ("jugador_cerca" in cofre and cofre.jugador_cerca) and not ("esta_abierto" in cofre and cofre.esta_abierto)
		if mostrar:
			lbl.show()
			lbl.modulate.a = move_toward(lbl.modulate.a, 1.0, delta * 5.0)
		else:
			lbl.modulate.a = move_toward(lbl.modulate.a, 0.0, delta * 6.0)
			if lbl.modulate.a <= 0.01:
				lbl.hide()


func _al_abrir_cofre_ruinas(items_entregados: Array[Dictionary], texto_resumen: String, cofre: Node3D, id_flag: StringName) -> void:
	var gs = _obtener_game_state()
	if gs:
		gs.marcar_progreso(id_flag, true)

	var descripciones: Array[String] = []
	for entry in items_entregados:
		var it: InventoryItem = entry.get("item")
		var cant: int = int(entry.get("cant", 1))
		if it != null:
			var detalle: String = "%dx [%s]" % [cant, it.nombre]
			if not it.descripcion.is_empty():
				detalle += " — %s" % it.descripcion
			descripciones.append(detalle)

	var mensaje_cofre: String = "¡Abriste el cofre de las ruinas!\nObtuviste: " + (", ".join(descripciones) if not descripciones.is_empty() else texto_resumen)
	cofre.set_meta("ultimo_mensaje_recompensa", mensaje_cofre)

	var jugador := get_active_player()
	# Mostrar diálogo informativo en partida interactiva
	if jugador != null and jugador.is_physics_processing() and DisplayServer.get_name() != "headless":
		var dlg_temp := InteraccionDialogo.new()
		dlg_temp.mostrar_indicador = false
		dlg_temp.orientar_npc_al_jugador = false
		dlg_temp.orientar_jugador_al_hablar = false
		dlg_temp.sfx_iniciar = null
		dlg_temp.nombre_hablante = "Cofre de las Ruinas"
		dlg_temp.lineas_rapidas = [mensaje_cofre]
		cofre.add_child(dlg_temp)
		dlg_temp.dialogo_terminado.connect(func():
			_liberar_referencias_dialogo(dlg_temp)
			dlg_temp.queue_free()
		, CONNECT_ONE_SHOT)
		dlg_temp.iniciar_dialogo(jugador)


# ---------------------------------------------------------------------------
# Inscripciones / Ruinas Leíbles
# ---------------------------------------------------------------------------

func _configurar_inscripciones() -> void:
	var nodo_inscripciones := get_node_or_null("InscripcionesRuinas")
	if nodo_inscripciones:
		for estela in nodo_inscripciones.get_children():
			var dlg := estela.get_node_or_null("InteraccionDialogo") as InteraccionDialogo
			if dlg and not dlg.dialogo_terminado.is_connected(_liberar_referencias_dialogo):
				dlg.dialogo_terminado.connect(_liberar_referencias_dialogo.bind(dlg))
	if dialogo_altar_final and not dialogo_altar_final.dialogo_terminado.is_connected(_liberar_referencias_dialogo):
		dialogo_altar_final.dialogo_terminado.connect(_liberar_referencias_dialogo.bind(dialogo_altar_final))


# ---------------------------------------------------------------------------
# Arma Grande / Ítem Importante (Mandoble de las Ruinas)
# ---------------------------------------------------------------------------

func _configurar_pedestal_arma() -> void:
	if dialogo_pedestal == null:
		return
	var gs = _obtener_game_state()
	if gs != null and gs.tiene_progreso(gs.OBJETO_IMPORTANTE_RUINAS):
		_aplicar_estado_pedestal_reclamado()
	else:
		dialogo_pedestal.cambiar_lineas_rapidas([
			"Sobre el altar del Gran Santuario reposa el [Mandoble de las Ruinas], grabado con runas boreales.",
			"Al empuñarlo, una corriente cálida recorre tus brazos. ¡Obtuviste el Mandoble de las Ruinas (+4 ATQ y Salud restaurada)!"
		], "Altar del Gran Santuario")
	if not dialogo_pedestal.dialogo_terminado.is_connected(_al_terminar_dialogo_pedestal):
		dialogo_pedestal.dialogo_terminado.connect(_al_terminar_dialogo_pedestal)


func _al_terminar_dialogo_pedestal() -> void:
	_liberar_referencias_dialogo(dialogo_pedestal)
	var gs = _obtener_game_state()
	if gs != null and gs.reclamar_unico(gs.OBJETO_IMPORTANTE_RUINAS):
		gs.agregar_item(ItemMandoble, 1)
		gs.aumentar_ataque(4)
		gs.curar_hp(999)
		_reproducir_sfx_2d(SfxFanfarria)
		if pedestal_arma:
			preload("res://scripts/vfx/nordic_vfx.gd").emitir(self, &"recogida", pedestal_arma.global_position + Vector3(0, 1.4, 0), 1.4)
		_aplicar_estado_pedestal_reclamado()


func _aplicar_estado_pedestal_reclamado() -> void:
	if espada_visual:
		espada_visual.hide()
	if luz_pedestal:
		luz_pedestal.light_energy = 0.45
	if dialogo_pedestal:
		dialogo_pedestal.cambiar_lineas_rapidas([
			"El pedestal rúnico aún conserva el calor ancestral. Ya empuñas el Mandoble de las Ruinas."
		], "Altar del Gran Santuario")
	_actualizar_indicadores_input()


# ---------------------------------------------------------------------------
# Cinemática y Pelea con el Jefe Final (Coloso de las Ruinas)
# ---------------------------------------------------------------------------

func _configurar_jefe() -> void:
	var gs = _obtener_game_state()
	if gs != null and gs.tiene_progreso(gs.JEFE_RUINAS_DERROTADO):
		if guardian_jefe:
			guardian_jefe.hide()
		if dialogo_jefe:
			dialogo_jefe.desactivar()
		if trigger_jefe:
			trigger_jefe.monitoring = false
		return

	if trigger_jefe and not trigger_jefe.body_entered.is_connected(_on_trigger_jefe_body_entered):
		trigger_jefe.body_entered.connect(_on_trigger_jefe_body_entered)
	if dialogo_jefe and not dialogo_jefe.dialogo_iniciado.is_connected(_preparar_lineas_jefe):
		dialogo_jefe.dialogo_iniciado.connect(_preparar_lineas_jefe)
	if dialogo_jefe and not dialogo_jefe.dialogo_terminado.is_connected(_al_terminar_dialogo_jefe):
		dialogo_jefe.dialogo_terminado.connect(_al_terminar_dialogo_jefe)


func _on_trigger_jefe_body_entered(body: Node3D) -> void:
	if _secuencia_jefe_activa:
		return
	var activo := get_active_player()
	if body != activo or activo == null:
		return
	# Ignorar teletransportaciones de suites de prueba donde physics_process está desactivado
	if not activo.is_physics_processing() or not activo.is_visible_in_tree():
		return
	var gs = _obtener_game_state()
	if gs != null and gs.tiene_progreso(gs.JEFE_RUINAS_DERROTADO):
		return
	iniciar_cinematica_y_pelea_jefe(activo)


func _preparar_lineas_jefe() -> void:
	if dialogo_jefe == null:
		return
	var gs = _obtener_game_state()
	if gs != null and gs.tiene_progreso(gs.OBJETO_IMPORTANTE_RUINAS):
		dialogo_jefe.cambiar_lineas_rapidas([
			"...Siglos de letargo bajo la escarcha... y al fin despierta el fulgor del Mandoble de las Ruinas...",
			"Portador del acero antiguo: si deseas cruzar el último umbral del Norte, ¡demuestra tu determinación en combate!"
		], "Coloso de las Ruinas")
	else:
		dialogo_jefe.cambiar_lineas_rapidas([
			"...Intruso que pisas el santuario carmesí sin la reliquia de los antiguos...",
			"¡Mi coraza de piedra ancestral pondrá a prueba tu valor!"
		], "Coloso de las Ruinas")


func iniciar_cinematica_y_pelea_jefe(jugador: CharacterBody3D = null) -> void:
	if _secuencia_jefe_activa:
		return
	var gs = _obtener_game_state()
	if gs != null and gs.tiene_progreso(gs.JEFE_RUINAS_DERROTADO):
		return
	if jugador == null:
		jugador = get_active_player()
	if jugador == null:
		return

	_secuencia_jefe_activa = true
	_activar_camara("Camera10")
	_reproducir_sfx_2d(SfxRugido)

	if visual_jefe:
		var escala_orig := visual_jefe.scale
		var tw := create_tween()
		tw.tween_property(visual_jefe, "scale", escala_orig * Vector3(1.18, 0.86, 1.18), 0.16)
		tw.tween_property(visual_jefe, "scale", escala_orig * Vector3(0.92, 1.14, 0.92), 0.18)
		tw.tween_property(visual_jefe, "scale", escala_orig, 0.14)

	_preparar_lineas_jefe()
	if dialogo_jefe and dialogo_jefe.activo:
		dialogo_jefe.iniciar_dialogo(jugador)
		if not dialogo_jefe._en_dialogo:
			await _ejecutar_combate_jefe(jugador)
	else:
		await _ejecutar_combate_jefe(jugador)


func _al_terminar_dialogo_jefe() -> void:
	_liberar_referencias_dialogo(dialogo_jefe)
	var jugador := get_active_player()
	await _ejecutar_combate_jefe(jugador)


func _ejecutar_combate_jefe(jugador: CharacterBody3D) -> void:
	if encuentro_jefe == null or jugador == null:
		_secuencia_jefe_activa = false
		return
	var gs = _obtener_game_state()
	if gs != null and gs.tiene_progreso(gs.JEFE_RUINAS_DERROTADO):
		_secuencia_jefe_activa = false
		return

	var resultado: CombatArena.ResultadoCombate = await encuentro_jefe.iniciar_combate(jugador, guardian_jefe)
	if resultado == CombatArena.ResultadoCombate.VICTORIA:
		_completar_victoria_jefe()
	_secuencia_jefe_activa = false


func _completar_victoria_jefe() -> void:
	var gs = _obtener_game_state()
	if gs != null:
		if gs.reclamar_unico(gs.OBJETO_IMPORTANTE_RUINAS):
			gs.agregar_item(ItemMandoble, 1)
			gs.aumentar_ataque(4)
		gs.marcar_progreso(gs.JEFE_RUINAS_DERROTADO, true)
		gs.marcar_progreso(gs.DEMO_COMPLETADA, true)

	if guardian_jefe:
		guardian_jefe.hide()
	if dialogo_jefe:
		dialogo_jefe.desactivar()
	if trigger_jefe:
		trigger_jefe.set_deferred("monitoring", false)

	_reproducir_sfx_2d(SfxFanfarria)
	_mostrar_pantalla_fin_demo()


func _mostrar_pantalla_fin_demo() -> void:
	if _pantalla_fin_demo != null and is_instance_valid(_pantalla_fin_demo):
		return

	var jugador := get_active_player()
	if jugador and "is_interacting" in jugador:
		jugador.is_interacting = true
		jugador.velocity = Vector3.ZERO

	var gs = _obtener_game_state()
	var canvas := CanvasLayer.new()
	canvas.name = "PantallaFinDemo"
	canvas.layer = 115
	_pantalla_fin_demo = canvas

	var fondo := ColorRect.new()
	fondo.color = Color(0.03, 0.05, 0.08, 0.88)
	fondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fondo)

	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	if TemaNordico:
		centro.theme = TemaNordico
	canvas.add_child(centro)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(560, 340)
	centro.add_child(panel)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 32)
	margen.add_theme_constant_override("margin_right", 32)
	margen.add_theme_constant_override("margin_top", 28)
	margen.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margen)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margen.add_child(vbox)

	var titulo := Label.new()
	titulo.text = "¡DEMO COMPLETADA!"
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	vbox.add_child(titulo)

	var subtitulo := Label.new()
	subtitulo.text = "Whispers of the North — Bosque y Ruinas"
	subtitulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitulo.add_theme_font_size_override("font_size", 18)
	subtitulo.add_theme_color_override("font_color", Color(0.78, 0.88, 0.96))
	vbox.add_child(subtitulo)

	var cuerpo := Label.new()
	cuerpo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cuerpo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var niv: int = gs.nivel if gs else 1
	var atq: int = gs.stats.ataque if (gs and gs.stats) else 2
	cuerpo.text = "El Coloso de las Ruinas ha caído y el Mandoble ancestral vuelve a brillar.\n\nNivel alcanzado: %d  ·  Ataque: %d\n¡Gracias por jugar la demo!" % [niv, atq]
	vbox.add_child(cuerpo)

	var botones := HBoxContainer.new()
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_theme_constant_override("separation", 20)
	vbox.add_child(botones)

	var btn_explorar := Button.new()
	btn_explorar.name = "BtnSeguirExplorando"
	btn_explorar.text = "Seguir explorando"
	btn_explorar.custom_minimum_size = Vector2(200, 44)
	btn_explorar.pressed.connect(func():
		var act := get_active_player()
		if act and "is_interacting" in act:
			act.is_interacting = false
		if is_instance_valid(canvas):
			canvas.queue_free()
		_pantalla_fin_demo = null
	)
	botones.add_child(btn_explorar)

	var btn_menu := Button.new()
	btn_menu.name = "BtnMenuPrincipal"
	btn_menu.text = "Menú Principal"
	btn_menu.custom_minimum_size = Vector2(200, 44)
	btn_menu.pressed.connect(func():
		var act := get_active_player()
		if act and "is_interacting" in act:
			act.is_interacting = false
		if is_instance_valid(canvas):
			canvas.queue_free()
		_pantalla_fin_demo = null
		get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	)
	botones.add_child(btn_menu)

	add_child(canvas)
	btn_explorar.grab_focus()


func _reproducir_sfx_2d(stream: AudioStream) -> void:
	if stream == null or not is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"SFX"
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _liberar_referencias_dialogo(dialogo: InteraccionDialogo) -> void:
	if dialogo == null:
		return
	var recurso := dialogo._recurso_generado_cache
	if recurso:
		for linea in recurso.lines.values():
			if linea is Dictionary and linea.get(&"resource") == recurso:
				linea.erase(&"resource")
