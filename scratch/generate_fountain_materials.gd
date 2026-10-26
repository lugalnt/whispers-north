extends SceneTree

func _init() -> void:
	print("--- GENERATING FOUNTAIN MATERIALS ---")
	var base_path = "res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/"
	var mat_dir = base_path + "materials/"
	DirAccess.make_dir_absolute(mat_dir)
	
	var configs = [
		{
			"filename": "mat_shadow.tres",
			"name": "mat_shadow",
			"tex": "h_kage.png",
			"trans": BaseMaterial3D.TRANSPARENCY_ALPHA,
			"unshaded": true,
			"color": Color(1, 1, 1, 0.65),
			"roughness": 1.0,
			"priority": -1
		},
		{
			"filename": "mat_water_rim.tres",
			"name": "mat_water_rim",
			"tex": "c03_foun_02.png",
			"trans": BaseMaterial3D.TRANSPARENCY_ALPHA,
			"unshaded": false,
			"color": Color(1, 1, 1, 0.9),
			"roughness": 0.2,
			"priority": 0
		},
		{
			"filename": "mat_basin_floor.tres",
			"name": "mat_basin_floor",
			"tex": "c3bay_yuka1.png",
			"trans": BaseMaterial3D.TRANSPARENCY_DISABLED,
			"unshaded": false,
			"color": Color.WHITE,
			"roughness": 0.85,
			"priority": 0
		},
		{
			"filename": "mat_water_pool.tres",
			"name": "mat_water_pool",
			"tex": "c03_foun_01.png",
			"trans": BaseMaterial3D.TRANSPARENCY_ALPHA,
			"unshaded": false,
			"color": Color(1, 1, 1, 0.85),
			"roughness": 0.1,
			"priority": 0
		},
		{
			"filename": "mat_water_stream.tres",
			"name": "mat_water_stream",
			"tex": "c03_foun_03.png",
			"trans": BaseMaterial3D.TRANSPARENCY_ALPHA,
			"unshaded": false,
			"color": Color(1, 1, 1, 0.95),
			"roughness": 0.1,
			"priority": 1
		},
		{
			"filename": "mat_stone_base.tres",
			"name": "mat_stone_base",
			"tex": "c3_yuka2.png",
			"trans": BaseMaterial3D.TRANSPARENCY_DISABLED,
			"unshaded": false,
			"color": Color.WHITE,
			"roughness": 0.85,
			"priority": 0
		},
		{
			"filename": "mat_stone_trim.tres",
			"name": "mat_stone_trim",
			"tex": "c3_line.png",
			"trans": BaseMaterial3D.TRANSPARENCY_DISABLED,
			"unshaded": false,
			"color": Color.WHITE,
			"roughness": 0.85,
			"priority": 0
		}
	]
	
	for cfg in configs:
		var mat = StandardMaterial3D.new()
		mat.resource_name = cfg["name"]
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.transparency = cfg["trans"]
		mat.albedo_color = cfg["color"]
		mat.roughness = cfg["roughness"]
		if cfg["unshaded"]:
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if cfg["priority"] != 0:
			mat.render_priority = cfg["priority"]
		
		var tex_path = base_path + cfg["tex"]
		var tex = load(tex_path) as Texture2D
		if tex:
			mat.albedo_texture = tex
		else:
			push_error("Failed to load texture: " + tex_path)
		
		var save_p = mat_dir + cfg["filename"]
		var err = ResourceSaver.save(mat, save_p)
		print("Saved material ", cfg["filename"], " -> err=", err)
	
	quit(0)
