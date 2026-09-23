extends Node2D

## Controla la animación del fondo del Menú Principal.
## Desplaza nubes en X y nieve en Y de forma infinita usando wrapping manual.

@export var velocidad := 15.0      ## Velocidad horizontal de las nubes (px/s)
@export var velocidad2 := 25.0     ## Velocidad vertical de la nieve (px/s)
@export var ancho_fondo := 576.0   ## Ancho base del sprite de fondo (px sin escala)

func _process(delta):
	$Clouds.position.x += velocidad * delta
	$Clouds2.position.x += velocidad * delta
	$Snow.position.y += velocidad2 * delta
	$Snow2.position.y += velocidad2 * delta

	if $Clouds.position.x >= 2880.0:
		$Clouds.position.x -= 3840.0

	if $Clouds2.position.x >= 2880.0:
		$Clouds2.position.x -= 3840.0
		
	if $Snow.position.y >= 1620.0:
		$Snow.position.y -= 2160.0
		
	if $Snow2.position.y >= 1620.0:
		$Snow2.position.y -= 2160.0


func _ready() -> void:
	## Conecta la referencia del panel del menú principal al menú de opciones.
	## El botón "Back" del addon usa esto para saber qué mostrar al volver.
	$Settings.MenuPanelRef = $Menu/Buttons


func _on_options_button_pressed() -> void:
	$Menu/Buttons.hide()
	$Settings.show()
