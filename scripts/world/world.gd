extends Node3D

# Referencias a los nodos de personaje en la escena
@onready var player_16: CharacterBody3D = $Player
@onready var player_32: CharacterBody3D = $Player32 

func _ready() -> void:
	# Asegura que la tecla 'Z' esté mapeada a la acción 'ui_accept'
	_setup_input_map()
	# El juego empieza solo con el personaje de 16x16 activo
	player_32.hide() 
	player_32.process_mode = Node.PROCESS_MODE_DISABLED 

# Configura la tecla 'Z' como evento de la acción ui_accept si no está configurada
func _setup_input_map() -> void:
	if not InputMap.has_action("ui_accept"):
		InputMap.add_action("ui_accept")
	
	var events = InputMap.action_get_events("ui_accept")
	var tiene_z: bool = false
	for ev in events:
		if ev is InputEventKey and ev.keycode == KEY_Z:
			tiene_z = true
			break
			
	if not tiene_z:
		var key_z = InputEventKey.new()
		key_z.keycode = KEY_Z
		InputMap.action_add_event("ui_accept", key_z)

# Devuelve el nodo del jugador activo (16x16 o 32x32)
func get_active_player() -> CharacterBody3D:
	if player_16 and player_16.visible:
		return player_16
	return player_32

# Alterna entre el personaje de 16x16 y el de 32x32
func toggle_player_character() -> void:
	if player_16.visible:
		cambiar_personaje(player_16, player_32)
	else:
		cambiar_personaje(player_32, player_16)

# Función que apaga al personaje actual y enciende al nuevo
func cambiar_personaje(personaje_viejo: CharacterBody3D, personaje_nuevo: CharacterBody3D) -> void:
	# Teletransporta al nuevo exactamente a donde estaba parado el viejo
	personaje_nuevo.global_position = personaje_viejo.global_position
	
	# Mueve elementos anclados (como la Rata en la cabeza) del viejo al nuevo personaje
	for child in personaje_viejo.get_children():
		if child.name.begins_with("Rat") or child.is_in_group("rat"):
			child.reparent(personaje_nuevo)
			child.position = Vector3(0, 1.2, 0)
	
	# Apaga físicas y visibilidad del viejo
	personaje_viejo.hide()
	personaje_viejo.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Enciende físicas y visibilidad del nuevo
	personaje_nuevo.show()
	personaje_nuevo.process_mode = Node.PROCESS_MODE_INHERIT
