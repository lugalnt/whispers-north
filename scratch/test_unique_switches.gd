@tool
extends SceneTree

func _init() -> void:
	print("==================================================")
	print("TEST: VERIFICACIÓN DE SWITCHES ÚNICOS EN WORLD_TOWN")
	print("==================================================")
	
	var town_scene: PackedScene = load("res://scenes/world/World_Town.tscn")
	assert(town_scene != null, "World_Town.tscn debe cargar correctamente")
	
	var town = town_scene.instantiate()
	assert(town != null, "World_Town debe instanciarse")
	
	var switches_parent = town.get_node_or_null("Switches")
	assert(switches_parent != null, "Nodo Switches debe existir en World_Town")
	
	var switches = switches_parent.get_children()
	print("Cantidad de switches encontrados: %d" % switches.size())
	assert(switches.size() == 11, "Deben haber exactamente 11 switches en World_Town")
	
	var shape_rids: Dictionary = {}
	var sizes_used: Dictionary = {}
	
	for sw in switches:
		assert(sw is Area3D, "El switch %s debe ser Area3D" % sw.name)
		var col = sw.get_node_or_null("CollisionShape3D") as CollisionShape3D
		assert(col != null, "El switch %s debe tener CollisionShape3D" % sw.name)
		assert(col.shape != null, "El switch %s debe tener forma de colisión" % sw.name)
		
		var shape_id = col.shape.get_instance_id()
		print("Switch: %-12s | Trigger: %-22s | Shape Size: %-22s | Shape ID: %d | Local: %s" % [
			sw.name,
			str(sw.tamano_trigger),
			str(col.shape.size),
			shape_id,
			str(col.shape.resource_local_to_scene)
		])
		
		# 1. Comprobar que resource_local_to_scene es true
		assert(col.shape.resource_local_to_scene, "Shape de %s debe ser resource_local_to_scene" % sw.name)
		
		# 2. Comprobar que el tamaño del shape coincide con tamano_trigger
		assert(col.shape.size.is_equal_approx(sw.tamano_trigger), "El shape de %s debe coincidir con tamano_trigger" % sw.name)
		
		# 3. Comprobar que el shape es una instancia ÚNICA en memoria (ningún otro switch lo comparte)
		assert(not shape_rids.has(shape_id), "ERROR: El shape ID %d está compartido entre %s y %s!" % [shape_id, sw.name, shape_rids.get(shape_id, "")])
		shape_rids[shape_id] = sw.name
		
		# 4. Comprobar que cada switch tiene un tamaño único asignado en esta escena
		var size_key = "%.1f_%.1f_%.1f" % [sw.tamano_trigger.x, sw.tamano_trigger.y, sw.tamano_trigger.z]
		assert(not sizes_used.has(size_key), "ERROR: Tamaño duplicado en %s (ya usado por %s)" % [sw.name, sizes_used.get(size_key, "")])
		sizes_used[size_key] = sw.name
	
	print("\n>>> Probando desacoplamiento e independencia: mutando Switch_1_2...")
	var sw1 = switches_parent.get_node("Switch_1_2")
	var sw2 = switches_parent.get_node("Switch_2_3")
	var sw2_size_orig = sw2.tamano_trigger
	var sw2_shape_size_orig = (sw2.get_node("CollisionShape3D") as CollisionShape3D).shape.size
	
	sw1.tamano_trigger = Vector3(99.0, 44.0, 33.0)
	var sw1_col = sw1.get_node("CollisionShape3D") as CollisionShape3D
	assert(sw1_col.shape.size.is_equal_approx(Vector3(99.0, 44.0, 33.0)), "Switch_1_2 debió actualizar su shape")
	
	assert(sw2.tamano_trigger.is_equal_approx(sw2_size_orig), "Switch_2_3 no debe haber sido afectado por Switch_1_2")
	assert((sw2.get_node("CollisionShape3D") as CollisionShape3D).shape.size.is_equal_approx(sw2_shape_size_orig), "El shape de Switch_2_3 no debe haber cambiado")
	print(">>> DESACOPLAMIENTO VERIFICADO CON ÉXITO: Modificar un switch no altera a los demás.")
	
	town.free()
	print("\n==================================================")
	print("TODAS LAS PRUEBAS PASARON EXITOSAMENTE (100% OK)")
	print("==================================================")
	quit(0)
