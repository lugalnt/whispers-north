extends SceneTree

const CameraSwitchScript = preload("res://scripts/world/camera_switch.gd")
const CameraSwitchManagerScript = preload("res://scripts/world/camera_switch_manager.gd")

func _initialize() -> void:
	print("--- INICIANDO TEST CAMERA SWITCH & MANAGER ---")
	
	# 1. Crear escena mock
	var root_node = Node3D.new()
	root_node.name = "WorldMock"
	root.add_child(root_node)
	current_scene = root_node
	await process_frame
	
	# 2. Crear contenedor de cámaras con Camera1 y Camera2
	var cameras_container = Node3D.new()
	cameras_container.name = "Cameras"
	root_node.add_child(cameras_container)
	
	var cam1 = Camera3D.new()
	cam1.name = "Camera1"
	cam1.position = Vector3(0, 5, 0)
	cameras_container.add_child(cam1)
	
	var cam2 = Camera3D.new()
	cam2.name = "Camera2"
	cam2.position = Vector3(20, 5, 0)
	cameras_container.add_child(cam2)
	
	# Cam1 activa por defecto
	cam1.make_current()
	assert(cam1.current == true, "Camera1 debe estar activa")
	assert(cam2.current == false, "Camera2 debe estar inactiva")
	print("PASS: Setup de cámaras inicializado.")
	
	# 3. Instanciar CameraSwitch desde prefab
	var switch_prefab = load("res://scenes/world/Entities/CameraSwitch.tscn")
	assert(switch_prefab != null, "Prefab CameraSwitch.tscn debe existir")
	
	var switch_inst = switch_prefab.instantiate()
	switch_inst.name = "Switch_1_2"
	switch_inst.camara_a_num = 1
	switch_inst.camara_b_num = 2
	root_node.add_child(switch_inst)
	await process_frame
	
	# 4. Verificar resolución de cámaras
	var res_a = switch_inst._resolver_camara(null, 1)
	var res_b = switch_inst._resolver_camara(null, 2)
	assert(res_a == cam1, "Debe resolver Camera1 dentro de Cameras/")
	assert(res_b == cam2, "Debe resolver Camera2 dentro de Cameras/")
	print("PASS: Resolución automática de cámaras en contenedor Cameras/ funciona.")
	
	# 5. Probar centrado automático entre cámaras
	switch_inst._auto_centrar_entre_camaras()
	print("Posición tras centrar: ", switch_inst.global_position)
	assert(abs(switch_inst.global_position.x - 10.0) < 0.01, "La posición X debe ser 10.0 (punto medio entre 0 y 20)")
	print("PASS: Auto-centrado entre cámaras verificado (X = 10.0).")
	
	# 6. Probar simulación de cruce del jugador
	var player = CharacterBody3D.new()
	player.name = "Player"
	player.add_to_group("player")
	root_node.add_child(player)
	
	# El jugador entra al switch (modo alternar)
	switch_inst._on_body_entered(player)
	assert(cam2.current == true, "Camera2 debe ser la activa tras cruzar de 1 hacia 2")
	assert(cam1.current == false, "Camera1 debe haber quedado inactiva")
	print("PASS: Alternancia 1 -> 2 exitosa.")
	
	# Verificar cooldown inmediato
	switch_inst._on_body_entered(player)
	assert(cam2.current == true, "Cooldown debe prevenir cambio instantáneo en el mismo tick")
	print("PASS: Cooldown / debounce previene parpadeo.")
	
	# Simular paso del tiempo (> 0.3s)
	switch_inst._ultimo_tiempo_cambio -= 0.5
	switch_inst._on_body_entered(player)
	assert(cam1.current == true, "Camera1 debe reactivarse al cruzar de vuelta")
	print("PASS: Alternancia 2 -> 1 exitosa.")
	
	# 7. Probar CameraSwitchManager
	var manager = CameraSwitchManagerScript.new()
	manager.name = "Switches"
	root_node.add_child(manager)
	
	# Crear un switch 2-1
	var nuevo_switch = manager.crear_switch(2, 1)
	assert(nuevo_switch != null, "Manager debe instanciar el switch")
	assert(manager.has_node("Switch_2_1"), "Manager debe tener el hijo Switch_2_1")
	print("PASS: CameraSwitchManager crea e inicializa switches correctamente.")
	
	print("--- TODOS LOS TESTS DE CAMERA SWITCH PASARON EXITOSAMENTE ---")
	quit(0)
