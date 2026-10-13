extends CanvasLayer
## Nieve minimalista: píxeles cayendo lento sobre toda la pantalla.
## Los parámetros (cantidad, velocidad, tamaño, color) se ajustan en el
## nodo "Flakes" (CPUParticles2D) desde el Inspector.

@onready var flakes: CPUParticles2D = $Flakes

func _ready() -> void:
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()

# Adapta el emisor al ancho/alto actual de la ventana (cae desde arriba).
func _fit_to_viewport() -> void:
	var size: Vector2 = get_viewport().get_visible_rect().size
	flakes.position = Vector2(size.x * 0.5, -8.0)
	flakes.emission_rect_extents = Vector2(size.x * 0.6, 1.0)
	# Tiempo de vida = altura / velocidad media, para que cubra toda la pantalla.
	var avg_speed: float = (flakes.initial_velocity_min + flakes.initial_velocity_max) * 0.5
	flakes.lifetime = (size.y + 16.0) / avg_speed
	flakes.preprocess = flakes.lifetime # La nieve ya está cayendo al entrar a la escena.
	flakes.restart()
