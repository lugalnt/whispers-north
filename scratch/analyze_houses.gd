extends SceneTree

func _initialize() -> void:
	var list = [
		{
			"name": "Cianwood City House",
			"path": "res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Cianwood City House/Cianwood City House.obj",
			"dir": "res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Cianwood City House/"
		},
		{
			"name": "Violet City House",
			"path": "res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Violet City House/Violet City House.obj",
			"dir": "res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Violet City House/"
		},
		{
			"name": "Pastoria City House",
			"path": "res://assets/models/placeholder houses/DS _ DSi - Pokemon Platinum - Map Objects - Pastoria City House/Pastoria City House.obj",
			"dir": "res://assets/models/placeholder houses/DS _ DSi - Pokemon Platinum - Map Objects - Pastoria City House/"
		}
	]
	
	for entry in list:
		print("====================================")
		print(entry["name"])
		var mesh: Mesh = load(entry["path"]) as Mesh
		var aabb: AABB = mesh.get_aabb()
		print("AABB: min=", aabb.position, " max=", aabb.end, " size=", aabb.size)
		print("Center: ", aabb.get_center())
		for i in range(mesh.get_surface_count()):
			var mat_name = mesh.get("surface_%d/name" % i)
			print("Surface %d: name='%s'" % [i, mat_name])
	quit(0)
