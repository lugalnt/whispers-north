extends Node3D

# Referencias a los nodos de personaje en la escena
@onready var player_16: CharacterBody3D = $Player
@onready var player_32: CharacterBody3D = $Player32 

func _ready() -> void:
	_setup_camera_switches()
	# Los controles (move_*, interact) se definen en Project Settings > Input Map
	# El juego empieza solo con el personaje de 16x16 activo
	player_32.hide() 
	player_32.process_mode = Node.PROCESS_MODE_DISABLED 

# --- Sistema de cámaras ---
# Cada Area3D llamada "SwitchC_A_B" alterna entre Camera<A> y Camera<B> cuando el jugador la cruza.
func _setup_camera_switches() -> void:
	var cam_1: Camera3D = get_node_or_null("Camera1")
	if cam_1:
		cam_1.make_current()
	
	for zone in find_children("SwitchC_*", "Area3D", true, false):
		var parts: PackedStringArray = zone.name.split("_")
		if parts.size() != 3 or not parts[1].is_valid_int() or not parts[2].is_valid_int():
			push_warning("Nombre de zona de cámara inválido (usa SwitchC_A_B): " + zone.name)
			continue
		
		var cam_a: Camera3D = get_node_or_null("Camera" + parts[1])
		var cam_b: Camera3D = get_node_or_null("Camera" + parts[2])
		if cam_a == null or cam_b == null:
			push_warning("La zona %s referencia una cámara que no existe" % zone.name)
			continue
		
		zone.body_entered.connect(_on_camera_switch_entered.bind(cam_a, cam_b))

# Alterna entre las dos cámaras de la zona (solo reacciona al jugador activo)
func _on_camera_switch_entered(body: Node3D, cam_a: Camera3D, cam_b: Camera3D) -> void:
	if body != get_active_player():
		return
	if cam_a.current:
		cam_b.make_current()
	elif cam_b.current:
		cam_a.make_current()

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
