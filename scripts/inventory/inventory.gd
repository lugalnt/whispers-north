class_name Inventory
extends Resource

## Gestor de inventario reactivo basado en el diseño de Godot Open RPG.
## Maneja los objetos del jugador, sus cantidades y emite señales de actualización para la interfaz.

signal item_cambiado(item_id: String, cantidad_actual: int)
signal inventario_actualizado()

const RUTA_GUARDADO_DEFECTO: String = "user://inventario_partida.tres"

## Diccionario de almacenamiento:
## Clave: String (id del item) -> Valor: Dictionary { "item": InventoryItem, "cantidad": int }
@export var items: Dictionary = {}

## Añade hasta el límite y devuelve las unidades realmente aceptadas.
func agregar(item: InventoryItem, cantidad: int = 1) -> int:
	if item == null or item.id.strip_edges().is_empty() or cantidad <= 0 or item.cantidad_maxima <= 0:
		return 0
	var actual: int = obtener_cantidad(item.id)
	var aceptada: int = mini(cantidad, maxi(0, item.cantidad_maxima - actual))
	if aceptada == 0:
		return 0
	items[item.id] = {"item": item, "cantidad": actual + aceptada}
	item_cambiado.emit(item.id, actual + aceptada)
	inventario_actualizado.emit()
	return aceptada

## Quita una cantidad de un objeto del inventario. Devuelve true si la operación fue exitosa.
func quitar(item_id: String, cantidad: int = 1) -> bool:
	if not items.has(item_id) or cantidad <= 0:
		return false
	
	var actual: int = items[item_id].get("cantidad", 0)
	if cantidad > actual:
		return false
	var nueva_cantidad: int = actual - cantidad
	
	if nueva_cantidad <= 0:
		items.erase(item_id)
		item_cambiado.emit(item_id, 0)
	else:
		items[item_id]["cantidad"] = nueva_cantidad
		item_cambiado.emit(item_id, nueva_cantidad)
	
	inventario_actualizado.emit()
	return true

## Devuelve la cantidad poseída de un objeto
func obtener_cantidad(item_id: String) -> int:
	if items.has(item_id):
		return items[item_id].get("cantidad", 0)
	return 0

## Devuelve la referencia al recurso InventoryItem o null si no existe
func obtener_item(item_id: String) -> InventoryItem:
	if items.has(item_id):
		return items[item_id].get("item", null) as InventoryItem
	return null

## Devuelve un Array con todos los registros de items [{ "item": InventoryItem, "cantidad": int }]
func obtener_lista_items() -> Array:
	var lista: Array = []
	for clave in items.keys():
		lista.append(items[clave].duplicate())
	lista.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ia: InventoryItem = a["item"]
		var ib: InventoryItem = b["item"]
		if ia.categoria != ib.categoria:
			return ia.categoria < ib.categoria
		var comparacion := ia.nombre.naturalnocasecmp_to(ib.nombre)
		return ia.id < ib.id if comparacion == 0 else comparacion < 0
	)
	return lista

## Comprueba si el inventario no tiene objetos
func esta_vacio() -> bool:
	return items.is_empty()

## Guarda el estado del inventario en disco
func guardar(ruta: String = RUTA_GUARDADO_DEFECTO) -> void:
	ResourceSaver.save(self, ruta)

## Restaura el inventario desde disco o genera uno nuevo si no existe
static func restaurar(ruta: String = RUTA_GUARDADO_DEFECTO) -> Inventory:
	if FileAccess.file_exists(ruta):
		var cargado = ResourceLoader.load(ruta) as Inventory
		if cargado != null:
			return cargado
	var nuevo := Inventory.new()
	return nuevo
