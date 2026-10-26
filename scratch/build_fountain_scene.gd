extends SceneTree

func _init() -> void:
	print("--- BUILDING FOUNTAIN SCENE ---")
	var base_path = "res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/"
	var mat_dir = base_path + "materials/"
	
	var fountain = StaticBody3D.new()
	fountain.name = "Fountain"
	
	# Collision shape
	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cyl = CylinderShape3D.new()
	cyl.radius = 4.0
	cyl.height = 2.0
	col.shape = cyl
	col.position = Vector3(0, 1.0, 0)
	fountain.add_child(col)
	col.owner = fountain
	
	# Visual node
	var visual = Node3D.new()
	visual.name = "Visual"
	visual.scale = Vector3(0.08, 0.08, 0.08)
	fountain.add_child(visual)
	visual.owner = fountain
	
	# Mesh instance
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "FountainMesh"
	var mesh = load(base_path + "fountain_mesh.res") as ArrayMesh
	mesh_inst.mesh = mesh
	
	var mat_files = [
		"mat_shadow.tres",
		"mat_water_rim.tres",
		"mat_basin_floor.tres",
		"mat_water_pool.tres",
		"mat_water_stream.tres",
		"mat_stone_base.tres",
		"mat_stone_trim.tres"
	]
	
	for i in range(mat_files.size()):
		var mat = load(mat_dir + mat_files[i]) as Material
		mesh_inst.set_surface_override_material(i, mat)
	
	visual.add_child(mesh_inst)
	mesh_inst.owner = fountain
	
	# AnimationPlayer
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	fountain.add_child(anim_player)
	anim_player.owner = fountain
	
	var anim = Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Track for water stream (surface 4)
	var t0 = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t0, "Visual/FountainMesh:surface_material_override/4:uv1_offset")
	anim.track_insert_key(t0, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t0, 1.0, Vector3(0, -1, 0))
	
	# Track for water pool (surface 3)
	var t1 = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t1, "Visual/FountainMesh:surface_material_override/3:uv1_offset")
	anim.track_insert_key(t1, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t1, 1.0, Vector3(0.5, 0.5, 0))
	
	# Track for water rim (surface 1)
	var t2 = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(t2, "Visual/FountainMesh:surface_material_override/1:uv1_offset")
	anim.track_insert_key(t2, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(t2, 1.0, Vector3(0, -1, 0))
	
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("flow", anim)
	anim_player.add_animation_library("", anim_lib)
	anim_player.autoplay = "flow"
	
	# Audio player
	var audio = AudioStreamPlayer3D.new()
	audio.name = "AudioStreamPlayer3D"
	audio.unit_size = 10.0
	audio.max_distance = 25.0
	audio.bus = &"SFX"
	fountain.add_child(audio)
	audio.owner = fountain
	
	# Pack scene
	var packed = PackedScene.new()
	var pack_err = packed.pack(fountain)
	print("Pack error: ", pack_err)
	var save_err = ResourceSaver.save(packed, "res://scenes/world/Entities/Fountain.tscn")
	print("Save scene error: ", save_err)
	
	fountain.free()
	quit(0)
