extends CanvasLayer

# Textbox animado estilo "máquina de escribir" que reproduce un spritesheet.
# Los tiempos de cada frame se copiaron del GIF original (65 frames):
#   - 34 frames de 0.02 s  -> se escribe la primera frase
#   - 4 frames de 0.20 s   -> parpadea la flecha ▼ (pausa entre frases)
#   - 26 frames de 0.02 s  -> se escribe la segunda frase
#   - 1 frame de 1.50 s    -> el texto completo queda en pantalla
#
# Uso:
#   var caja = escena_textbox.instantiate()
#   add_child(caja)
#   caja.reproducir()
#   var completo: bool = await caja.terminado   # true = acabó, false = se canceló
#   caja.ocultar()

# Se emite al terminar la animación (true) o al cancelarla con ocultar() (false)
signal terminado(completo: bool)

# Segmentos [cantidad de frames, duración de cada frame en segundos]
const SEGMENTOS_DURACION: Array = [[34, 0.02], [4, 0.20], [26, 0.02], [1, 1.50]]

@export var spritesheet: Texture2D = preload("res://assets/sprites/ui/intentaste-empezar-una-pelea--ezgif.com-gif-to-sprite-converter.png")
@export var columnas: int = 5
@export var tamano_frame: Vector2i = Vector2i(608, 256)
# Escala de la caja en pantalla (1.0 = tamaño original del sprite)
@export var escala: float = 1.0
# Separación en píxeles entre la caja y el borde inferior de la pantalla
@export var margen_inferior: float = 24.0
# Duración del fundido de entrada
@export var duracion_aparicion: float = 0.12

@onready var caja: TextureRect = $Caja

var _atlas: AtlasTexture
var _duraciones: PackedFloat32Array = PackedFloat32Array()
var _frame: int = 0
var _acumulado: float = 0.0
var _reproduciendo: bool = false

func _ready() -> void:
	for segmento in SEGMENTOS_DURACION:
		for i in range(int(segmento[0])):
			_duraciones.append(float(segmento[1]))

	_atlas = AtlasTexture.new()
	_atlas.atlas = spritesheet
	caja.texture = _atlas

	# Anclada abajo al centro de la pantalla
	var tam: Vector2 = Vector2(tamano_frame) * escala
	caja.anchor_left = 0.5
	caja.anchor_right = 0.5
	caja.anchor_top = 1.0
	caja.anchor_bottom = 1.0
	caja.offset_left = -tam.x / 2.0
	caja.offset_right = tam.x / 2.0
	caja.offset_top = -tam.y - margen_inferior
	caja.offset_bottom = -margen_inferior

	_mostrar_frame(0)
	visible = false
	set_process(false)

# Muestra la caja y reproduce la animación desde el principio
func reproducir() -> void:
	_frame = 0
	_acumulado = 0.0
	_mostrar_frame(0)
	_reproduciendo = true
	visible = true

	caja.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(caja, "modulate:a", 1.0, duracion_aparicion)

	set_process(true)

# Oculta la caja. Si la animación seguía en curso, emite terminado(false)
func ocultar() -> void:
	var estaba_reproduciendo: bool = _reproduciendo
	_reproduciendo = false
	set_process(false)
	visible = false
	if estaba_reproduciendo:
		terminado.emit(false)

func _process(delta: float) -> void:
	if not _reproduciendo:
		return

	_acumulado += delta
	while _acumulado >= _duraciones[_frame]:
		_acumulado -= _duraciones[_frame]
		if _frame >= _duraciones.size() - 1:
			# Último frame cumplido: la animación terminó (la caja queda visible)
			_reproduciendo = false
			set_process(false)
			terminado.emit(true)
			return
		_frame += 1
	_mostrar_frame(_frame)

# Recorta del spritesheet el frame indicado
func _mostrar_frame(indice: int) -> void:
	var col: int = indice % columnas
	@warning_ignore("integer_division")
	var fila: int = indice / columnas
	_atlas.region = Rect2(
		col * tamano_frame.x,
		fila * tamano_frame.y,
		tamano_frame.x,
		tamano_frame.y
	)
