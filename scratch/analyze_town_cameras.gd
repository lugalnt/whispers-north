extends SceneTree

func _init() -> void:
	print("--- ANALYZING WORLD_TOWN CAMERAS ---")
	var town_scene = load("res://scenes/world/World_Town.tscn") as PackedScene
	var inst = town_scene.instantiate()
	var cameras_node = inst.get_node_or_null("Cameras")
	if cameras_node:
		print("Cameras container found with ", cameras_node.get_child_count(), " children:")
		for c in cameras_node.get_children():
			if c is Camera3D:
				print("  ", c.name, " pos: ", c.global_position, " rot: ", c.rotation_degrees)
	else:
		print("No 'Cameras' container found!")
	inst.free()
	quit(0)
