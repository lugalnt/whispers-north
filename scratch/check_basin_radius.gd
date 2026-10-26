extends SceneTree

func _init() -> void:
	var dae_scene = load("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/c03_fountain_01.dae") as PackedScene
	var inst = dae_scene.instantiate()
	var mesh_inst: MeshInstance3D = inst.find_child("c03_fountain_01", true, false)
	var mesh = mesh_inst.mesh
	var s5_arrays = mesh.surface_get_arrays(5)
	var s5_verts: PackedVector3Array = s5_arrays[Mesh.ARRAY_VERTEX]
	
	var r_at_y25 = []
	for v in s5_verts:
		if abs(v.y - 25.0) < 0.5:
			r_at_y25.append(Vector2(v.x, v.z).length())
	r_at_y25.sort()
	print("Radius at Y=25: min=", r_at_y25[0], " max=", r_at_y25[-1])
	print("In meters at scale 0.08: min=", r_at_y25[0] * 0.08, "m, max=", r_at_y25[-1] * 0.08, "m")
	
	inst.free()
	quit(0)
