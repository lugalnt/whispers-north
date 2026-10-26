extends SceneTree

func _init() -> void:
	var dae_scene = load("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/c03_fountain_01.dae") as PackedScene
	var inst = dae_scene.instantiate()
	var mesh_inst: MeshInstance3D = inst.find_child("c03_fountain_01", true, false)
	var mesh: ArrayMesh = mesh_inst.mesh.duplicate(true)
	
	var save_path = "res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/fountain_mesh.res"
	var err = ResourceSaver.save(mesh, save_path)
	print("Save result: ", err)
	
	var loaded_mesh = load(save_path) as ArrayMesh
	if loaded_mesh and loaded_mesh.get_surface_count() == 7:
		print("[SUCCESS] fountain_mesh.res saved and reloaded cleanly with 7 surfaces!")
	else:
		print("[FAIL] Failed to reload mesh")
	
	inst.free()
	quit(0)
