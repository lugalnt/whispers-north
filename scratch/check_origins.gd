extends SceneTree

func _initialize() -> void:
	var paths = [
		"res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Cianwood City House/Cianwood City House.obj",
		"res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Violet City House/Violet City House.obj",
		"res://assets/models/placeholder houses/DS _ DSi - Pokemon Platinum - Map Objects - Pastoria City House/Pastoria City House.obj"
	]
	
	for p in paths:
		print("====================================")
		print("Model: ", p.get_file())
		var mesh: Mesh = load(p) as Mesh
		var aabb = mesh.get_aabb()
		print("AABB: min=", aabb.position, " max=", aabb.end, " size=", aabb.size)
		print("Origin Y offset from bottom: ", -aabb.position.y)
		for s in range(mesh.get_surface_count()):
			var mat: Material = mesh.surface_get_material(s)
			if mat is StandardMaterial3D:
				var sm: StandardMaterial3D = mat as StandardMaterial3D
				print("  Surface ", s, " (", sm.resource_name, "):")
				print("    albedo_color: ", sm.albedo_color)
				print("    transparency: ", sm.transparency)
				print("    cull_mode: ", sm.cull_mode)
				print("    texture: ", sm.albedo_texture.resource_path if sm.albedo_texture else "none")
	quit(0)
