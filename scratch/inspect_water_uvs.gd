extends SceneTree

func _init() -> void:
	print("--- INSPECTING WATER MESH & UVs ---")
	var dae_scene = load("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/c03_fountain_01.dae") as PackedScene
	var inst = dae_scene.instantiate()
	var mesh_inst: MeshInstance3D = inst.find_child("c03_fountain_01", true, false)
	if mesh_inst and mesh_inst.mesh:
		var mesh = mesh_inst.mesh
		print("AABB: ", mesh.get_aabb())
		for i in range(mesh.get_surface_count()):
			var mat = mesh.surface_get_material(i)
			var mat_name = mat.resource_name if mat else "unknown"
			var arrays = mesh.surface_get_arrays(i)
			var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			print("Surface ", i, " (", mat_name, "): ", verts.size(), " verts")
			if mat_name == "hunsui_water" or i == 4:
				# Check bounding box of water
				var min_v = Vector3(999, 999, 999)
				var max_v = Vector3(-999, -999, -999)
				for v in verts:
					min_v = min_v.min(v)
					max_v = max_v.max(v)
				print("  Water Bounding Box: min=", min_v, " max=", max_v)
				if uvs.size() > 0:
					var min_uv = Vector2(999, 999)
					var max_uv = Vector2(-999, -999)
					for uv in uvs:
						min_uv = min_uv.min(uv)
						max_uv = max_uv.max(uv)
					print("  Water UV range: min=", min_uv, " max=", max_uv)
					print("  Sample UVs: ", uvs.slice(0, 8))
	inst.free()
	quit(0)
