extends SceneTree

func _initialize() -> void:
	print("==================================================")
	print("TESTING HOUSE SCENES")
	print("==================================================")
	
	var entity_scenes = [
		"res://scenes/world/Entities/House_Cianwood.tscn",
		"res://scenes/world/Entities/House_Violet.tscn",
		"res://scenes/world/Entities/House_Pastoria.tscn"
	]
	
	var model_scenes = [
		"res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Cianwood City House/Cianwood_City_House.tscn",
		"res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Violet City House/Violet_City_House.tscn",
		"res://assets/models/placeholder houses/DS _ DSi - Pokemon Platinum - Map Objects - Pastoria City House/Pastoria_City_House.tscn"
	]
	
	for path in entity_scenes:
		print("Checking Entity Scene: ", path)
		var scn: PackedScene = load(path) as PackedScene
		assert(scn != null, "Scene must load")
		var inst: StaticBody3D = scn.instantiate() as StaticBody3D
		assert(inst != null, "Must instantiate as StaticBody3D")
		root.add_child(inst)
		await process_frame
		
		var col = inst.get_node_or_null("CollisionShape3D")
		assert(col != null, "Must have CollisionShape3D")
		var visual = inst.get_node_or_null("Visual")
		assert(visual != null, "Must have Visual")
		var mi = visual.get_node_or_null("MeshInstance3D") as MeshInstance3D
		assert(mi != null, "Must have MeshInstance3D")
		assert(mi.mesh != null, "Mesh must be assigned")
		
		print("  [PASS] Entity %s: Col=%s VisualScale=%s Mesh=%s" % [inst.name, col.shape.size, visual.scale, mi.mesh.get_class()])
		inst.queue_free()
		await process_frame

	for path in model_scenes:
		print("Checking Model Scene: ", path)
		var scn: PackedScene = load(path) as PackedScene
		assert(scn != null, "Scene must load")
		var inst: Node3D = scn.instantiate() as Node3D
		assert(inst != null, "Must instantiate as Node3D")
		root.add_child(inst)
		await process_frame
		
		var mi = inst.get_node_or_null("MeshInstance3D") as MeshInstance3D
		assert(mi != null, "Must have MeshInstance3D")
		assert(mi.mesh != null, "Mesh must be assigned")
		print("  [PASS] Model %s: Mesh=%s Surfaces=%d" % [inst.name, mi.mesh.get_class(), mi.mesh.get_surface_count()])
		inst.queue_free()
		await process_frame
		
	print("==================================================")
	print("ALL HOUSE SCENES VERIFIED SUCCESSFULLY!")
	print("==================================================")
	quit(0)
