extends Node

## Estado global del juego y persistencia del jugador (Autoload GameState).
## Inspirado en el autoload `Player` de Godot Open RPG.
## Mantiene el inventario, nivel, EXP, stats y estado de acompañantes.

signal inventario_modificado()
signal stats_modificadas()
signal exp_ganada(cantidad: int)
signal nivel_subido(nuevo_nivel: int)

const PlayerBattlerScene = preload("res://scenes/combat/battlers/PlayerBattler.tscn")

var inventario: Inventory = Inventory.new()

var nombre_jugador: String = "Eric"
var titulo_jugador: String = "Explorador del Norte"
var nivel: int = 1
var exp_actual: int = 0
var exp_para_siguiente_nivel: int = 50

# Estadísticas base del jugador
var stats: BattlerStats
var hp_actual: int = 15

# Estado del acompañante
var tiene_rata: bool = false

# Acciones de combate desbloqueadas para el jugador
var acciones_desbloqueadas: Array[String] = []

# Transición entre escenas de mundo
var spawn_nombre_marcador: String = ""
var spawn_offset: Vector3 = Vector3.ZERO
var spawn_camara_siguiente: String = ""
var usar_personaje_32: bool = false

# ---------------------------------------------------------------------------
# Recorrido de la demo y progresión entre mapas
# ---------------------------------------------------------------------------

signal progreso_cambiado(id: StringName, valor: Variant)

## Escenas del recorrido Casa → Vecindad → Pueblo → Cueva → Bosque y ruinas.
const ESCENA_CASA: String = "res://scenes/world/World_House.tscn"
const ESCENA_VECINDAD: String = "res://scenes/world/World.tscn"
const ESCENA_PUEBLO: String = "res://scenes/world/World_Town.tscn"
const ESCENA_CUEVA: String = "res://scenes/world/World_Cave.tscn"
const ESCENA_BOSQUE: String = "res://scenes/world/World_ForestRuins.tscn"

## Escena en la que empieza una Nueva partida.
## La demo comienza junto a la cama, con el diario como tutorial inicial.
var escena_nueva_partida: String = ESCENA_CASA

## Identificadores ESTABLES de progresión (no renombrar: son claves persistentes).
## Formato "categoria.nombre". Ver docs/AVANCE_DEMO.md.
const PROGRESO_TUTORIAL_DIARIO: StringName = &"tutorial.diario_casa"
const PROGRESO_CHARLA_PROGENITOR: StringName = &"dialogo.progenitor_casa"
const RECOMPENSA_NPC_UTIL: StringName = &"recompensa.npc_util_pueblo"
const ENCUENTRO_POT_VECINDAD: StringName = &"encuentro.pot_vecindad"
const ENCUENTRO_TRIO_POTS_PUEBLO: StringName = &"encuentro.trio_pots_pueblo"
const COFRE_CUEVA_OCULTO: StringName = &"cofre.cueva_oculto"
const OBJETO_IMPORTANTE_RUINAS: StringName = &"evento.objeto_importante_ruinas"
const JEFE_RUINAS_DERROTADO: StringName = &"jefe.ruinas_derrotado"
const DEMO_COMPLETADA: StringName = &"demo.completada"

## Banderas de progresión: StringName -> Variant (normalmente bool).
## Solo vive en memoria durante la partida (sin guardado en disco).
var progreso: Dictionary = {}
## Ruta de la zona cargada actualmente (la actualiza ZonaMundo/World al entrar).
var zona_actual: String = ""

## Marca una bandera de progreso (cofre abierto, tutorial visto, jefe derrotado...).
func marcar_progreso(id: StringName, valor: Variant = true) -> void:
	if id == &"":
		push_warning("GameState: id de progreso vacío")
		return
	progreso[id] = valor
	progreso_cambiado.emit(id, valor)

## Devuelve true si la bandera existe y es verdadera.
func tiene_progreso(id: StringName) -> bool:
	return bool(progreso.get(id, false))

## Devuelve el valor guardado para la bandera o `defecto` si no existe.
func obtener_progreso(id: StringName, defecto: Variant = null) -> Variant:
	return progreso.get(id, defecto)

## Reclama un evento único: devuelve true SOLO la primera vez y lo marca.
## Usar para recompensas únicas, cofres, encuentros relevantes y secuencias del jefe.
func reclamar_unico(id: StringName) -> bool:
	if id == &"" or tiene_progreso(id):
		return false
	marcar_progreso(id, true)
	return true

## Reinicia todo el estado de partida para comenzar una Nueva partida coherente.
## No toca nombre/título del jugador ni configuración de audio/vídeo.
func nueva_partida() -> void:
	var coordinador: Node = get_node_or_null("/root/CoordinadorEncuentros")
	if coordinador != null and coordinador.has_method("cancelar"):
		coordinador.cancelar(null, "nueva_partida")
	nivel = 1
	exp_actual = 0
	exp_para_siguiente_nivel = EXP_INICIAL_SIGUIENTE_NIVEL
	stats = null
	_inicializar_stats()
	tiene_rata = false
	acciones_desbloqueadas.clear()
	spawn_nombre_marcador = ""
	spawn_offset = Vector3.ZERO
	spawn_camara_siguiente = ""
	usar_personaje_32 = false
	progreso.clear()
	zona_actual = ""
	# Vaciar en el mismo recurso para conservar las conexiones de señales existentes
	inventario.items.clear()
	_cargar_items_iniciales()
	inventario.inventario_actualizado.emit()
	stats_modificadas.emit()

const EXP_INICIAL_SIGUIENTE_NIVEL: int = 50

## Comprueba si hay un cambio de mundo en curso esperando ubicar al jugador
func hay_transicion_pendiente() -> bool:
	return not spawn_nombre_marcador.is_empty()

## Prepara los parámetros para la escena de destino
func preparar_transicion(marcador_destino: String, offset: Vector3, camara: String) -> void:
	spawn_nombre_marcador = marcador_destino
	spawn_offset = offset
	spawn_camara_siguiente = camara

## Obtiene la posición final en la nueva escena a partir del marcador y limpia el estado
func consumir_posicion_spawn(mundo: Node) -> Vector3:
	var pos: Vector3 = Vector3.ZERO
	if not spawn_nombre_marcador.is_empty() and mundo != null:
		var marcador = mundo.find_child(spawn_nombre_marcador, true, false)
		if marcador != null and marcador is Node3D:
			var m_pos = marcador.global_position if marcador.is_inside_tree() else marcador.position
			pos = m_pos + spawn_offset
	spawn_nombre_marcador = ""
	spawn_offset = Vector3.ZERO
	return pos

## Obtiene el nombre de la cámara que debe activarse y limpia el estado
func consumir_camara_spawn() -> String:
	var cam: String = spawn_camara_siguiente
	spawn_camara_siguiente = ""
	return cam

static var instancia: Node = null

func _enter_tree() -> void:
	# El autoload es la única instancia válida; evita que copias creadas con .new() la reemplacen
	if instancia == null or not is_instance_valid(instancia):
		instancia = self

func _ready() -> void:
	if instancia == null or not is_instance_valid(instancia):
		instancia = self
	_inicializar_stats()
	_cargar_items_iniciales()
	inventario.inventario_actualizado.connect(func(): inventario_modificado.emit())

func _inicializar_stats() -> void:
	if stats != null:
		return
	# Cargar stats base del arquetipo del jugador si existen
	var temp_battler: Battler = PlayerBattlerScene.instantiate() as Battler
	if temp_battler and temp_battler.stats:
		stats = temp_battler.stats.duplicate()
	else:
		stats = BattlerStats.new()
		stats.max_hp = 15
		stats.ataque = 2
		stats.defensa = 1
		stats.velocidad = 12
	hp_actual = stats.max_hp
	if temp_battler:
		temp_battler.queue_free()

@export_group("Inventario Inicial")
## Ítems iniciales otorgados al comenzar. Configurable visualmente asignando recursos .tres desde data/items/
@export var items_iniciales: Array[InventoryItem] = [
	preload("res://data/items/fragmento_ceramica.tres"),
	preload("res://data/items/queso_nordico.tres"),
	preload("res://data/items/llave_antigua.tres"),
]
## Cantidades de cada ítem inicial
@export var cantidades_iniciales: Array[int] = [3, 2, 1]

## Carga los objetos temáticos iniciales desde los recursos .tres configurados
func _cargar_items_iniciales() -> void:
	if not inventario.esta_vacio():
		return
	
	for i in range(items_iniciales.size()):
		var item: InventoryItem = items_iniciales[i]
		if item == null:
			continue
		var cant: int = cantidades_iniciales[i] if i < cantidades_iniciales.size() else 1
		inventario.agregar(item, cant)

## Añade un ítem al inventario pasando su recurso InventoryItem o su ID en String
func agregar_item(item_o_id, cantidad: int = 1) -> int:
	var item: InventoryItem = null
	if item_o_id is String:
		item = ItemDatabase.obtener_item(item_o_id)
	elif item_o_id is InventoryItem:
		item = item_o_id
	
	if item != null:
		return inventario.agregar(item, cantidad)
	return 0

## Suma experiencia y sube de nivel si corresponde
func agregar_exp(cantidad: int) -> void:
	if cantidad <= 0:
		return
	exp_actual += cantidad
	exp_ganada.emit(cantidad)
	
	while exp_actual >= exp_para_siguiente_nivel:
		exp_actual -= exp_para_siguiente_nivel
		nivel += 1
		exp_para_siguiente_nivel = int(exp_para_siguiente_nivel * 1.5)
		# Incrementos por nivel
		if stats:
			stats.max_hp += 2
			stats.ataque += 1
			stats.defensa += 1
			hp_actual = clamp(hp_actual + 2, 1, stats.max_hp)
		nivel_subido.emit(nivel)
	
	stats_modificadas.emit()

## Aumenta el ataque base del jugador y notifica a la interfaz
func aumentar_ataque(cantidad: int = 1) -> void:
	if stats == null:
		_inicializar_stats()
	stats.ataque += cantidad
	stats_modificadas.emit()

## Actualiza la salud actual tras un combate o evento
func actualizar_hp(nuevo_hp: int) -> void:
	if stats:
		hp_actual = clamp(nuevo_hp, 0, stats.max_hp)
	else:
		hp_actual = max(0, nuevo_hp)
	stats_modificadas.emit()

## Cura una cantidad de HP al jugador
func curar_hp(cantidad: int) -> int:
	if not stats or cantidad <= 0:
		return 0
	var hp_anterior: int = hp_actual
	hp_actual = clamp(hp_actual + cantidad, 0, stats.max_hp)
	var curado: int = hp_actual - hp_anterior
	stats_modificadas.emit()
	return curado

## Motivo legible por el que un objeto no puede usarse en exploración.
func motivo_no_usable(item_id: String) -> String:
	var item: InventoryItem = inventario.obtener_item(item_id)
	if item == null or inventario.obtener_cantidad(item_id) <= 0:
		return "No tienes este objeto."
	if not item.puede_usarse():
		return "Este objeto no se consume desde el inventario."
	if stats == null or hp_actual <= 0:
		return "Este objeto no puede revivir al personaje."
	if hp_actual >= stats.max_hp:
		return "Salud completa."
	return ""

## Consume una unidad únicamente cuando puede aplicar su efecto.
func usar_item(item_id: String) -> bool:
	if not motivo_no_usable(item_id).is_empty():
		return false
	var item: InventoryItem = inventario.obtener_item(item_id)
	if not inventario.quitar(item_id, 1):
		return false
	curar_hp(item.curacion_hp)
	return true

## Desbloquea una nueva acción de combate para el jugador
func desbloquear_accion(id_accion: String) -> void:
	if id_accion not in acciones_desbloqueadas:
		acciones_desbloqueadas.append(id_accion)
		print("[GameState] ¡Acción de combate desbloqueada: %s!" % id_accion)

## Comprueba si el jugador tiene una acción de combate desbloqueada
func tiene_accion(id_accion: String) -> bool:
	return id_accion in acciones_desbloqueadas
