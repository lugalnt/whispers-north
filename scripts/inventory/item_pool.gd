class_name ItemPool
extends Resource

## Pool o tabla de botín (Loot Table) para el mundo y enemigos.
## Configurable visualmente desde el Inspector de Godot.
## Permite definir probabilidades y pesos para la aparición de objetos en cofres, jarrones o el supramundo.

@export var nombre: String = "Pool de Ítems"
@export var entradas: Array[ItemPoolEntry] = []

## Selecciona un ítem aleatorio de la pool basándose en el peso de cada entrada
func elegir_item_aleatorio() -> InventoryItem:
	if entradas.is_empty():
		return null
	
	var peso_total: float = 0.0
	for e in entradas:
		if e != null and e.item != null and e.peso > 0.0:
			peso_total += e.peso
	
	if peso_total <= 0.0:
		return null
	
	var r: float = randf_range(0.0, peso_total)
	var acumulado: float = 0.0
	for e in entradas:
		if e != null and e.item != null and e.peso > 0.0:
			acumulado += e.peso
			if r <= acumulado:
				return e.item
	
	return entradas[0].item if entradas[0] != null else null

## Alias conveniente para elegir_item_aleatorio()
func elegir_item() -> InventoryItem:
	return elegir_item_aleatorio()

## Obtiene la cantidad aleatoria configurada para un ítem dentro de la pool
func elegir_cantidad(item_buscado: InventoryItem) -> int:
	for e in entradas:
		if e and e.item == item_buscado:
			return randi_range(e.cantidad_min, e.cantidad_max)
	return 1


## Genera una lista de drops resolviendo probabilidades individuales y pesos
## Devuelve Array de diccionarios: [{ "item": InventoryItem, "cantidad": int }]
func generar_drops() -> Array[Dictionary]:
	var resultado: Array[Dictionary] = []
	for e in entradas:
		if e == null or e.item == null:
			continue
		# Si cumple la probabilidad individual
		if randf() <= e.probabilidad:
			var cant: int = randi_range(e.cantidad_min, e.cantidad_max)
			if cant > 0:
				resultado.append({
					"item": e.item,
					"cantidad": cant
				})
	return resultado

## Devuelve todos los ítems únicos contenidos en esta pool
func obtener_todos_los_items() -> Array[InventoryItem]:
	var lista: Array[InventoryItem] = []
	for e in entradas:
		if e != null and e.item != null and not lista.has(e.item):
			lista.append(e.item)
	return lista
