class_name ItemDatabase
extends RefCounted

## Registro centralizado y escáner automático de ítems del juego.
## Descubre dinámicamente cualquier recurso .tres creado en res://data/items/.
## Permite añadir nuevos ítems simplemente guardando un nuevo .tres en esa carpeta.

const CARPETA_ITEMS: String = "res://data/items/"

static var _cache_items: Dictionary = {}
static var _inicializado: bool = false

## Inicializa la base de datos escaneando res://data/items/
static func inicializar() -> void:
	_cache_items.clear()
	
	# 1. Asegurar precargas conocidas por defecto
	_registrar_item_archivo("res://data/items/fragmento_ceramica.tres")
	_registrar_item_archivo("res://data/items/queso_nordico.tres")
	_registrar_item_archivo("res://data/items/llave_antigua.tres")
	
	# 2. Escanear directorio para descubrir nuevos ítems creados por el usuario
	if DirAccess.dir_exists_absolute(CARPETA_ITEMS):
		var dir := DirAccess.open(CARPETA_ITEMS)
		if dir != null:
			dir.list_dir_begin()
			var nombre_archivo := dir.get_next()
			while not nombre_archivo.is_empty():
				if not dir.current_is_dir() and (nombre_archivo.ends_with(".tres") or nombre_archivo.ends_with(".res")):
					var ruta_completa := CARPETA_ITEMS + nombre_archivo
					_registrar_item_archivo(ruta_completa)
				nombre_archivo = dir.get_next()
			dir.list_dir_end()
	
	_inicializado = true

## Registra un archivo de recurso en la caché
static func _registrar_item_archivo(ruta: String) -> void:
	if not ResourceLoader.exists(ruta):
		return
	var res = load(ruta)
	if res is InventoryItem:
		var item: InventoryItem = res as InventoryItem
		if not item.id.is_empty():
			_cache_items[item.id] = item

## Obtiene un ítem por su ID único (ej: "queso_nordico")
static func obtener_item(item_id: String) -> InventoryItem:
	if not _inicializado or _cache_items.is_empty():
		inicializar()
	return _cache_items.get(item_id, null)

## Registra dinámicamente un ítem en tiempo de ejecución
static func registrar_item(item: InventoryItem) -> void:
	if item != null and not item.id.is_empty():
		_cache_items[item.id] = item

## Devuelve la lista completa de todos los ítems registrados en el proyecto
static func obtener_todos_los_items() -> Array[InventoryItem]:
	if not _inicializado or _cache_items.is_empty():
		inicializar()
	var lista: Array[InventoryItem] = []
	for k in _cache_items.keys():
		lista.append(_cache_items[k])
	return lista

## Devuelve un duplicado del diccionario completo con todos los ítems indexados por ID
static func obtener_diccionario_items() -> Dictionary:
	if not _inicializado or _cache_items.is_empty():
		inicializar()
	return _cache_items.duplicate()


## Comprueba si existe un ítem con el id dado
static func tiene_item(item_id: String) -> bool:
	if not _inicializado:
		inicializar()
	return _cache_items.has(item_id)
