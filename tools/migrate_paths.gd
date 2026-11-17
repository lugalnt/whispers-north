extends SceneTree
func _initialize() -> void:
	var nuevo: TileSet = load("res://assets/sprites/environment/tilesets/nordic_path_v1/nordic_path_tileset.tres")
	for ruta in ["World/Path", "World/Main_Path_Section1", "World/Main_Path_Section2", "World/Main_Path_Section3", "World_Town/Main_Path_Town_Section1"]:
		var archivo: String = "res://scenes/world/Paths/" + ruta + ".tscn"
		var capa: TileMapLayer = load(archivo).instantiate()
		if capa.tile_set.resource_path == nuevo.resource_path:
			capa.free()
			continue
		var cells := capa.get_used_cells()
		var ocupado := {}
		for c in cells: ocupado[c] = true
		capa.clear()
		capa.tile_set = nuevo
		# Mantener el tamaño 2D de la fuente; PathPatch normaliza la raíz a escala 1.
		capa.scale *= 0.25
		for c in cells:
			var n: bool = ocupado.has(c + Vector2i.UP)
			var s: bool = ocupado.has(c + Vector2i.DOWN)
			var w: bool = ocupado.has(c + Vector2i.LEFT)
			var e: bool = ocupado.has(c + Vector2i.RIGHT)
			var atlas := Vector2i(1, 1)
			var fuente := 0
			if not w: atlas.x = 0
			elif not e: atlas.x = 2
			if not n: atlas.y = 0
			elif not s: atlas.y = 2
			# Cuatro vecinos conectados requieren tierra continua, sin recorte interior.
			capa.set_cell(c, fuente, atlas)
		assert(capa.get_used_cells().size() == cells.size())
		var packed := PackedScene.new()
		assert(packed.pack(capa) == OK)
		assert(ResourceSaver.save(packed, archivo) == OK)
		print("MIGRADO ", ruta, ": ", cells.size(), " celdas conservadas")
		capa.free()
	quit()

