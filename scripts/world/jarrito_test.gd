extends Node3D

@onready var _jarrito: CharacterBody3D = $Jarrito
@onready var _estado: Label = $CanvasLayer/Estado
var _lbl_radio: Label


func _ready() -> void:
	_jarrito.connect("estado_cambiado", _al_cambiar_estado)
	_jarrito.connect("inicio_combate", _al_iniciar_combate)
	_crear_slider_deteccion()


func _crear_slider_deteccion() -> void:
	var hud := get_node_or_null("CanvasLayer") as CanvasLayer
	if hud == null:
		return
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 96)
	panel.focus_mode = Control.FOCUS_NONE
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	_lbl_radio = Label.new()
	_lbl_radio.text = "Radio de detección: %.2f m" % _jarrito.radio_deteccion
	vbox.add_child(_lbl_radio)

	var slider := HSlider.new()
	slider.name = "SliderRadioDeteccion"
	slider.custom_minimum_size = Vector2(260, 24)
	slider.min_value = 0.5
	slider.max_value = 15.0
	slider.step = 0.25
	slider.value = _jarrito.radio_deteccion
	slider.focus_mode = Control.FOCUS_NONE
	slider.value_changed.connect(_al_cambiar_radio)
	vbox.add_child(slider)
	hud.add_child(panel)


func _al_cambiar_radio(nuevo_radio: float) -> void:
	if _lbl_radio:
		_lbl_radio.text = "Radio de detección: %.2f m" % nuevo_radio
	for nodo in find_children("*", "CharacterBody3D", true, false):
		if nodo is Jarrito:
			nodo.radio_deteccion = nuevo_radio
			nodo.distancia_perdida = maxf(nodo.distancia_perdida, nuevo_radio * 2.0)


func _al_cambiar_estado(estado_actual: int) -> void:
	var nombres: PackedStringArray = PackedStringArray(["Idle", "Alert", "Walk", "Encounter", "Return"])
	var texto: String = nombres[estado_actual] if estado_actual >= 0 and estado_actual < nombres.size() else str(estado_actual)
	_estado.text = "Jarrito: %s" % texto


func _al_iniciar_combate(_protagonista: CharacterBody3D) -> void:
	_estado.text = "Reserva confirmada: combate iniciado. Al terminar, Jarrito vuelve a Idle."
