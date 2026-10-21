class_name ComandoAccion
extends Control

## Comando de acción estilo Paper Mario: pulsar el botón justo en el momento del impacto.
##
## Es la pieza reutilizable para TODAS las mecánicas de timing (golpe a tiempo, esquive,
## defensa, superguardia, saltos encadenados...). Las acciones lo usan así:
##
##     # Arranca la animación de la acción para que el impacto caiga dentro de 0.6 s...
##     var resultado := await arena.comando.ejecutar(0.6, 0.18, 0.05, arena.a_pantalla(pos))
##     if resultado == ComandoAccion.Resultado.EXITO:
##         ...bonus de daño / esquive...
##
## Reglas:
##   - La ventana válida es [impacto - ventana_antes, impacto + ventana_despues].
##   - Pulsar ANTES de la ventana = ANTICIPADO (bloquea el intento, como en Paper Mario:
##     así no sirve machacar el botón).
##   - `ejecutar()` nunca devuelve antes del momento del impacto, así la acción puede aplicar
##     el daño justo al terminar el await.
##
## Botón: acción `interact` del Input Map (ver docs/INPUT_MAP.md). No se leen teclas crudas.
##
## VISUAL PLACEHOLDER: se dibuja con `_draw()` (círculo con la tecla + anillo que se cierra).
## Para un look definitivo se puede sustituir por sprites/AnimationPlayer manteniendo la
## misma API (`ejecutar` + señal `resuelto`).

enum Resultado { EXITO, FALLO, ANTICIPADO }

signal resuelto(resultado: Resultado)

## Acción del Input Map que se usa para los comandos
@export var accion_input: StringName = &"interact"
@export var radio_boton: float = 24.0
## Tamaño inicial del anillo (en múltiplos del radio del botón)
@export var escala_anillo_inicial: float = 3.2
@export var color_boton: Color = Color(0.13, 0.15, 0.22, 0.92)
@export var color_borde: Color = Color(1.0, 1.0, 1.0, 0.95)
@export var color_anillo: Color = Color(1.0, 1.0, 1.0, 0.85)
@export var color_ventana: Color = Color(0.45, 1.0, 0.55, 1.0)
@export var color_exito: Color = Color(0.45, 1.0, 0.55)
@export var color_fallo: Color = Color(0.75, 0.78, 0.85)
@export var color_anticipado: Color = Color(1.0, 0.65, 0.3)
@export var duracion_feedback: float = 0.55

var _activo: bool = false
var _mostrar_indicador: bool = true
var _t: float = 0.0
var _impacto: float = 0.0
var _antes: float = 0.0
var _despues: float = 0.0
var _resultado: Resultado = Resultado.FALLO
var _centro: Vector2 = Vector2.ZERO
var _usando_mando: bool = false

var _texto_feedback: String = ""
var _color_feedback: Color = Color.WHITE
var _t_feedback: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(false)

## Abre una ventana de timing. `tiempo_impacto` = segundos hasta el impacto.
## `posicion_pantalla` = dónde dibujar el indicador (Vector2(-1, -1) = centro de pantalla).
## `mostrar_indicador` = false para comandos "a ciegas" (p. ej. esquives avanzados).
func ejecutar(tiempo_impacto: float, ventana_antes: float = 0.18, ventana_despues: float = 0.05,
		posicion_pantalla: Vector2 = Vector2(-1, -1), mostrar_indicador: bool = true) -> Resultado:
	if _activo:
		push_warning("ComandoAccion: ya hay un comando en curso.")
		return Resultado.FALLO

	_impacto = maxf(tiempo_impacto, 0.01)
	_antes = maxf(ventana_antes, 0.0)
	_despues = maxf(ventana_despues, 0.0)
	_t = 0.0
	_resultado = Resultado.FALLO
	_mostrar_indicador = mostrar_indicador
	_centro = posicion_pantalla if posicion_pantalla.x >= 0.0 else size * Vector2(0.5, 0.45)
	_texto_feedback = ""
	_activo = true
	set_process(true)
	queue_redraw()

	var resultado: Resultado = await resuelto

	# Nunca devolver antes del impacto: así la animación y el daño quedan sincronizados
	var falta: float = _impacto - _t
	if falta > 0.0:
		await get_tree().create_timer(falta, true).timeout
	return resultado

func esta_activo() -> bool:
	return _activo

func _process(delta: float) -> void:
	if _activo:
		_t += delta
		if _t > _impacto + _despues:
			_resolver(Resultado.FALLO)
	elif _t_feedback > 0.0:
		_t_feedback -= delta
		if _t_feedback <= 0.0:
			_texto_feedback = ""
			set_process(false)
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Solo para mostrar el icono correcto (teclado o mando); no consume el evento
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		_usando_mando = true
	elif event is InputEventKey:
		_usando_mando = false

func _unhandled_input(event: InputEvent) -> void:
	if not _activo:
		return
	if not event.is_action_pressed(accion_input) or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	if _t < _impacto - _antes:
		_resolver(Resultado.ANTICIPADO)
	else:
		_resolver(Resultado.EXITO)

func _resolver(resultado: Resultado) -> void:
	if not _activo:
		return
	_activo = false
	_resultado = resultado
	if _mostrar_indicador or resultado == Resultado.EXITO:
		match resultado:
			Resultado.EXITO:
				_texto_feedback = "¡Bien!"
				_color_feedback = color_exito
			Resultado.ANTICIPADO:
				_texto_feedback = "¡Muy pronto!"
				_color_feedback = color_anticipado
			_:
				_texto_feedback = ""
		_t_feedback = duracion_feedback
	resuelto.emit(resultado)

# ---------------------------------------------------------------------------
# Dibujo (placeholder)
# ---------------------------------------------------------------------------

func _draw() -> void:
	var fuente: Font = ThemeDB.fallback_font
	if _activo and _mostrar_indicador:
		var progreso: float = clampf(_t / _impacto, 0.0, 1.0)
		var en_ventana: bool = _t >= _impacto - _antes
		# Anillo que se cierra sobre el botón: cuando lo toca, es el momento
		var radio_anillo: float = lerpf(radio_boton * escala_anillo_inicial, radio_boton, progreso)
		var color_r: Color = color_ventana if en_ventana else color_anillo
		draw_arc(_centro, radio_anillo, 0.0, TAU, 48, color_r, 3.0 if en_ventana else 2.0, true)
		# Botón
		var radio_b: float = radio_boton * (1.12 if en_ventana else 1.0)
		draw_circle(_centro, radio_b, color_boton)
		draw_arc(_centro, radio_b, 0.0, TAU, 40, color_ventana if en_ventana else color_borde, 2.5, true)
		var etiqueta: String = _nombre_boton()
		var tam_fuente: int = 22 if etiqueta.length() <= 2 else 13
		var ancho: float = fuente.get_string_size(etiqueta, HORIZONTAL_ALIGNMENT_CENTER, -1, tam_fuente).x
		draw_string(fuente, _centro + Vector2(-ancho * 0.5, tam_fuente * 0.36), etiqueta,
				HORIZONTAL_ALIGNMENT_CENTER, -1, tam_fuente, Color.WHITE)

	if _texto_feedback != "":
		var vida: float = clampf(_t_feedback / duracion_feedback, 0.0, 1.0)
		var subida: float = (1.0 - vida) * 18.0
		var tam: int = 26
		var ancho_f: float = fuente.get_string_size(_texto_feedback, HORIZONTAL_ALIGNMENT_CENTER, -1, tam).x
		var pos: Vector2 = _centro + Vector2(-ancho_f * 0.5, -radio_boton * 1.8 - subida)
		var color_f: Color = Color(_color_feedback, vida)
		draw_string_outline(fuente, pos, _texto_feedback, HORIZONTAL_ALIGNMENT_CENTER, -1, tam, 6, Color(0, 0, 0, 0.7 * vida))
		draw_string(fuente, pos, _texto_feedback, HORIZONTAL_ALIGNMENT_CENTER, -1, tam, color_f)

## Nombre del botón a mostrar, leído del Input Map (no se crean ni modifican acciones)
func _nombre_boton() -> String:
	if _usando_mando:
		return "A"
	for evento in InputMap.action_get_events(accion_input):
		if evento is InputEventKey:
			var tecla: InputEventKey = evento
			var codigo: Key = tecla.keycode
			if int(tecla.physical_keycode) != 0:
				codigo = DisplayServer.keyboard_get_keycode_from_physical(tecla.physical_keycode)
			var texto: String = OS.get_keycode_string(codigo)
			if texto != "":
				return texto
	return "A"
