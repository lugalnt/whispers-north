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
signal encuentro_rechazado(motivo: String)
signal combate_cancelado(motivo: String)
signal reserva_confirmada(sesion: RefCounted)

const Sesion = preload("res://scripts/combat/sesion_encuentro.gd")

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
var ultima_cancelacion: String = ""

func _ready() -> void:
	if auto_iniciar_en_area:
		var padre: Node = get_parent()
		if padre is Area3D:
			(padre as Area3D).body_entered.connect(_on_parent_area_body_entered)

func _on_parent_area_body_entered(body: Node3D) -> void:
	if not activo or _combate_en_curso:
		return
	if body.is_in_group("player") or "is_interacting" in body:
		var area: Area3D = get_parent() as Area3D
		iniciar_combate(body as CharacterBody3D, area, func(): return is_instance_valid(body) and area.overlaps_body(body))

## Inicia el flujo completo del encuentro de combate:
## 1. Congela al jugador y guarda la cámara del supramundo.
## 2. Prepara la arena para heredar configuraciones visuales (jingle, fondo, textos).
## 3. Ejecuta el jingle y el destello (flash) de transición.
## 4. Oculta el nodo de la entidad en el mundo mientras dura la batalla.
## 5. Revela la arena configurada y ejecuta el combate.
## 6. Al finalizar, restaura cámaras, visibilidad y emite señales.
func iniciar_combate(jugador: CharacterBody3D = null, nodo_a_ocultar: Node = null, validar_alcance: Callable = Callable()) -> CombatArena.ResultadoCombate:
	if not activo or _combate_en_curso:
		encuentro_rechazado.emit("inactivo_o_en_curso")
		return CombatArena.ResultadoCombate.HUIDA
	if jugador == null:
		jugador = _obtener_jugador()
	var gestor: Node = get_node("/root/CoordinadorEncuentros")
	var sesion: Sesion = gestor.reservar(self, jugador, validar_alcance)
	if sesion == null:
		encuentro_rechazado.emit("no_disponible_o_fuera_de_alcance")
		return CombatArena.ResultadoCombate.HUIDA
	_combate_en_curso = true
	ultima_cancelacion = ""
	sesion.recordar_visual(nodo_a_ocultar)
	sesion.recordar_visual(jugador.get_node_or_null("Sprite2_5D"))
	reserva_confirmada.emit(sesion)
	if not sesion.terminada:
		_ejecutar_encuentro(sesion, nodo_a_ocultar)
	# La sesión, no la arena, completa también cancelación y salidas excepcionales.
	if not sesion.terminada:
		await sesion.finalizada
	_combate_en_curso = false
	if sesion.cancelada:
		ultima_cancelacion = sesion.motivo
		combate_cancelado.emit(sesion.motivo)
		return CombatArena.ResultadoCombate.HUIDA
	var resultado: CombatArena.ResultadoCombate = sesion.resultado as CombatArena.ResultadoCombate
	combate_terminado.emit(resultado)
	match resultado:
		CombatArena.ResultadoCombate.VICTORIA:
			_entregar_recompensas()
			victoria.emit()
			if auto_eliminar_padre_en_victoria:
				get_parent().queue_free()
		CombatArena.ResultadoCombate.DERROTA:
			derrota.emit()
		CombatArena.ResultadoCombate.HUIDA:
			huida.emit()
	return resultado


func cancelar_combate(motivo: String = "cancelado") -> void:
	get_node("/root/CoordinadorEncuentros").cancelar(self, motivo)


func _ejecutar_encuentro(sesion: Sesion, nodo_a_ocultar: Node) -> void:
	var gestor: Node = get_node("/root/CoordinadorEncuentros")
	var escena: PackedScene = escena_arena if escena_arena else ArenaDefaultScene
	var instancia: Node = escena.instantiate()
	if not instancia is CombatArena:
		if instancia != null:
			instancia.free()
		gestor.cancelar(self, "escena_arena_invalida")
		return
	var arena: CombatArena = instancia as CombatArena
	sesion.recursos.append(arena)
	var lista_aliados: Array = aliados if not aliados.is_empty() else [JugadorBattlerScene]
	var lista_enemigos: Array = enemigos if not enemigos.is_empty() else [PotBattlerScene]
	if not _validar_battlers(lista_aliados) or not _validar_battlers(lista_enemigos):
		gestor.cancelar(self, "battler_invalido")
		return
	arena.auto_iniciar_si_esta_vacio = false
	sesion.mundo.add_child(arena)
	arena.global_position = Vector3(0.0, altura_aislamiento, 0.0)
	var jingle: AudioStream = jingle_inicio if jingle_inicio else arena.jingle_inicio
	if jingle != null:
		sesion.recursos.append(_reproducir_audio(jingle))
		arena._jingle_reproducido = true

	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 105
	sesion.recursos.append(canvas)
	var cortina: ColorRect = ColorRect.new()
	cortina.color = color_flash if flash_activo else color_fundido_entrada
	cortina.modulate.a = 0.0
	cortina.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(cortina)
	get_tree().root.add_child(canvas)
	var entrada: Tween = create_tween()
	if flash_activo and cantidad_flashes > 0:
		for i in cantidad_flashes:
			entrada.tween_property(cortina, "modulate:a", 1.0, duracion_flash)
			if i < cantidad_flashes - 1:
				entrada.tween_property(cortina, "modulate:a", 0.0, duracion_flash * 0.8)
	else:
		entrada.tween_property(cortina, "modulate:a", 1.0, duracion_fundido_entrada)
	if not await _esperar_tween(entrada, sesion):
		return
	cortina.color = color_fundido_entrada
	if is_instance_valid(nodo_a_ocultar) and nodo_a_ocultar.has_method("hide"):
		nodo_a_ocultar.hide()
	var sprite: Node = sesion.jugador.get_node_or_null("Sprite2_5D")
	if sprite != null:
		sprite.hide()
	arena.aplicar_configuracion_encuentro(musica_combate, textura_fondo, texto_recompensas,
		exp_recompensa, jingle, texto_inicio_combate, texto_victoria, texto_derrota,
		texto_huida, texto_titulo_recompensas)
	arena.inicializar(lista_aliados, lista_enemigos, sesion.jugador)
	var revelar: Tween = create_tween()
	revelar.tween_property(cortina, "modulate:a", 0.0, 0.2)
	if not await _esperar_tween(revelar, sesion):
		return

	gestor.ejecutar(sesion, arena)
	arena.combate_terminado.connect(sesion.registrar_resultado)
	combate_iniciado.emit()
	if sesion.terminada:
		return
	if sesion.fase == Sesion.Fase.EJECUTANDO:
		arena.comenzar_combate()
	while not sesion.terminada and sesion.fase == Sesion.Fase.EJECUTANDO:
		await get_tree().process_frame
	if sesion.terminada:
		return
	var gs = _obtener_game_state()
	if gs:
		for aliado in arena.aliados:
			if is_instance_valid(aliado) and aliado.controlado_por_jugador:
				gs.actualizar_hp(aliado.hp)
				break
	cortina.color = color_fundido_salida
	var salida: Tween = create_tween()
	salida.tween_property(cortina, "modulate:a", 1.0, duracion_fundido_salida)
	if not await _esperar_tween(salida, sesion):
		return
	arena.queue_free()
	gestor.restaurar_visuales(sesion)
	var retorno: Tween = create_tween()
	retorno.tween_property(cortina, "modulate:a", 0.0, 0.22)
	if not await _esperar_tween(retorno, sesion):
		return
	gestor.finalizar(sesion)


func _esperar_tween(tween: Tween, sesion: Sesion) -> bool:
	sesion.tweens.append(tween)
	while not sesion.terminada and tween.is_valid() and tween.is_running():
		await get_tree().process_frame
	return not sesion.terminada


func _validar_battlers(escenas: Array) -> bool:
	for escena in escenas:
		if not escena is PackedScene:
			return false
		var instancia: Node = escena.instantiate()
		var valido: bool = instancia is Battler
		if instancia != null:
			instancia.free()
		if not valido:
			return false
	return true

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

## Reproduce un SFX o jingle de forma global e independiente
func _reproducir_audio(stream: AudioStream) -> AudioStreamPlayer:
	if stream == null or not is_inside_tree():
		return null
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.stream = stream
	get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player

func _obtener_game_state():
	# Autoload GameState (acceso por nodo para compatibilidad con scripts headless)
	var ml := Engine.get_main_loop() as SceneTree
	return ml.root.get_node_or_null("GameState") if ml else null

func _entregar_recompensas() -> void:
	var gs = _obtener_game_state()
	if not gs:
		return
	# La EXP ya la otorga CombatArena._finalizar_victoria (exp_victoria = exp_recompensa); no duplicar aquí
	for item in items_garantizados:
		if item and gs.has_method("agregar_item"):
			gs.agregar_item(item, 1)
	
	if pool_recompensas and randf() <= probabilidad_pool and gs.has_method("agregar_item"):
		var drop: InventoryItem = pool_recompensas.elegir_item()
		if drop:
			var cant: int = pool_recompensas.elegir_cantidad(drop)
			gs.agregar_item(drop, cant)

