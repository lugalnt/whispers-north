extends SceneTree

func _init() -> void:
	print("--- TESTING ACTUAL FOUNTAIN MESH ANIMATION ---")
	var dae_scene = load("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/c03_fountain_01.dae") as PackedScene
	var inst = dae_scene.instantiate()
	var mesh_inst: MeshInstance3D = inst.find_child("c03_fountain_01", true, false)
	
	var mat_water = StandardMaterial3D.new()
	mat_water.resource_name = "mat_water"
	mesh_inst.set_surface_override_material(4, mat_water)
	
	var anim_player = inst.find_child("AnimationPlayer", true, false)
	if anim_player == null:
		anim_player = AnimationPlayer.new()
		inst.add_child(anim_player)
	
	var anim = Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	# Path relative to AnimationPlayer parent
	var rel_path = anim_player.get_parent().get_path_to(mesh_inst)
	print("Relative path from anim_player parent to mesh: ", rel_path)
	
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	var prop_path = str(rel_path) + ":surface_material_override/4:uv1_offset"
	print("Testing track path: ", prop_path)
	anim.track_set_path(track_idx, prop_path)
	anim.track_insert_key(track_idx, 0.0, Vector3(0, 0, 0))
	anim.track_insert_key(track_idx, 1.0, Vector3(0, -1, 0))
	
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("flow", anim)
	anim_player.add_animation_library("", anim_lib)
	anim_player.play("flow")
	anim_player.advance(0.5)
	
	print("At 0.5s, mat_water uv1_offset = ", mat_water.uv1_offset)
	if is_equal_approx(mat_water.uv1_offset.y, -0.5):
		print("[SUCCESS] AnimationPlayer correctly animated surface_material_override/4:uv1_offset!")
	else:
		print("[FAILED] uv1_offset: ", mat_water.uv1_offset)
	
	inst.free()
	quit(0)
