extends SceneTree

func _init() -> void:
	var dae_scene = load("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/c03_fountain_01.dae") as PackedScene
	var inst = dae_scene.instantiate()
	var mesh_inst: MeshInstance3D = inst.find_child("c03_fountain_01", true, false)
	var mesh = mesh_inst.mesh
	
	print("--- SURFACE BREAKDOWN ---")
	for i in range(mesh.get_surface_count()):
		var mat = mesh.surface_get_material(i)
		var arrays = mesh.surface_get_arrays(i)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var min_v = Vector3(9999, 9999, 9999)
		var max_v = Vector3(-9999, -9999, -9999)
		for v in verts:
			min_v = min_v.min(v)
			max_v = max_v.max(v)
		print("Surface ", i, " [", mat.resource_name, "]:")
		print("  Verts: ", verts.size(), " Triangles: ", verts.size() / 3)
		print("  Bounds: min=", min_v, " max=", max_v, " size=", max_v - min_v)
	
	inst.free()
	quit(0)
