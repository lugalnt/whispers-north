class_name EncuentroCombate
extends Node

## Nodo modular y reutilizable para disparar encuentros de combate RPG estilo Paper Mario.
##
## Puede añadirse como hijo a cualquier entidad del mundo (jarrón, cofre, enemigo, NPC o Area3D).
## Es totalmente configurable desde el Inspector visual de Godot:
##   - Enemigos y aliados (Array de PackedScene).
##   - Música y fondo personalizados por encuentro.
##   - Recompensas (EXP y texto multilínea).
##   - Colores y tiempos de transición.
##   - Activación/desactivación dinámica con un solo clic.

signal combate_iniciado()
signal combate_terminado(resultado: CombatArena.ResultadoCombate)
signal victoria()
signal derrota()
signal huida()

const CombatArenaScript = preload("res://scripts/combat/combat_arena.gd")
const ArenaDefaultScene = preload("res://scenes/combat/CombatArena.tscn")
const JugadorBattlerScene = preload("res://scenes/combat/battlers/PlayerBattler.tscn")
const PotBattlerScene = preload("res://scenes/combat/battlers/PotBattler.tscn")

@export_group("Estado del Encuentro")
## Si es false, el encuentro está inactivo y no se disparará el combate.
@export var activo: bool = true

@export_group("Combatientes")
## Lista de escenas de battlers enemigos a instanciar en este combate.
@export var enemigos: Array[PackedScene] = [PotBattlerScene]
## Lista de escenas de battlers aliados (por defecto el jugador).
@export var aliados: Array[PackedScene] = [JugadorBattlerScene]

@export_group("Personalización de Arena")
## Escena de la arena de combate a instanciar.
@export var escena_arena: PackedScene = ArenaDefaultScene
## Música de combate temática para este encuentro específico (opcional).
@export var musica_combate: AudioStream
## Textura de fondo (2D/3D) para el escenario de la arena (opcional).
@export var textura_fondo: Texture2D
## Altura Y a la que se instancia la arena en el mundo para aislarla del terreno.
@export var altura_aislamiento: float = 200.0

@export_group("Recompensas")
## Puntos de experiencia otorgados al vencer.
@export var exp_recompensa: int = 20
## Texto multilínea que se muestra en el panel de victoria.
@export_multiline var texto_recompensas: String = "¡Ganaste el combate!\n\n+20 EXP\nObtuviste: [Fragmento de Cerámica Antiguo]"
## Ítems garantizados otorgados al jugador al salir victorioso.
@export var items_garantizados: Array[InventoryItem] = []
## Tabla de botín aleatoria opcional que suelta un ítem según probabilidades.
@export var pool_recompensas: ItemPool = null
## Probabilidad de que la pool de recompensas suelte un objeto (0.0 = nunca, 1.0 = siempre).
@export_range(0.0, 1.0, 0.05) var probabilidad_pool: float = 0.5

@export_group("Efecto de Inicio (Flash y Jingle)")
## Si está activo, produce un destello (flash) en pantalla al comenzar el combate.
@export var flash_activo: bool = true
## Color del destello en pantalla (por defecto blanco brillante).
@export var color_flash: Color = Color.WHITE
## Número de parpadeos en el destello inicial.
@export var cantidad_flashes: int = 2
## Duración en segundos de cada parpadeo del destello.
@export var duracion_flash: float = 0.07
## Jingle o fanfarria sonora de inicio de combate. Si se deja en null, hereda el jingle asignado visualmente en el nodo principal de CombatArena.
@export var jingle_inicio: AudioStream = null

@export_group("Textos del Encuentro (HUD)")
## Mensaje al arrancar la batalla en el banner superior (dejar vacío para usar el de la arena).
@export var texto_inicio_combate: String = ""
## Mensaje mostrado al ganar la batalla (dejar vacío para usar el de la arena).
@export var texto_victoria: String = ""
## Mensaje mostrado al caer derrotado (dejar vacío para usar el de la arena).
@export var texto_derrota: String = ""
## Mensaje mostrado al huir de la batalla (dejar vacío para usar el de la arena).
@export var texto_huida: String = ""
## Título del banner de recompensas (dejar vacío para usar el de la arena).
@export var texto_titulo_recompensas: String = ""

@export_group("Transición")
## Color del fundido al entrar al combate.
@export var color_fundido_entrada: Color = Color.WHITE
## Duración en segundos de la cortina al entrar.
@export var duracion_fundido_entrada: float = 0.16
## Color del fundido al salir del combate.
@export var color_fundido_salida: Color = Color.BLACK
## Duración en segundos de la cortina al salir.
@export var duracion_fundido_salida: float = 0.22

@export_group("Disparador Automático (Opcional)")
## Si es true y el nodo padre es un Area3D, inicia el combate cuando el jugador entre al área.
@export var auto_iniciar_en_area: bool = false
## Si es true, destruye automáticamente el nodo padre (queue_free) tras la victoria.
@export var auto_eliminar_padre_en_victoria: bool = false

var _combate_en_curso: bool = false

func _ready() -> void:
	if auto_iniciar_en_area:
		var padre: Node = get_parent()
		if padre is Area3D:
			(padre as Area3D).body_entered.connect(_on_parent_area_body_entered)

func _on_parent_area_body_entered(body: Node3D) -> void:
	if not activo or _combate_en_curso:
		return
	if body.is_in_group("player") or "is_interacting" in body:
		iniciar_combate(body as CharacterBody3D, get_parent())

## Inicia el flujo completo del encuentro de combate:
## 1. Congela al jugador y guarda la cámara del supramundo.
## 2. Prepara la arena para heredar configuraciones visuales (jingle, fondo, textos).
## 3. Ejecuta el jingle y el destello (flash) de transición.
## 4. Oculta el nodo de la entidad en el mundo mientras dura la batalla.
## 5. Revela la arena configurada y ejecuta el combate.
## 6. Al finalizar, restaura cámaras, visibilidad y emite señales.
func iniciar_combate(jugador: CharacterBody3D = null, nodo_a_ocultar: Node = null) -> CombatArena.ResultadoCombate:
	if not activo or _combate_en_curso:
		return CombatArena.ResultadoCombate.HUIDA

	_combate_en_curso = true

	if jugador == null:
		jugador = _obtener_jugador()

	# Bloquear movimiento del jugador en el supramundo
	_bloquear_jugador(jugador, true)

	# Guardar la cámara activa del mundo para restaurarla al terminar
	var cam_mundo: Camera3D = get_viewport().get_camera_3d()

	# Instanciar anticipadamente la arena para leer o sobreescribir propiedades visuales
	var escena_a_usar: PackedScene = escena_arena if escena_arena else ArenaDefaultScene
	var arena: CombatArena = escena_a_usar.instantiate() as CombatArena
	arena.auto_iniciar_si_esta_vacio = false
	get_tree().current_scene.add_child(arena)
	arena.global_position = Vector3(0.0, altura_aislamiento, 0.0)

	# Determinar jingle: usar el del encuentro si se definió, sino el del nodo principal de CombatArena
	var jingle_a_usar: AudioStream = jingle_inicio
	if jingle_a_usar == null and arena.jingle_inicio != null:
		jingle_a_usar = arena.jingle_inicio

	# 1. Reproducir jingle de inicio de combate al arrancar la transición
	if jingle_a_usar != null:
		_reproducir_audio(jingle_a_usar)
		arena._jingle_reproducido = true

	# 2. Transición de entrada: destellos (flash) seguidos de cortina
	var canvas_transicion: CanvasLayer = CanvasLayer.new()
	canvas_transicion.layer = 105
	var fade_rect: ColorRect = ColorRect.new()
	fade_rect.color = color_flash if flash_activo else color_fundido_entrada
	fade_rect.modulate.a = 0.0
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_transicion.add_child(fade_rect)
	get_tree().root.add_child(canvas_transicion)

	if flash_activo and cantidad_flashes > 0:
		var tween_flash: Tween = create_tween()
		for i in range(cantidad_flashes):
			tween_flash.tween_property(fade_rect, "modulate:a", 1.0, duracion_flash).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			if i < cantidad_flashes - 1:
				tween_flash.tween_property(fade_rect, "modulate:a", 0.0, duracion_flash * 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tween_flash.finished
		fade_rect.color = color_fundido_entrada
	else:
		var tween_in: Tween = create_tween()
		tween_in.tween_property(fade_rect, "modulate:a", 1.0, duracion_fundido_entrada)
		await tween_in.finished

	# Ocultar visuales del supramundo mientras pelean en la arena
	if nodo_a_ocultar and is_instance_valid(nodo_a_ocultar) and nodo_a_ocultar.has_method("hide"):
		nodo_a_ocultar.hide()
	var sprite_jugador: Node = null
	if jugador:
		sprite_jugador = jugador.get_node_or_null("Sprite2_5D")
		if sprite_jugador:
			sprite_jugador.hide()

	# Aplicar personalizaciones del encuentro (música, fondo, recompensas, jingle y textos)
	if arena.has_method("aplicar_configuracion_encuentro"):
		arena.aplicar_configuracion_encuentro(
			musica_combate,
			textura_fondo,
			texto_recompensas,
			exp_recompensa,
			jingle_a_usar,
			texto_inicio_combate,
			texto_victoria,
			texto_derrota,
			texto_huida,
			texto_titulo_recompensas
		)

	# Inicializar combatientes
	var lista_aliados: Array = aliados if not aliados.is_empty() else [JugadorBattlerScene]
	var lista_enemigos: Array = enemigos if not enemigos.is_empty() else [PotBattlerScene]
	arena.inicializar(lista_aliados, lista_enemigos, jugador)

	# Quitar cortina de entrada para revelar la arena
	var tween_unfade: Tween = create_tween()
	tween_unfade.tween_property(fade_rect, "modulate:a", 0.0, 0.2)
	await tween_unfade.finished
	canvas_transicion.queue_free()

	combate_iniciado.emit()

	# Comenzar batalla y esperar resultado
	arena.comenzar_combate()
	var resultado: CombatArena.ResultadoCombate = await arena.combate_terminado

	# Sincronizar vida restante del jugador de vuelta a GameState
	var gs = _obtener_game_state()
	if gs:
		for a in arena.aliados:
			if is_instance_valid(a) and a.controlado_por_jugador:
				gs.actualizar_hp(a.hp)
				break

	# Transición de salida
	var canvas_salida: CanvasLayer = CanvasLayer.new()
	canvas_salida.layer = 100
	var fade_salida: ColorRect = ColorRect.new()
	fade_salida.color = color_fundido_salida
	fade_salida.modulate.a = 0.0
	fade_salida.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_salida.add_child(fade_salida)
	get_tree().root.add_child(canvas_salida)

	var tween_fade_out: Tween = create_tween()
	tween_fade_out.tween_property(fade_salida, "modulate:a", 1.0, duracion_fundido_salida)
	await tween_fade_out.finished

	# Liberar arena y restaurar cámara
	arena.queue_free()
	if cam_mundo and is_instance_valid(cam_mundo):
		cam_mundo.make_current()

	# Restaurar visuales del supramundo
	if nodo_a_ocultar and is_instance_valid(nodo_a_ocultar) and nodo_a_ocultar.has_method("show"):
		nodo_a_ocultar.show()
	if sprite_jugador and is_instance_valid(sprite_jugador):
		sprite_jugador.show()

	# Desvanecer cortina de salida
	var tween_unfade_out: Tween = create_tween()
	tween_unfade_out.tween_property(fade_salida, "modulate:a", 0.0, 0.22)
	await tween_unfade_out.finished
	canvas_salida.queue_free()

	_combate_en_curso = false

	# Emitir señales correspondientes
	combate_terminado.emit(resultado)
	match resultado:
		CombatArena.ResultadoCombate.VICTORIA:
			_entregar_recompensas()
			victoria.emit()
			if auto_eliminar_padre_en_victoria:
				var padre: Node = get_parent()
				if padre and is_instance_valid(padre):
					padre.queue_free()
		CombatArena.ResultadoCombate.DERROTA:
			derrota.emit()
		CombatArena.ResultadoCombate.HUIDA:
			huida.emit()

	return resultado

# ---------------------------------------------------------------------------
# Utilidades auxiliares
# ---------------------------------------------------------------------------

func _obtener_jugador() -> CharacterBody3D:
	var mundo: Node = get_tree().current_scene
	if mundo != null and mundo.has_method("get_active_player"):
		return mundo.get_active_player()
	var jugador: Node = get_tree().get_first_node_in_group("player")
	if jugador is CharacterBody3D:
		return jugador as CharacterBody3D
	return null

func _bloquear_jugador(jugador: CharacterBody3D, bloquear: bool) -> void:
	if not is_instance_valid(jugador) or not ("is_interacting" in jugador):
		return
	jugador.is_interacting = bloquear

## Reproduce un SFX o jingle de forma global e independiente
func _reproducir_audio(stream: AudioStream) -> void:
	if stream == null or not is_inside_tree():
		return
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _obtener_game_state():
	var GS = load("res://scripts/core/game_state.gd")
	if GS and GS.instancia != null:
		return GS.instancia
	if Engine.has_singleton("GameState"):
		return Engine.get_singleton("GameState")
	if is_inside_tree() and get_tree() and get_tree().root.has_node("GameState"):
		return get_tree().root.get_node("GameState")
	return null

func _entregar_recompensas() -> void:
	var gs = _obtener_game_state()
	if not gs:
		return
	if exp_recompensa > 0 and gs.has_method("agregar_exp"):
		gs.agregar_exp(exp_recompensa)
	
	for item in items_garantizados:
		if item and gs.has_method("agregar_item"):
			gs.agregar_item(item, 1)
	
	if pool_recompensas and randf() <= probabilidad_pool and gs.has_method("agregar_item"):
		var drop: InventoryItem = pool_recompensas.elegir_item()
		if drop:
			var cant: int = pool_recompensas.elegir_cantidad(drop)
			gs.agregar_item(drop, cant)

