extends SceneTree
func _initialize() -> void:
	var path := "res://scenes/world/World_Town.tscn"
	var town = load(path).instantiate()
	var patch = town.get_node("PathPatch")
	var layer: TileMapLayer = patch.source_scene.instantiate()
	var used := layer.get_used_rect()
	var road: Array[Vector2] = []
	for cell in layer.get_used_cells():
		var local: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5) - (Vector2(used.position) + Vector2(used.size) * 0.5)) * patch.meters_per_tile
		for sign_z in [-1.0, 1.0]:
			var v: Vector3 = patch.transform * Vector3(local.x, 0, local.y * sign_z)
			road.append(Vector2(v.x, v.z))
	var blockers: Array[Vector3] = []
	for house in town.get_node("Houses").get_children():
		blockers.append(Vector3(house.position.x, 3.6, house.position.z))
	for group in ["DecoracionNueva", "DecoracionEntorno"]:
		for prop in town.get_node(group).get_children():
			blockers.append(Vector3(prop.position.x, 1.5, prop.position.z))
	blockers.append(Vector3(-7.1823, 7.2, 11.6161))
	for npc in ["Npc", "Npc_Exp", "Npc_Util"]:
		var pos: Vector3 = town.get_node(npc).position
		blockers.append(Vector3(pos.x, 2.3, pos.z))
	var rng := RandomNumberGenerator.new()
	rng.seed = 171128
	var points: Array[Vector2] = []
	var text := FileAccess.get_file_as_string(path)
	assert(not text.contains('name="ArbustosPueblo"'))
	var at := text.find('[sub_resource')
	text = text.insert(at, '[ext_resource type="PackedScene" path="res://scenes/world/Entities/NordicProps/dense_bush.tscn" id="town_bush"]\n\n')
	text += '\n[node name="ArbustosPueblo" type="Node3D" parent="."]\n'
	for attempt in 12000:
		var pos := Vector2(rng.randf_range(-23, 44), rng.randf_range(-14, 21))
		var safe := true
		for tile in road:
			if absf(pos.x-tile.x) < 1.35 and absf(pos.y-tile.y) < 1.5: safe = false; break
		if not safe: continue
		for block in blockers:
			if pos.distance_to(Vector2(block.x,block.z)) < block.y: safe = false; break
		if not safe: continue
		for other in points:
			if pos.distance_to(other) < 1.45: safe = false; break
		if not safe: continue
		points.append(pos)
		var scale := rng.randf_range(0.48, 0.78)
		text += '\n[node name="Arbusto_%02d" parent="ArbustosPueblo" instance=ExtResource("town_bush")]\nposition = Vector3(%f, 0.078613, %f)\nscale = Vector3(%f, %f, %f)\n' % [points.size(),pos.x,pos.y,scale,scale,scale]
		text += '\n[node name="Visual" parent="ArbustosPueblo/Arbusto_%02d" index="0"]\nshaded = true\ncast_shadow = 2\nflip_h = %s\n' % [points.size(), "true" if rng.randf()<0.5 else "false"]
		# Low foliage is decorative: never add invisible barriers to traversal.
		text += '\n[node name="Obstacle" parent="ArbustosPueblo/Arbusto_%02d" index="1"]\ncollision_layer = 0\n' % points.size()
		if points.size() == 65: break
	for i in points.size(): text += '\n[editable path="ArbustosPueblo/Arbusto_%02d"]\n' % (i+1)
	assert(points.size() == 65)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("65 arbustos añadidos; exclusiones de caminos, casas, fuente y mobiliario comprobadas")
	layer.free()
	town.free()
	quit()
