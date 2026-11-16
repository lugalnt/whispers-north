extends Node3D

@onready var _jarrito: CharacterBody3D = $Jarrito
@onready var _estado: Label = $CanvasLayer/Estado


func _ready() -> void:
	_jarrito.connect("estado_cambiado", _al_cambiar_estado)
	_jarrito.connect("inicio_combate", _al_iniciar_combate)


func _al_cambiar_estado(estado_actual: int) -> void:
	var nombres: PackedStringArray = PackedStringArray(["Idle", "Alert", "Walk", "Encounter"])
	_estado.text = "Jarrito: %s" % nombres[estado_actual]


func _al_iniciar_combate(_protagonista: CharacterBody3D) -> void:
	_estado.text = "Reserva confirmada: combate iniciado. Al terminar, Jarrito vuelve a Idle."
