extends SceneTree

func _initialize() -> void:
	var models = {
		"cianwood": "res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Cianwood City House/Cianwood City House.obj",
		"violet": "res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Violet City House/Violet City House.obj",
		"pastoria": "res://assets/models/placeholder houses/DS _ DSi - Pokemon Platinum - Map Objects - Pastoria City House/Pastoria City House.obj"
	}
	
	var scale_factor = 0.08
	
	for name in models:
		var m: Mesh = load(models[name]) as Mesh
		var aabb = m.get_aabb()
		print("--- " + name + " ---")
		print("Raw AABB: ", aabb)
		# Scaled AABB
		var scaled_size = aabb.size * scale_factor
		var scaled_pos = aabb.position * scale_factor
		var scaled_center = aabb.get_center() * scale_factor
		print("Scaled Size: ", scaled_size)
		print("Scaled Center: ", scaled_center)
		# If we offset mesh so min.y is at 0:
		# mesh.position.y = -aabb.position.y * scale_factor
		var offset_y = -aabb.position.y * scale_factor
		print("Offset to put base at Y=0: mesh.position = Vector3(0, %f, 0)" % offset_y)
		# Center in X and Z:
		var offset_x = -aabb.get_center().x * scale_factor
		var offset_z = -aabb.get_center().z * scale_factor
		print("Offset to center X and Z at 0: mesh.position = Vector3(%f, %f, %f)" % [offset_x, offset_y, offset_z])
	quit(0)
