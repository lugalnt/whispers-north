extends SceneTree

func _init() -> void:
	var dae_scene = load("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/c03_fountain_01.dae") as PackedScene
	var inst = dae_scene.instantiate()
	var mesh_inst: MeshInstance3D = inst.find_child("c03_fountain_01", true, false)
	var mesh = mesh_inst.mesh
	
	print("--- DETAILED Y LEVELS OF FOUNTAIN ---")
	var s5_arrays = mesh.surface_get_arrays(5)
	var s5_verts: PackedVector3Array = s5_arrays[Mesh.ARRAY_VERTEX]
	var y_levels = {}
	for v in s5_verts:
		var y_rounded = snappedf(v.y, 0.1)
		y_levels[y_rounded] = y_levels.get(y_rounded, 0) + 1
	var sorted_ys = y_levels.keys()
	sorted_ys.sort()
	for y in sorted_ys:
		print("  Y = ", y, " (", y * 0.08, "m at scale 0.08): ", y_levels[y], " verts")
	
	inst.free()
	quit(0)
