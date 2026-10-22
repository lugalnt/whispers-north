class_name InventoryItem
extends Resource

## Definición de un ítem para el inventario del juego (estilo Open RPG / Paper Mario).
## Permite crear recursos independientes .tres en data/items/ configurables desde el editor.

enum Categoria {
	OBJETO,
	CONSUMIBLE,
	CLAVE
}

@export var id: String = "item"
@export var nombre: String = "Objeto"
@export_multiline var descripcion: String = "Descripción del objeto."
@export var icono: Texture2D
@export var categoria: Categoria = Categoria.OBJETO
@export var cantidad_maxima: int = 99

## Efecto de curación inmediata en HP al consumirse (si aplica)
@export var curacion_hp: int = 0

## Devuelve el texto legible de la categoría
func obtener_nombre_categoria() -> String:
	match categoria:
		Categoria.CONSUMIBLE:
			return "Consumible"
		Categoria.CLAVE:
			return "Objeto Clave"
		_:
			return "Objeto General"

func puede_usarse() -> bool:
	return categoria == Categoria.CONSUMIBLE and curacion_hp > 0
