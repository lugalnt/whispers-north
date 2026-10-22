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

func _ready() -> void:
	_inicializar_stats()
	_cargar_items_iniciales()
	inventario.inventario_actualizado.connect(func(): inventario_modificado.emit())

func _inicializar_stats() -> void:
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

## Carga algunos objetos temáticos iniciales de demostración
func _cargar_items_iniciales() -> void:
	if not inventario.esta_vacio():
		return
	
	var item_fragmento: InventoryItem = InventoryItem.new()
	item_fragmento.id = "fragmento_ceramica"
	item_fragmento.nombre = "Fragmento de Cerámica"
	item_fragmento.descripcion = "Un trozo de arcilla antigua decorado con runas nórdicas. Parece provenir de un jarrón encantado."
	item_fragmento.categoria = InventoryItem.Categoria.OBJETO
	item_fragmento.icono = preload("res://assets/sprites/ui/icon.png")
	inventario.agregar(item_fragmento, 3)

	var item_queso: InventoryItem = InventoryItem.new()
	item_queso.id = "queso_nordico"
	item_queso.nombre = "Queso Nórdico"
	item_queso.descripcion = "Queso ahumado de montaña. Delicioso y reconfortante. Restaura 5 HP al consumirse."
	item_queso.categoria = InventoryItem.Categoria.CONSUMIBLE
	item_queso.curacion_hp = 5
	item_queso.icono = preload("res://assets/sprites/ui/icon.png")
	inventario.agregar(item_queso, 2)

	var item_llave: InventoryItem = InventoryItem.new()
	item_llave.id = "llave_antigua"
	item_llave.nombre = "Llave Antigua de Madera"
	item_llave.descripcion = "Una pequeña llave tallada en madera de roble mohoso. Debe abrir algún cofre o puerta del bosque."
	item_llave.categoria = InventoryItem.Categoria.CLAVE
	item_llave.icono = preload("res://assets/sprites/environment/items/chest_closed.png")
	inventario.agregar(item_llave, 1)

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
