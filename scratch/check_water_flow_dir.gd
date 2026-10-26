extends SceneTree

func _init() -> void:
	var dae_scene = load("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/c03_fountain_01.dae") as PackedScene
	var inst = dae_scene.instantiate()
	var mesh_inst: MeshInstance3D = inst.find_child("c03_fountain_01", true, false)
	var mesh = mesh_inst.mesh
	
	var arrays = mesh.surface_get_arrays(4)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	
	print("--- CORRELATING VERTEX Y WITH UV V ---")
	# Sample pairs of (vertex.y, uv.y)
	for i in range(min(20, verts.size())):
		print("v[", i, "] Y=", verts[i].y, " -> UV=", uvs[i])
	
	# Compute correlation between vertex Y and UV Y
	var sum_dy = 0.0
	var sum_duv = 0.0
	var count = 0
	for i in range(0, verts.size() - 1, 2):
		var dy = verts[i+1].y - verts[i].y
		var duv = uvs[i+1].y - uvs[i].y
		if abs(dy) > 0.1:
			# print("dy=", dy, " duv=", duv, " ratio=", duv / dy)
			count += 1
	
	inst.free()
	quit(0)
