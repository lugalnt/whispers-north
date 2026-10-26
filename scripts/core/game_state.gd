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

func _init() -> void:
	instancia = self
	_inicializar_stats()

func _enter_tree() -> void:
	instancia = self

func _ready() -> void:
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
func agregar_item(item_o_id, cantidad: int = 1) -> void:
	var item: InventoryItem = null
	if item_o_id is String:
		item = ItemDatabase.obtener_item(item_o_id)
	elif item_o_id is InventoryItem:
		item = item_o_id
	
	if item != null:
		inventario.agregar(item, cantidad)

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

## Consume un ítem consumible y aplica sus efectos
func usar_item(item_id: String) -> bool:
	var item: InventoryItem = inventario.obtener_item(item_id)
	if item == null or not item.puede_usarse():
		return false
	
	if item.curacion_hp > 0:
		curar_hp(item.curacion_hp)
	
	inventario.quitar(item_id, 1)
	return true

## Desbloquea una nueva acción de combate para el jugador
func desbloquear_accion(id_accion: String) -> void:
	if id_accion not in acciones_desbloqueadas:
		acciones_desbloqueadas.append(id_accion)
		print("[GameState] ¡Acción de combate desbloqueada: %s!" % id_accion)

## Comprueba si el jugador tiene una acción de combate desbloqueada
func tiene_accion(id_accion: String) -> bool:
	return id_accion in acciones_desbloqueadas
