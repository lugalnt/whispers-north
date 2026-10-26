@tool
extends SceneTree

func _init() -> void:
	var town_scene: PackedScene = load("res://scenes/world/World_Town.tscn")
	var town = town_scene.instantiate()
	var switches = town.get_node_or_null("Switches")
	var cameras = town.get_node_or_null("Cameras")
	
	print("=== TOWN SWITCHES & CAMERAS ===")
	if cameras:
		for cam in cameras.get_children():
			print("CAM ", cam.name, " -> pos: ", cam.global_position)
	
	if switches:
		for sw in switches.get_children():
			print("SWITCH: ", sw.name)
			print("   pos: ", sw.position)
			print("   rot: ", sw.rotation_degrees)
			print("   scale: ", sw.scale)
			print("   cam_a: ", sw.camara_a_num, " cam_b: ", sw.camara_b_num)
			var col = sw.get_node_or_null("CollisionShape3D") as CollisionShape3D
			if col and col.shape:
				print("   shape size: ", col.shape.size, " local_to_scene: ", col.shape.resource_local_to_scene)
	town.free()
	quit(0)
