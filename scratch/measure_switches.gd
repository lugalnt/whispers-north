@tool
extends SceneTree

func _init() -> void:
	var town_scene: PackedScene = load("res://scenes/world/World_Town.tscn")
	var town = town_scene.instantiate()
	var switches = town.get_node_or_null("Switches")
	var cameras = town.get_node_or_null("Cameras")
	
	for sw in switches.get_children():
		var cam_a = cameras.get_node_or_null("Camera%d" % sw.camara_a_num)
		var cam_b = cameras.get_node_or_null("Camera%d" % sw.camara_b_num)
		var dist_a = sw.position.distance_to(cam_a.position) if cam_a else -1.0
		var dist_b = sw.position.distance_to(cam_b.position) if cam_b else -1.0
		var cam_dist = cam_a.position.distance_to(cam_b.position) if (cam_a and cam_b) else -1.0
		print(sw.name, " (", sw.camara_a_num, " -> ", sw.camara_b_num, ") pos=", sw.position, " dist_between_cams=", cam_dist)
	
	town.free()
	quit(0)
