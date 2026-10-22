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

## Agrega una cantidad de un objeto al inventario
func agregar(item: InventoryItem, cantidad: int = 1) -> void:
	if item == null or cantidad <= 0:
		return
	
	var id: String = item.id
	if items.has(id):
		var actual: int = items[id].get("cantidad", 0)
		var nueva_cantidad: int = mini(actual + cantidad, item.cantidad_maxima)
		items[id]["cantidad"] = nueva_cantidad
		items[id]["item"] = item
	else:
		items[id] = {
			"item": item,
			"cantidad": mini(cantidad, item.cantidad_maxima)
		}
	
	item_cambiado.emit(id, items[id]["cantidad"])
	inventario_actualizado.emit()

## Quita una cantidad de un objeto del inventario. Devuelve true si la operación fue exitosa.
func quitar(item_id: String, cantidad: int = 1) -> bool:
	if not items.has(item_id) or cantidad <= 0:
		return false
	
	var actual: int = items[item_id].get("cantidad", 0)
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
		lista.append(items[clave])
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
