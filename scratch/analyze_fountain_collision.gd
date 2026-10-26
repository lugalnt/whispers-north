extends SceneTree

func _init() -> void:
	var dae_scene = load("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/c03_fountain_01.dae") as PackedScene
	var inst = dae_scene.instantiate()
	var mesh_inst: MeshInstance3D = inst.find_child("c03_fountain_01", true, false)
	var mesh = mesh_inst.mesh
	
	# Overall AABB
	var aabb = mesh.get_aabb()
	print("Mesh AABB: ", aabb)
	print("Center XZ: ", Vector2(aabb.position.x + aabb.size.x / 2.0, aabb.position.z + aabb.size.z / 2.0))
	print("Bottom Y: ", aabb.position.y)
	print("Top Y: ", aabb.position.y + aabb.size.y)
	
	# Check surface 5 (base stone)
	var s5_arrays = mesh.surface_get_arrays(5)
	var s5_verts: PackedVector3Array = s5_arrays[Mesh.ARRAY_VERTEX]
	var s5_max_r = 0.0
	for v in s5_verts:
		var r = Vector2(v.x, v.z).length()
		if r > s5_max_r:
			s5_max_r = r
	print("Base stone max radius in original units: ", s5_max_r)
	print("Base stone max radius at 0.08 scale: ", s5_max_r * 0.08, " meters (diameter ~", s5_max_r * 0.16, "m)")
	
	inst.free()
	quit(0)
