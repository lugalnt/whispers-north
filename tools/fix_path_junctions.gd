extends SceneTree
func _initialize() -> void:
	var total := 0
	for ruta in ["World/Path", "World/Main_Path_Section1", "World/Main_Path_Section2", "World/Main_Path_Section3", "World_Town/Main_Path_Town_Section1"]:
		var archivo: String = "res://scenes/world/Paths/" + ruta + ".tscn"
		var capa: TileMapLayer = load(archivo).instantiate()
		var cells := capa.get_used_cells()
		var corregidos := 0
		for c in cells:
			if capa.get_cell_source_id(c) == 1:
				capa.set_cell(c, 0, Vector2i(1, 1))
				corregidos += 1
		assert(capa.get_used_cells().size() == cells.size())
		var packed := PackedScene.new()
		assert(packed.pack(capa) == OK)
		assert(ResourceSaver.save(packed, archivo) == OK)
		print(ruta, ": ", corregidos, " cruces corregidos; ", cells.size(), " celdas conservadas")
		total += corregidos
		capa.free()
	print("TOTAL: ", total)
	quit()
