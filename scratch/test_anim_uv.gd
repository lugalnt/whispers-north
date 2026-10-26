extends SceneTree

func _init() -> void:
	print("--- TESTING ANIMATIONPLAYER UV SCROLL ON MESH SURFACE MATERIAL OVERRIDE ---")
	var root_node = Node3D.new()
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.name = "FountainMesh"
	root_node.add_child(mesh_inst)
	
	# Load or create a material for surface 4
	var mat_water = StandardMaterial3D.new()
	mat_water.resource_name = "mat_water"
	mat_water.uv1_offset = Vector3.ZERO
	mesh_inst.set_surface_override_material(0, mat_water)
	
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	root_node.add_child(anim_player)
	
	var anim = Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "FountainMesh:surface_material_override/0:uv1_offset")
	anim.track_insert_key(track_idx, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(track_idx, 1.0, Vector3(0, -1, 0))
	
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("flow", anim)
	anim_player.add_animation_library("", anim_lib)
	anim_player.autoplay = "flow"
	
	# Test seeking
	anim_player.play("flow")
	anim_player.advance(0.5)
	print("At 0.5s, mat_water uv1_offset = ", mat_water.uv1_offset)
	if is_equal_approx(mat_water.uv1_offset.y, -0.5):
		print("[SUCCESS] AnimationPlayer correctly animates surface_material_override uv1_offset!")
	else:
		print("[FAILED] uv1_offset not expected: ", mat_water.uv1_offset)
	
	root_node.free()
	quit(0)
