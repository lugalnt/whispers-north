extends SceneTree

func _initialize() -> void:
	print("--- INSPECTING HOUSES ---")
	var paths = [
		"res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Cianwood City House/Cianwood City House.obj",
		"res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Violet City House/Violet City House.obj",
		"res://assets/models/placeholder houses/DS _ DSi - Pokemon Platinum - Map Objects - Pastoria City House/Pastoria City House.obj"
	]
	
	for p in paths:
		print("\nChecking: ", p)
		var mesh: Mesh = load(p) as Mesh
		if mesh:
			print("Mesh loaded successfully: ", mesh.get_class())
			print("Surfaces count: ", mesh.get_surface_count())
			print("AABB: ", mesh.get_aabb())
			print("AABB size: ", mesh.get_aabb().size)
			for i in range(mesh.get_surface_count()):
				var mat = mesh.surface_get_material(i)
				var mat_name = mesh.get("surface_%d/name" % i)
				print("  Surface %d: mat = %s" % [i, mat])
				if mat is StandardMaterial3D:
					print("    Albedo texture: ", mat.albedo_texture)
		else:
			print("Failed to load mesh!")
	
	quit(0)
