class_name CombatArena
extends Node3D

## Arena de combate RPG estilo Paper Mario.
##
## Diseñada para ser modular y reutilizable:
##   - Gestiona el ciclo de turnos por iniciativa (velocidad).
##   - Soporta N aliados y N enemigos colocándolos en sus marcadores de posición.
##   - Proporciona utilidades para las acciones: comandos de acción (QTE / timing),
##     números de daño flotantes, sacudida de cámara, sonidos y mensajes.
##   - Menú de combate con navegación mediante acciones `ui_*` (soporta teclado y gamepad).
##   - El escenario visual (suelo, fondo, luces, etc.) vive en el nodo $Escenario y es fácil
##     de cambiar o intercambiar por diferentes arenas en el futuro.

signal combate_terminado(resultado: ResultadoCombate)

enum ResultadoCombate { VICTORIA, DERROTA, HUIDA }
enum EstadoTurno { ESPERANDO, TURNO_JUGADOR, SELECCIONANDO_OBJETIVO, ACCION_EN_CURSO, TERMINADO }

@export_group("Referencias")
@export var camara: Camera3D
@export var comando: ComandoAccion
@export var nodo_escenario: Node3D
@export var contenedor_aliados: Node3D
@export var contenedor_enemigos: Node3D
@export var ui_canvas: CanvasLayer

@export_group("Audio")
@export var musica_combate: AudioStream
## Jingle o fanfarria de inicio de combate
@export var jingle_inicio: AudioStream = preload("res://assets/audio/sfx/snd_mysterygo.wav")
@export var sonido_victoria: AudioStream = preload("res://assets/audio/sfx/snd_bell_bounce_short.wav")
@export var sonido_derrota: AudioStream = preload("res://assets/audio/sfx/scream.mp3")
@export var sonido_huida: AudioStream = preload("res://assets/audio/sfx/snd_dooropen.wav")
@export var sonido_cursor: AudioStream = preload("res://assets/audio/sfx/snd_item.wav")

@export_group("Textos de la Interfaz (HUD)")
## Mensaje mostrado al arrancar la batalla en el banner superior.
@export var texto_inicio_combate: String = "¡Empieza el combate!"
## Formato del banner cuando inicia el turno de un combatiente (%s = nombre).
@export var formato_texto_turno: String = "Turno de %s"
## Título del panel de acciones del jugador.
@export var texto_titulo_acciones: String = "ACCIONES"
## Nombre del botón de huida en el menú de acciones.
@export var texto_opcion_huir: String = "Huir"
## Descripción mostrada al colocarse sobre la opción Huir.
@export var texto_descripcion_huir: String = "Escapar del combate y volver al mapa."
## Mensaje mostrado en el banner al ganar el combate.
@export var texto_victoria: String = "¡Victoria!"
## Mensaje mostrado en el banner al caer derrotado.
@export var texto_derrota: String = "Has sido derrotado..."
## Mensaje mostrado en el banner al huir con éxito.
@export var texto_huida: String = "¡Escapaste del combate!"
## Título del panel de recompensas de victoria.
@export var texto_titulo_recompensas: String = "RECOMPENSAS"
## Formato del texto de vida en las barras del HUD (%d / %d HP).
@export var formato_hp: String = "%d / %d HP"

@export_group("Personalización de Arena")
## Textura de fondo personalizada para el escenario de la arena
@export var textura_fondo_custom: Texture2D
## Texto multilínea mostrado en el panel de recompensas tras la victoria
@export_multiline var texto_recompensas: String = "¡Ganaste el combate!\n\n+20 EXP\nObtuviste: [Fragmento de Cerámica Antiguo]"
## Cantidad de experiencia otorgada por la victoria
@export var exp_victoria: int = 20

@export_group("Prueba standalone")
## Si es true y no se pasan battlers externamente, inicializa con jugador y pot por defecto al pulsar F6
@export var auto_iniciar_si_esta_vacio: bool = true
@export var escena_battler_jugador_defecto: PackedScene = preload("res://scenes/combat/battlers/PlayerBattler.tscn")
@export var escena_battler_enemigo_defecto: PackedScene = preload("res://scenes/combat/battlers/PotBattler.tscn")

# Nodos de UI internos
@onready var menu_acciones: Control = $UICanvas/MenuAcciones
@onready var lista_botones: VBoxContainer = $UICanvas/MenuAcciones/VBox/VBoxBotones
@onready var desc_accion_label: Label = $UICanvas/MenuAcciones/VBox/LabelDescripcion
@onready var banner_turno: Label = $UICanvas/BannerTurno
@onready var selector_objetivo: Control = $UICanvas/SelectorObjetivo
@onready var contenedor_danio: Control = $UICanvas/ContenedorDanio
@onready var hud_aliados: VBoxContainer = $UICanvas/HUD/Aliados
@onready var hud_enemigos: VBoxContainer = $UICanvas/HUD/Enemigos
@onready var panel_recompensas: PanelContainer = $UICanvas/PanelRecompensas
@onready var label_recompensas: Label = $UICanvas/PanelRecompensas/MarginContainer/VBox/LabelTexto
@onready var reproductor_musica: AudioStreamPlayer = $MusicaPlayer

var aliados: Array[Battler] = []
var enemigos: Array[Battler] = []
var todos_los_battlers: Array[Battler] = []

var _estado: EstadoTurno = EstadoTurno.ESPERANDO
var _battler_actual: Battler = null
var _accion_seleccionada: BattlerAction = null
var _indice_objetivo: int = 0
var _objetivos_validos: Array[Battler] = []

var _opciones_menu: Array = []
var _botones_menu: Array[Button] = []
var _indice_menu_accion: int = 0
var _seleccion_menu_resultado = null
var _paneles_hud: Dictionary = {}

var _cam_pos_original: Vector3
var _jugador_mundo_ref: Node = null
var _jingle_reproducido: bool = false

func _ready() -> void:
	if camara:
		_cam_pos_original = camara.transform.origin
	if hud_aliados == null:
		hud_aliados = get_node_or_null("UICanvas/HUD/Aliados")
	if hud_enemigos == null:
		hud_enemigos = get_node_or_null("UICanvas/HUD/Enemigos")
	selector_objetivo.hide()
	menu_acciones.hide()
	banner_turno.hide()
	panel_recompensas.hide()

	_aplicar_textos_hud()

	if textura_fondo_custom != null and nodo_escenario != null:
		var fondo_sprite: Sprite3D = nodo_escenario.get_node_or_null("FondoSprite") as Sprite3D
		if fondo_sprite:
			fondo_sprite.texture = textura_fondo_custom

	if auto_iniciar_si_esta_vacio and get_tree().current_scene == self and aliados.is_empty() and enemigos.is_empty():
		inicializar([escena_battler_jugador_defecto], [escena_battler_enemigo_defecto], null)
		comenzar_combate.call_deferred()
	elif not aliados.is_empty() or not enemigos.is_empty():
		var gs = _obtener_game_state()
		if gs and gs.stats:
			for a in aliados:
				if a.controlado_por_jugador:
					a.stats.max_hp = gs.stats.max_hp
					a.stats.ataque = gs.stats.ataque
					a.stats.defensa = gs.stats.defensa
					a.stats.velocidad = gs.stats.velocidad
					if not gs.nombre_jugador.is_empty():
						a.nombre = gs.nombre_jugador
					if gs.hp_actual > 0:
						a.hp = clamp(gs.hp_actual, 1, a.stats.max_hp)
		_reconstruir_hud()

func _process(_delta: float) -> void:
	if _estado == EstadoTurno.SELECCIONANDO_OBJETIVO and _objetivos_validos.size() > 0:
		_actualizar_posicion_selector()

# ---------------------------------------------------------------------------
# Inicialización y preparación de la batalla
# ---------------------------------------------------------------------------

## Aplica los textos del inspector a los nodos de la interfaz
func _aplicar_textos_hud() -> void:
	if banner_turno:
		banner_turno.text = texto_inicio_combate
	if menu_acciones:
		var lbl_titulo_menu: Label = menu_acciones.get_node_or_null("VBox/LabelTitulo") as Label
		if lbl_titulo_menu:
			lbl_titulo_menu.text = texto_titulo_acciones
	if panel_recompensas:
		var lbl_titulo_rec: Label = panel_recompensas.get_node_or_null("MarginContainer/VBox/LabelTitulo") as Label
		if lbl_titulo_rec:
			lbl_titulo_rec.text = texto_titulo_recompensas
		if label_recompensas:
			label_recompensas.text = texto_recompensas

## Permite a EncuentroCombate o triggers externos configurar música, fondo, recompensas y textos dinámicamente
func aplicar_configuracion_encuentro(
	musica: AudioStream = null,
	fondo: Texture2D = null,
	texto_rec: String = "",
	exp_rec: int = -1,
	jingle: AudioStream = null,
	txt_inicio: String = "",
	txt_victoria: String = "",
	txt_derrota: String = "",
	txt_huida: String = "",
	txt_titulo_rec: String = ""
) -> void:
	if musica != null:
		musica_combate = musica
	if jingle != null:
		jingle_inicio = jingle
	if fondo != null and nodo_escenario != null:
		var fondo_sprite: Sprite3D = nodo_escenario.get_node_or_null("FondoSprite") as Sprite3D
		if fondo_sprite:
			fondo_sprite.texture = fondo
	if not texto_rec.is_empty():
		texto_recompensas = texto_rec
	if exp_rec >= 0:
		exp_victoria = exp_rec
	if not txt_inicio.is_empty():
		texto_inicio_combate = txt_inicio
	if not txt_victoria.is_empty():
		texto_victoria = txt_victoria
	if not txt_derrota.is_empty():
		texto_derrota = txt_derrota
	if not txt_huida.is_empty():
		texto_huida = txt_huida
	if not txt_titulo_rec.is_empty():
		texto_titulo_recompensas = txt_titulo_rec

	_aplicar_textos_hud()

## Configura la arena instanciando aliados y enemigos.
## Si jugador_mundo se pasa, los battlers con `copiar_sprite_del_jugador` usan su textura actual.
func inicializar(escenas_aliados: Array, escenas_enemigos: Array, jugador_mundo: Node = null) -> void:
	_jugador_mundo_ref = jugador_mundo

	# Limpiar battlers anteriores si los hubiera (evita duplicados)
	for a in aliados:
		if is_instance_valid(a):
			a.queue_free()
	aliados.clear()
	for e in enemigos:
		if is_instance_valid(e):
			e.queue_free()
	enemigos.clear()

	# Instanciar Aliados
	for i in range(escenas_aliados.size()):
		var escena: PackedScene = escenas_aliados[i] as PackedScene
		if escena == null:
			continue
		var battler: Battler = escena.instantiate() as Battler
		contenedor_aliados.add_child(battler)
		battler.inicializar_stats()
		battler.bando = Battler.Bando.ALIADO
		# Sincronizar stats y vida inicial con GameState si es el jugador
		if battler.controlado_por_jugador:
			var gs = _obtener_game_state()
			if gs:
				if gs.stats != null:
					if battler.stats == null:
						battler.stats = BattlerStats.new()
					else:
						battler.stats = battler.stats.duplicate()
					battler.stats.max_hp = gs.stats.max_hp
					battler.stats.ataque = gs.stats.ataque
					battler.stats.defensa = gs.stats.defensa
					battler.stats.velocidad = gs.stats.velocidad
				if not gs.nombre_jugador.is_empty():
					battler.nombre = gs.nombre_jugador
				if gs.hp_actual > 0:
					battler.hp = clamp(gs.hp_actual, 1, battler.stats.max_hp)
				else:
					battler.hp = battler.stats.max_hp
				# Cargar acciones desbloqueadas por NPCs o misiones
				if gs.has_method("tiene_accion") and gs.tiene_accion("barrida_vortice"):
					_asegurar_accion_desbloqueada(battler, "res://scripts/combat/acciones/accion_barrida_vortice.gd")
		if battler.copiar_sprite_del_jugador and jugador_mundo != null:
			battler.copiar_sprite_de(jugador_mundo)
		aliados.append(battler)
		battler.hp_cambiado.connect(_on_battler_hp_cambiado.bind(battler))
		battler.derrotado.connect(_on_battler_derrotado.bind(battler))

	# Instanciar Enemigos
	for i in range(escenas_enemigos.size()):
		var escena: PackedScene = escenas_enemigos[i] as PackedScene
		if escena == null:
			continue
		var battler: Battler = escena.instantiate() as Battler
		contenedor_enemigos.add_child(battler)
		battler.inicializar_stats()
		battler.bando = Battler.Bando.ENEMIGO
		if escenas_enemigos.size() > 1:
			var letra = String.chr(65 + i)
			battler.nombre = "%s %s" % [battler.nombre, letra]
		enemigos.append(battler)
		battler.hp_cambiado.connect(_on_battler_hp_cambiado.bind(battler))
		battler.derrotado.connect(_on_battler_derrotado.bind(battler))

	# Posicionar aliados y enemigos con adaptación de encuadre por proyección de cámara
	_posicionar_combatientes_inicial()
	_ajustar_encuadre_camara_y_combatientes()

	_reconstruir_hud()

func _asegurar_accion_desbloqueada(battler: Battler, ruta_script: String) -> void:
	for a in battler.acciones:
		if a and a.get_script() and a.get_script().resource_path == ruta_script:
			return
	var script_accion = load(ruta_script)
	if script_accion:
		var nueva_accion: BattlerAction = script_accion.new()
		battler.acciones.append(nueva_accion)

func _posicionar_combatientes_inicial() -> void:
	var cant_aliados = aliados.size()
	for i in range(cant_aliados):
		var a = aliados[i]
		var offset_x: float
		if cant_aliados == 1:
			offset_x = -3.0
		else:
			var sep = clampf(2.4 / float(cant_aliados - 1), 0.85, 1.3)
			offset_x = -2.2 - float(i) * sep
		var offset_z: float = float(i) * 0.35
		a.position = Vector3(offset_x, 0.0, offset_z)
		a.posicion_base = a.global_position if a.is_inside_tree() else a.position
		a.mirar_al_frente()

	var cant_enemigos = enemigos.size()
	for i in range(cant_enemigos):
		var e = enemigos[i]
		var offset_x: float
		if cant_enemigos == 1:
			offset_x = 3.0
		else:
			var sep = clampf(2.2 / float(cant_enemigos - 1), 0.85, 1.25)
			offset_x = 2.4 + float(i) * sep
		var offset_z: float = float(i) * 0.35
		e.position = Vector3(offset_x, 0.0, offset_z)
		e.posicion_base = e.global_position if e.is_inside_tree() else e.position
		e.mirar_al_frente()

## Proyecta un punto 3D del mundo a coordenadas 2D en pantalla basándose en la cámara y resolución
func proyectar_posicion_pantalla(pos_3d: Vector3, tam_pantalla: Vector2) -> Vector2:
	if camara == null:
		return tam_pantalla * 0.5
	
	# Si unproject_position está disponible en el entorno y da coordenadas válidas, usarlo
	if camara.is_inside_tree():
		var p_unproj: Vector2 = camara.unproject_position(pos_3d)
		if p_unproj.length_squared() > 1.0:
			return p_unproj
	
	# Cálculo analítico directo de perspectiva (consistente en cualquier resolución, aspecto y modo headless)
	var cam_xform: Transform3D = camara.global_transform if camara.is_inside_tree() else camara.transform
	if absf(cam_xform.basis.determinant()) < 0.0001:
		return tam_pantalla * 0.5
	var p_cam: Vector3 = cam_xform.affine_inverse() * pos_3d
	var dist_z: float = -p_cam.z
	if dist_z <= 0.05:
		return Vector2(-9999.0, -9999.0)
	
	var fov_rad: float = deg_to_rad(camara.fov)
	var h_half: float = dist_z * tan(fov_rad * 0.5)
	var aspect: float = tam_pantalla.x / maxf(1.0, tam_pantalla.y)
	var w_half: float = h_half * aspect
	
	var ndc_x: float = p_cam.x / w_half
	var ndc_y: float = -p_cam.y / h_half
	
	return Vector2(
		(ndc_x * 0.5 + 0.5) * tam_pantalla.x,
		(ndc_y * 0.5 + 0.5) * tam_pantalla.y
	)

## Comprueba mediante proyección 3D a 2D en pantalla que todos los combatientes (aliados y enemigos)
## quepan dentro de los márgenes visibles de la resolución de la cámara, ajustando su espaciado y/o alejando la cámara.
func _ajustar_encuadre_camara_y_combatientes() -> void:
	if camara == null:
		return
	
	var vp := get_viewport()
	var tam_pantalla: Vector2 = vp.get_visible_rect().size if vp else Vector2(1152, 648)
	if tam_pantalla.x <= 10.0 or tam_pantalla.y <= 10.0:
		tam_pantalla = Vector2(1152, 648)
	
	# Márgenes de seguridad dentro de la resolución de pantalla (6% a 90%)
	var margen_izq: float = tam_pantalla.x * 0.06
	var margen_der: float = tam_pantalla.x * 0.90
	var margen_arr: float = tam_pantalla.y * 0.07
	var margen_aba: float = tam_pantalla.y * 0.91
	
	var todos: Array[Battler] = []
	todos.append_array(aliados)
	todos.append_array(enemigos)
	
	for iteracion in range(8):
		var fuera_derecha: float = 0.0
		var fuera_izquierda: float = 0.0
		var fuera_arriba: float = 0.0
		var fuera_abajo: float = 0.0
		
		for b in todos:
			if not is_instance_valid(b):
				continue
			var pos_b: Vector3 = b.global_position if b.is_inside_tree() else b.position
			var r: float = b.radio if "radio" in b else 0.6
			var h: float = b.altura if "altura" in b else 1.4
			
			var puntos: Array[Vector3] = [
				pos_b,
				pos_b + Vector3(-r * 1.1, 0.0, 0.0),
				pos_b + Vector3(r * 1.1, 0.0, 0.0),
				pos_b + Vector3(0.0, h * 1.1, 0.0),
			]
			
			for pt in puntos:
				var p2d: Vector2 = proyectar_posicion_pantalla(pt, tam_pantalla)
				if p2d.x < -9000.0:
					fuera_derecha = maxf(fuera_derecha, 50.0)
					continue
				if p2d.x > margen_der:
					fuera_derecha = maxf(fuera_derecha, p2d.x - margen_der)
				if p2d.x < margen_izq:
					fuera_izquierda = maxf(fuera_izquierda, margen_izq - p2d.x)
				if p2d.y < margen_arr:
					fuera_arriba = maxf(fuera_arriba, margen_arr - p2d.y)
				if p2d.y > margen_aba:
					fuera_abajo = maxf(fuera_abajo, p2d.y - margen_aba)
		
		if fuera_derecha <= 1.0 and fuera_izquierda <= 1.0 and fuera_arriba <= 1.0 and fuera_abajo <= 1.0:
			break
		
		if fuera_derecha > 1.0:
			for e in enemigos:
				if is_instance_valid(e):
					e.position.x = maxf(1.5, e.position.x - 0.2)
			camara.position += camara.transform.basis.z * 0.35
		
		if fuera_izquierda > 1.0:
			for a in aliados:
				if is_instance_valid(a):
					a.position.x = minf(-1.5, a.position.x + 0.2)
			camara.position += camara.transform.basis.z * 0.35
		
		if fuera_arriba > 1.0:
			camara.position += camara.transform.basis.z * 0.25 + Vector3.UP * 0.15
		
		if fuera_abajo > 1.0:
			camara.position += camara.transform.basis.z * 0.25 - Vector3.UP * 0.1

	# Asegurar que el suelo y el fondo se extiendan lo suficiente cuando se aleja o escala la cámara
	# para evitar que se vea como una plataforma flotante en el vacío.
	if nodo_escenario:
		var dist_extra: float = maxf(0.0, camara.position.z - 6.47)
		var suelo = nodo_escenario.get_node_or_null("PlataformaSuelo") as Node3D
		if suelo and is_instance_valid(suelo):
			var escala_suelo: float = 1.0 + dist_extra * 0.3
			suelo.scale = Vector3(escala_suelo, 1.0, escala_suelo)
		var fondo = nodo_escenario.get_node_or_null("FondoSprite") as Node3D
		if fondo and is_instance_valid(fondo):
			var escala_fondo: float = 3.8 * (1.0 + dist_extra * 0.2)
			fondo.scale = Vector3(escala_fondo, escala_fondo, 3.8)
			fondo.position.y = 4.2 + dist_extra * 0.12

	for b in todos:
		if is_instance_valid(b):
			b.posicion_base = b.global_position if b.is_inside_tree() else b.position
	_cam_pos_original = camara.transform.origin

## Arranca el combate y comienza el bucle de turnos
func comenzar_combate() -> void:
	if camara:
		camara.make_current()
	if jingle_inicio and not _jingle_reproducido:
		reproducir_sonido(jingle_inicio)
		_jingle_reproducido = true
	if musica_combate:
		reproductor_musica.stream = musica_combate
		reproductor_musica.play()

	await mostrar_mensaje(texto_inicio_combate, 1.0)
	_bucle_de_turnos()

# ---------------------------------------------------------------------------
# Bucle principal de turnos (estilo Open-RPG + Paper Mario)
# ---------------------------------------------------------------------------

func _bucle_de_turnos() -> void:
	while true:
		# Comprobar condiciones de fin
		if _todos_muertos(enemigos):
			await _finalizar_victoria()
			return
		if _todos_muertos(aliados):
			await _finalizar_derrota()
			return

		# Ordenar combatientes vivos por velocidad descendente
		todos_los_battlers.clear()
		for a in aliados:
			if a.esta_vivo():
				todos_los_battlers.append(a)
		for e in enemigos:
			if e.esta_vivo():
				todos_los_battlers.append(e)

		todos_los_battlers.sort_custom(func(a: Battler, b: Battler) -> bool:
			return a.stats.velocidad > b.stats.velocidad
		)

		for battler in todos_los_battlers:
			if not battler.esta_vivo():
				continue
			if _todos_muertos(enemigos) or _todos_muertos(aliados):
				break

			_battler_actual = battler

			if battler.controlado_por_jugador:
				var resuelto_exitoso: bool = await _procesar_turno_jugador(battler)
				if not resuelto_exitoso:
					# Si eligió huir o terminó por otra vía
					return
			else:
				await _procesar_turno_ia(battler)

			await esperar(0.3)

# ---------------------------------------------------------------------------
# Turno del Jugador
# ---------------------------------------------------------------------------

func _procesar_turno_jugador(battler: Battler) -> bool:
	_estado = EstadoTurno.TURNO_JUGADOR
	await mostrar_mensaje(formato_texto_turno % battler.nombre, 0.7)

	# Preparar menú de acciones
	_crear_botones_acciones(battler)
	menu_acciones.show()

	# Esperar a que el jugador tome una decisión (señal o await)
	var decision_tomada: bool = false
	while not decision_tomada:
		var accion_o_huida = await _esperar_seleccion_menu()
		if accion_o_huida is String and accion_o_huida == "huir":
			menu_acciones.hide()
			await _intentar_huida()
			return false
		elif accion_o_huida is BattlerAction:
			_accion_seleccionada = accion_o_huida
			if _accion_seleccionada.requiere_elegir_objetivo():
				menu_acciones.hide()
				var objetivo: Battler = await _elegir_objetivo(_accion_seleccionada)
				if objetivo == null:
					# Canceló la selección de objetivo: vuelve al menú de acciones
					_estado = EstadoTurno.TURNO_JUGADOR
					menu_acciones.show()
					_actualizar_resaltado_menu()
					continue
				else:
					decision_tomada = true
					_estado = EstadoTurno.ACCION_EN_CURSO
					await _accion_seleccionada.ejecutar(battler, [objetivo], self)
			else:
				decision_tomada = true
				menu_acciones.hide()
				_estado = EstadoTurno.ACCION_EN_CURSO
				var objs: Array[Battler] = []
				if _accion_seleccionada.objetivo == BattlerAction.Objetivo.TODOS_ENEMIGOS:
					for e in enemigos:
						if e.esta_vivo():
							objs.append(e)
				else:
					objs = [battler]
				await _accion_seleccionada.ejecutar(battler, objs, self)

	_estado = EstadoTurno.ESPERANDO
	return true

func _crear_botones_acciones(battler: Battler) -> void:
	for c in lista_botones.get_children():
		lista_botones.remove_child(c)
		c.queue_free()

	_opciones_menu.clear()
	_botones_menu.clear()

	# Acciones de combate del battler
	for accion in battler.acciones:
		_opciones_menu.append(accion)

	# Opción Huir (requisito A3)
	_opciones_menu.append("huir")

	for i in range(_opciones_menu.size()):
		var btn: Button = Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		
		# Conectar eventos de ratón
		var idx: int = i
		btn.mouse_entered.connect(func(): _seleccionar_indice_menu(idx, false))
		btn.pressed.connect(func(): _confirmar_opcion_menu(idx))
		
		lista_botones.add_child(btn)
		_botones_menu.append(btn)

	_indice_menu_accion = 0
	_actualizar_resaltado_menu()

func _seleccionar_indice_menu(nuevo_indice: int, reproducir_sfx: bool = true) -> void:
	if _botones_menu.is_empty():
		return
	var idx_valido: int = clampi(nuevo_indice, 0, _botones_menu.size() - 1)
	if _indice_menu_accion != idx_valido and reproducir_sfx:
		reproducir_sonido(sonido_cursor)
	_indice_menu_accion = idx_valido
	_actualizar_resaltado_menu()

func _actualizar_resaltado_menu() -> void:
	for i in range(_botones_menu.size()):
		var btn: Button = _botones_menu[i]
		var opcion = _opciones_menu[i]
		var nombre_base: String = opcion.nombre if opcion is BattlerAction else texto_opcion_huir
		if i == _indice_menu_accion:
			btn.text = "▶  " + nombre_base
			btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			if opcion is BattlerAction:
				desc_accion_label.text = opcion.descripcion
			else:
				desc_accion_label.text = texto_descripcion_huir
		else:
			btn.text = "    " + nombre_base
			btn.remove_theme_color_override("font_color")

func _confirmar_opcion_menu(indice: int) -> void:
	if _seleccion_menu_resultado != null:
		return
	if indice >= 0 and indice < _opciones_menu.size():
		reproducir_sonido(sonido_cursor)
		_seleccion_menu_resultado = _opciones_menu[indice]

func _esperar_seleccion_menu():
	_seleccion_menu_resultado = null
	while _seleccion_menu_resultado == null:
		await get_tree().process_frame
	var res = _seleccion_menu_resultado
	_seleccion_menu_resultado = null
	return res

# ---------------------------------------------------------------------------
# Selección de Objetivo
# ---------------------------------------------------------------------------

var _seleccion_objetivo_terminada: bool = false
var _objetivo_elegido: Battler = null

func _elegir_objetivo(accion: BattlerAction) -> Battler:
	_estado = EstadoTurno.SELECCIONANDO_OBJETIVO
	_objetivos_validos.clear()

	var grupo: Array[Battler] = enemigos if accion.objetivo == BattlerAction.Objetivo.ENEMIGO else aliados
	for b in grupo:
		if b.esta_vivo():
			_objetivos_validos.append(b)

	if _objetivos_validos.is_empty():
		return null

	_indice_objetivo = 0
	selector_objetivo.show()
	_actualizar_posicion_selector()

	_seleccion_objetivo_terminada = false
	_objetivo_elegido = null

	while not _seleccion_objetivo_terminada:
		await get_tree().process_frame

	selector_objetivo.hide()
	return _objetivo_elegido

var _ultimo_tiempo_stick_v: int = 0
var _ultimo_tiempo_stick_h: int = 0
var _stick_v_activo: bool = false
var _stick_h_activo: bool = false


const RETARDO_INICIAL_STICK_MS: int = 280
const REPETICION_STICK_MS: int = 180
const UMBRAL_ACTIVACION_STICK: float = 0.45
const UMBRAL_RETORNO_STICK: float = 0.25

## Evalúa si un evento vertical del stick o entrada debe avanzar un paso en el menú
func _debe_procesar_paso_menu_v(event: InputEvent) -> bool:
	if event.is_echo():
		return false
	
	if event is InputEventJoypadMotion:
		if event.axis != JOY_AXIS_LEFT_Y:
			return false
		var axis_val := absf(event.axis_value)
		if axis_val < UMBRAL_ACTIVACION_STICK:
			return false
		
		var ahora := Time.get_ticks_msec()
		if not _stick_v_activo:
			_stick_v_activo = true
			_ultimo_tiempo_stick_v = ahora
			return true
		else:
			if ahora - _ultimo_tiempo_stick_v >= RETARDO_INICIAL_STICK_MS:
				_ultimo_tiempo_stick_v = ahora - (RETARDO_INICIAL_STICK_MS - REPETICION_STICK_MS)
				return true
			return false
	
	return true

## Evalúa si un evento horizontal del stick o entrada debe avanzar un paso
func _debe_procesar_paso_menu_h(event: InputEvent) -> bool:
	if event.is_echo():
		return false
	
	if event is InputEventJoypadMotion:
		if event.axis != JOY_AXIS_LEFT_X:
			return false
		var axis_val := absf(event.axis_value)
		if axis_val < UMBRAL_ACTIVACION_STICK:
			return false
		
		var ahora := Time.get_ticks_msec()
		if not _stick_h_activo:
			_stick_h_activo = true
			_ultimo_tiempo_stick_h = ahora
			return true
		else:
			if ahora - _ultimo_tiempo_stick_h >= RETARDO_INICIAL_STICK_MS:
				_ultimo_tiempo_stick_h = ahora - (RETARDO_INICIAL_STICK_MS - REPETICION_STICK_MS)
				return true
	return true

## Compatibilidad: redirige al filtro vertical por defecto
func _debe_procesar_paso_menu(event: InputEvent) -> bool:
	return _debe_procesar_paso_menu_v(event)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion:
		if event.axis == JOY_AXIS_LEFT_Y and absf(event.axis_value) < UMBRAL_RETORNO_STICK:
			_stick_v_activo = false
		elif event.axis == JOY_AXIS_LEFT_X and absf(event.axis_value) < UMBRAL_RETORNO_STICK:
			_stick_h_activo = false

	if _estado == EstadoTurno.TURNO_JUGADOR:
		if _botones_menu.is_empty():
			return

		# Navegación vertical: ui_up/ui_down o move_up/move_down (flechas, WASD, stick, d-pad)
		if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
			if not _debe_procesar_paso_menu_v(event):
				return
			get_viewport().set_input_as_handled()
			var nuevo: int = (_indice_menu_accion - 1 + _botones_menu.size()) % _botones_menu.size()
			_seleccionar_indice_menu(nuevo, true)

		elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
			if not _debe_procesar_paso_menu_v(event):
				return
			get_viewport().set_input_as_handled()
			var nuevo: int = (_indice_menu_accion + 1) % _botones_menu.size()
			_seleccionar_indice_menu(nuevo, true)

		# Confirmar: ui_accept o interact (Z, E, Enter, Espacio, Gamepad A)
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			if event.is_echo():
				return
			get_viewport().set_input_as_handled()
			_confirmar_opcion_menu(_indice_menu_accion)

	elif _estado == EstadoTurno.SELECCIONANDO_OBJETIVO:
		# Navegación entre objetivos: flechas, WASD, stick, d-pad
		if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
			if not _debe_procesar_paso_menu_h(event):
				return
			get_viewport().set_input_as_handled()
			_cambiar_objetivo(-1)

		elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
			if not _debe_procesar_paso_menu_h(event):
				return
			get_viewport().set_input_as_handled()
			_cambiar_objetivo(1)

		elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
			if not _debe_procesar_paso_menu_v(event):
				return
			get_viewport().set_input_as_handled()
			_cambiar_objetivo(-1)

		elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
			if not _debe_procesar_paso_menu_v(event):
				return
			get_viewport().set_input_as_handled()
			_cambiar_objetivo(1)

		# Confirmar objetivo: ui_accept o interact (Z, E, Enter, Espacio, Gamepad A)
		elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
			if event.is_echo():
				return
			get_viewport().set_input_as_handled()
			reproducir_sonido(sonido_cursor)
			_objetivo_elegido = _objetivos_validos[_indice_objetivo]
			_seleccion_objetivo_terminada = true

		elif event.is_action_pressed("ui_cancel"):
			if event.is_echo():
				return
			get_viewport().set_input_as_handled()
			_objetivo_elegido = null
			_seleccion_objetivo_terminada = true

func _cambiar_objetivo(direccion: int) -> void:
	if _objetivos_validos.is_empty():
		return
	_indice_objetivo = (_indice_objetivo + direccion) % _objetivos_validos.size()
	if _indice_objetivo < 0:
		_indice_objetivo = _objetivos_validos.size() - 1
	reproducir_sonido(sonido_cursor)
	_actualizar_posicion_selector()

func _actualizar_posicion_selector() -> void:
	if _indice_objetivo < 0 or _indice_objetivo >= _objetivos_validos.size():
		return
	var b: Battler = _objetivos_validos[_indice_objetivo]
	var pos_cabeza: Vector3 = b.punto_cabeza() + Vector3.UP * 0.4
	var pantalla: Vector2 = a_pantalla(pos_cabeza)
	selector_objetivo.position = pantalla - selector_objetivo.size * 0.5

# ---------------------------------------------------------------------------
# Turno de la IA (Enemigo)
# ---------------------------------------------------------------------------

func _procesar_turno_ia(battler: Battler) -> void:
	_estado = EstadoTurno.ACCION_EN_CURSO
	await mostrar_mensaje("Turno de %s" % battler.nombre, 0.7)

	# Elegir una acción de sus acciones disponibles
	if battler.acciones.is_empty():
		await esperar(0.5)
		return

	var accion: BattlerAction = battler.acciones[randi() % battler.acciones.size()]

	# Elegir un objetivo vivo del bando contrario
	var candidatos: Array[Battler] = []
	for a in aliados:
		if a.esta_vivo():
			candidatos.append(a)

	if candidatos.is_empty():
		return

	var objetivo: Battler = candidatos[randi() % candidatos.size()]
	await accion.ejecutar(battler, [objetivo], self)

# ---------------------------------------------------------------------------
# Huida y Resoluciones
# ---------------------------------------------------------------------------

func _intentar_huida() -> void:
	_estado = EstadoTurno.TERMINADO
	_sincronizar_estado_global()
	reproducir_sonido(sonido_huida)
	await mostrar_mensaje(texto_huida, 1.2)
	combate_terminado.emit(ResultadoCombate.HUIDA)

func _finalizar_victoria() -> void:
	_estado = EstadoTurno.TERMINADO
	_sincronizar_estado_global()
	var gs = _obtener_game_state()
	if gs and exp_victoria > 0:
		gs.agregar_exp(exp_victoria)
	reproductor_musica.stop()
	reproducir_sonido(sonido_victoria)
	await mostrar_mensaje(texto_victoria, 1.0)
	
	# Mostrar recompensas configuradas
	_aplicar_textos_hud()
	panel_recompensas.show()
	await esperar(2.0)
	combate_terminado.emit(ResultadoCombate.VICTORIA)

func _finalizar_derrota() -> void:
	_estado = EstadoTurno.TERMINADO
	_sincronizar_estado_global()
	reproductor_musica.stop()
	reproducir_sonido(sonido_derrota)
	await mostrar_mensaje(texto_derrota, 1.5)
	combate_terminado.emit(ResultadoCombate.DERROTA)

# ---------------------------------------------------------------------------
# Utilidades para las acciones
# ---------------------------------------------------------------------------

## Convierte una coordenada 3D del mundo en píxeles 2D de la pantalla
func a_pantalla(pos_3d: Vector3) -> Vector2:
	var vp := get_viewport()
	var tam_pantalla: Vector2 = vp.get_visible_rect().size if vp else Vector2(1152, 648)
	if tam_pantalla.x <= 10.0 or tam_pantalla.y <= 10.0:
		tam_pantalla = Vector2(1152, 648)
	return proyectar_posicion_pantalla(pos_3d, tam_pantalla)

func esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout

func reproducir_sonido(stream: AudioStream) -> void:
	if stream == null or not is_inside_tree():
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

## Muestra un número flotante de daño o curación
func mostrar_numero(battler: Battler, cantidad: int, critico: bool = false) -> void:
	if contenedor_danio == null:
		contenedor_danio = get_node_or_null("UICanvas/ContenedorDanio")
	if contenedor_danio == null or battler == null:
		return

	var label: Label = Label.new()
	label.text = str(cantidad)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30 if critico else 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if critico else Color(1.0, 0.35, 0.35))
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)

	contenedor_danio.add_child(label)
	var pos: Vector2 = a_pantalla(battler.punto_cabeza() + Vector3.UP * 0.2)
	label.position = pos - Vector2(30, 15)

	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", pos.y - 45.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.2)
	tween.tween_callback(label.queue_free)

## Muestra un texto flotante encima del combatiente (e.g. "¡Esquivado!")
func mostrar_texto(battler: Battler, texto: String, color: Color = Color.WHITE) -> void:
	if contenedor_danio == null:
		contenedor_danio = get_node_or_null("UICanvas/ContenedorDanio")
	if contenedor_danio == null or battler == null:
		return

	var label: Label = Label.new()
	label.text = texto
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)

	contenedor_danio.add_child(label)
	var pos: Vector2 = a_pantalla(battler.punto_cabeza() + Vector3.UP * 0.3)
	label.position = pos - Vector2(60, 15)

	var tween: Tween = label.create_tween()
	tween.tween_property(label, "position:y", pos.y - 40.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.3)
	tween.tween_callback(label.queue_free)

## Muestra un cartel / mensaje temporal en el centro de la pantalla
func mostrar_mensaje(texto: String, duracion: float = 1.0) -> void:
	banner_turno.text = texto
	banner_turno.show()
	banner_turno.modulate.a = 0.0
	var tween: Tween = banner_turno.create_tween()
	tween.tween_property(banner_turno, "modulate:a", 1.0, 0.2)
	tween.tween_interval(duracion)
	tween.tween_property(banner_turno, "modulate:a", 0.0, 0.2)
	await tween.finished
	banner_turno.hide()

## Sacudida de cámara ante impactos
func sacudir_camara(intensidad: float = 0.15) -> void:
	if not camara:
		return
	var tween: Tween = camara.create_tween()
	for i in range(5):
		var offset: Vector3 = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0.0).normalized() * intensidad
		tween.tween_property(camara, "transform:origin", _cam_pos_original + offset, 0.03)
	tween.tween_property(camara, "transform:origin", _cam_pos_original, 0.04)

# ---------------------------------------------------------------------------
# Gestión de HUD y Eventos
# ---------------------------------------------------------------------------

func _reconstruir_hud() -> void:
	if hud_aliados == null:
		hud_aliados = get_node_or_null("UICanvas/HUD/Aliados")
	if hud_enemigos == null:
		hud_enemigos = get_node_or_null("UICanvas/HUD/Enemigos")
	if hud_aliados == null or hud_enemigos == null:
		return

	_paneles_hud.clear()
	for c in hud_aliados.get_children():
		c.queue_free()
	for c in hud_enemigos.get_children():
		c.queue_free()

	for a in aliados:
		var panel: Control = _crear_panel_hud(a, Color(0.2, 0.7, 1.0))
		hud_aliados.add_child(panel)

	for e in enemigos:
		var panel: Control = _crear_panel_hud(e, Color(1.0, 0.35, 0.35))
		hud_enemigos.add_child(panel)

func _crear_panel_hud(battler: Battler, color_borde: Color) -> Control:
	var contenedor: PanelContainer = PanelContainer.new()
	contenedor.name = "HUD_" + str(battler.get_instance_id())
	var vbox: VBoxContainer = VBoxContainer.new()
	contenedor.add_child(vbox)

	var lbl_nombre: Label = Label.new()
	lbl_nombre.text = battler.nombre
	lbl_nombre.add_theme_font_size_override("font_size", 16)
	lbl_nombre.add_theme_color_override("font_color", color_borde)
	vbox.add_child(lbl_nombre)

	var pbar: ProgressBar = ProgressBar.new()
	pbar.name = "BarraHP"
	pbar.min_value = 0
	pbar.max_value = battler.stats.max_hp
	pbar.value = battler.hp
	pbar.custom_minimum_size = Vector2(160, 16)
	pbar.show_percentage = false

	# Fondo oscuro con borde sutil
	var bg_box: StyleBoxFlat = StyleBoxFlat.new()
	bg_box.bg_color = Color(0.08, 0.1, 0.14, 0.95)
	bg_box.border_width_left = 1
	bg_box.border_width_top = 1
	bg_box.border_width_right = 1
	bg_box.border_width_bottom = 1
	bg_box.border_color = Color(0.3, 0.35, 0.45, 0.8)
	bg_box.corner_radius_top_left = 4
	bg_box.corner_radius_top_right = 4
	bg_box.corner_radius_bottom_right = 4
	bg_box.corner_radius_bottom_left = 4
	pbar.add_theme_stylebox_override("background", bg_box)

	# Relleno verde para aliados, rojo para enemigos
	var fill_box: StyleBoxFlat = StyleBoxFlat.new()
	fill_box.bg_color = Color(0.2, 0.85, 0.35) if battler.bando == Battler.Bando.ALIADO else Color(0.95, 0.3, 0.3)
	fill_box.corner_radius_top_left = 3
	fill_box.corner_radius_top_right = 3
	fill_box.corner_radius_bottom_right = 3
	fill_box.corner_radius_bottom_left = 3
	pbar.add_theme_stylebox_override("fill", fill_box)
	vbox.add_child(pbar)

	var lbl_hp: Label = Label.new()
	lbl_hp.name = "TextoHP"
	lbl_hp.text = formato_hp % [battler.hp, battler.stats.max_hp]
	lbl_hp.add_theme_font_size_override("font_size", 13)
	vbox.add_child(lbl_hp)

	_paneles_hud[battler] = {
		"pbar": pbar,
		"lbl": lbl_hp,
		"panel": contenedor
	}

	return contenedor

func _on_battler_hp_cambiado(hp_actual: int, max_hp: int, battler: Battler) -> void:
	var hud_data = _paneles_hud.get(battler)
	if hud_data == null:
		var id: String = "HUD_" + str(battler.get_instance_id())
		var hud_item = hud_aliados.get_node_or_null(id)
		if hud_item == null:
			hud_item = hud_enemigos.get_node_or_null(id)
		if hud_item:
			hud_data = {
				"pbar": hud_item.find_child("BarraHP") as ProgressBar,
				"lbl": hud_item.find_child("TextoHP") as Label
			}
	if hud_data:
		var pbar: ProgressBar = hud_data.get("pbar")
		var lbl: Label = hud_data.get("lbl")
		if pbar:
			pbar.max_value = max_hp
			var tween: Tween = create_tween()
			tween.tween_property(pbar, "value", float(hp_actual), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if lbl:
			lbl.text = formato_hp % [hp_actual, max_hp]

func _on_battler_derrotado(battler: Battler) -> void:
	var hud_data = _paneles_hud.get(battler)
	if hud_data:
		var pbar: ProgressBar = hud_data.get("pbar")
		var lbl: Label = hud_data.get("lbl")
		if pbar:
			pbar.value = 0
		if lbl:
			lbl.text = formato_hp % [0, battler.stats.max_hp]
			lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	await battler.animar_derrota()

func _todos_muertos(grupo: Array[Battler]) -> bool:
	for b in grupo:
		if b.esta_vivo():
			return false
	return true

func _sincronizar_estado_global() -> void:
	var gs = _obtener_game_state()
	if gs == null:
		return
	for a in aliados:
		if is_instance_valid(a) and a.controlado_por_jugador:
			gs.actualizar_hp(a.hp)
			break

func _obtener_game_state():
	var gs_script = load("res://scripts/core/game_state.gd")
	if gs_script and "instancia" in gs_script and gs_script.instancia != null:
		return gs_script.instancia
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	var root_node: Node = null
	if is_inside_tree() and get_tree():
		root_node = get_tree().root
	elif Engine.get_main_loop() and "root" in Engine.get_main_loop():
		root_node = Engine.get_main_loop().root
	if root_node and root_node.has_node("GameState"):
		return root_node.get_node("GameState")
	var p = get_parent()
	while p != null:
		if p.has_node("GameState"):
			return p.get_node("GameState")
		if p.get_parent() == null:
			if p.name == "GameState":
				return p
			break
		p = p.get_parent()
	return null
