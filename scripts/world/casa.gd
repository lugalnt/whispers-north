extends "res://scripts/world/zona_mundo.gd"

@onready var diario: InteraccionDialogo = $Cuarto/Diario/InteraccionDialogo
@onready var padre: InteraccionDialogo = $PlantaBaja/Erland/InteraccionDialogo
@onready var pista: Label = $Ayuda/Margen/Texto
var _usa_mando := false

func _ready() -> void:
	super._ready()
	diario.dialogo_terminado.connect(_terminar_diario)
	padre.dialogo_terminado.connect(_terminar_charla)
	_configurar_ayuda()
	_actualizar_textos()
	if GameState.tiene_progreso(GameState.PROGRESO_TUTORIAL_DIARIO):
		diario.desactivar()
		pista.hide()
	if GameState.tiene_progreso(GameState.PROGRESO_CHARLA_PROGENITOR):
		padre.cambiar_lineas_rapidas(["Abrígate bien. Estaré aquí si necesitas volver a casa."])

func _input(event: InputEvent) -> void:
	preload("res://scripts/ui/input_hints.gd").registrar(event)
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and absf(event.axis_value) < 0.3:
			return
		_usa_mando = true
	elif event is InputEventKey or event is InputEventMouseButton:
		_usa_mando = false
	else:
		return
	if not diario._en_dialogo:
		_actualizar_textos()

func _control(accion: StringName) -> String:
	return preload("res://scripts/ui/input_hints.gd").accion(accion, _usa_mando)

func _actualizar_textos() -> void:
	var movimiento := "%s / %s / %s / %s" % [
		_control(&"move_up"), _control(&"move_left"), _control(&"move_down"), _control(&"move_right")]
	var interactuar := _control(&"interact")
	diario.cambiar_lineas_rapidas([
		"Primer día en la casa nueva. Todavía quedan cajas por abrir.",
		"Para moverte: %s." % movimiento,
		"Acércate a personas y objetos. Para interactuar: %s." % interactuar,
		"Puedes abrir el inventario y consultar tus estadísticas desde la pausa: %s." % _control(&"pause"),
		"Papá está abajo. Antes de salir, pasaré a saludarlo."
	])
	_actualizar_indicador(diario, "%s · Leer diario" % interactuar)
	_actualizar_indicador(padre, "%s · Hablar" % interactuar)
	pista.text = "Lee el diario sobre la mesa antes de bajar.\nMover: %s\nInteractuar: %s" % [movimiento, interactuar]

func _actualizar_indicador(dialogo: InteraccionDialogo, texto: String) -> void:
	dialogo.texto_indicador = texto
	if is_instance_valid(dialogo._indicador_label):
		dialogo._indicador_label.text = texto

func recordar_diario() -> void:
	if not GameState.tiene_progreso(GameState.PROGRESO_TUTORIAL_DIARIO):
		pista.show()

func _terminar_diario() -> void:
	# No registrar progreso si el proveedor no pudo crear el diálogo.
	if diario._recurso_generado_cache == null:
		return
	GameState.reclamar_unico(GameState.PROGRESO_TUTORIAL_DIARIO)
	_liberar_referencias_dialogo(diario)
	diario.desactivar()
	pista.hide()

func _terminar_charla() -> void:
	if padre._recurso_generado_cache == null:
		return
	GameState.reclamar_unico(GameState.PROGRESO_CHARLA_PROGENITOR)
	_liberar_referencias_dialogo(padre)
	padre.cambiar_lineas_rapidas(["Abrígate bien. Estaré aquí si necesitas volver a casa."])

## El addon inyecta el propio recurso en cada línea leída; romper ese ciclo
## únicamente en los recursos rápidos privados de esta casa, al terminar.
func _liberar_referencias_dialogo(dialogo: InteraccionDialogo) -> void:
	var recurso := dialogo._recurso_generado_cache
	if recurso:
		for linea in recurso.lines.values():
			if linea is Dictionary and linea.get(&"resource") == recurso:
				linea.erase(&"resource")

func _configurar_ayuda() -> void:
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0.04, 0.06, 0.09, 0.85)
	fondo.content_margin_left = 12
	fondo.content_margin_right = 12
	fondo.content_margin_top = 8
	fondo.content_margin_bottom = 8
	pista.add_theme_stylebox_override("normal", fondo)
	pista.add_theme_font_size_override("font_size", 17)
	pista.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	get_viewport().size_changed.connect(_ajustar_ayuda)
	_ajustar_ayuda()

func _ajustar_ayuda() -> void:
	$Ayuda/Margen.offset_right = minf(590, get_viewport().get_visible_rect().size.x - 24)
