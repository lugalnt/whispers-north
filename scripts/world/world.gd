extends Node3D

# Conectamos ambos nodos. Asegúrate de que los nombres coincidan con los de tu panel izquierdo.
@onready var player_16 = $Player
@onready var player_32 = $Player32 

func _ready():
	# El juego empieza solo con el personaje de 16x16 activo
	player_32.hide() 
	player_32.process_mode = Node.PROCESS_MODE_DISABLED 

func _process(_delta):
	# ui_accept por defecto es la barra espaciadora o la tecla Enter
	if Input.is_action_just_pressed("ui_accept"):
		if player_16.visible:
			cambiar_personaje(player_16, player_32)
		else:
			cambiar_personaje(player_32, player_16)

# Función que apaga al personaje actual y enciende al nuevo
func cambiar_personaje(personaje_viejo, personaje_nuevo):
	# Teletransporta al nuevo exactamente a donde estaba parado el viejo
	personaje_nuevo.global_position = personaje_viejo.global_position
	
	# Apaga físicas y visibilidad del viejo
	personaje_viejo.hide()
	personaje_viejo.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Enciende físicas y visibilidad del nuevo
	personaje_nuevo.show()
	personaje_nuevo.process_mode = Node.PROCESS_MODE_INHERIT
