class_name ItemPoolEntry
extends Resource

## Entrada individual dentro de una tabla de botín (ItemPool).
## Define qué ítem puede aparecer, su probabilidad y cantidades mínimas/máximas.

@export var item: InventoryItem
## Peso relativo para la ruleta ponderada de la pool (mayor peso = más frecuente)
@export_range(0.01, 100.0, 0.1) var peso: float = 1.0
## Probabilidad independiente (0.0 a 1.0) al evaluar múltiples drops
@export_range(0.0, 1.0, 0.05) var probabilidad: float = 1.0
@export_range(1, 99, 1) var cantidad_min: int = 1
@export_range(1, 99, 1) var cantidad_max: int = 1
