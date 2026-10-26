extends SceneTree

func _initialize() -> void:
	print("--- GENERATING HOUSE SCENES AND MATERIALS ---")
	
	var houses = [
		{
			"id": "cianwood",
			"display_name": "House_Cianwood",
			"folder": "res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Cianwood City House/",
			"mesh_name": "Cianwood City House.obj",
			"scene_model_name": "Cianwood_City_House.tscn",
			"surfaces": [
				{"name": "mat_window", "tex": "_mado.png", "type": "scissor"},
				{"name": "mat_shadow", "tex": "_kage.png", "type": "shadow"},
				{"name": "mat_door", "tex": "h_in.png", "type": "opaque"},
				{"name": "mat_walls_roof", "tex": "tn_h01_02.png", "type": "opaque"}
			],
			"scale": 0.08,
			"offset": Vector3(-0.24, -0.08, -0.24),
			"col_size": Vector3(5.6, 5.0, 4.2),
			"col_pos": Vector3(0.0, 2.5, 0.0)
		},
		{
			"id": "violet",
			"display_name": "House_Violet",
			"folder": "res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Violet City House/",
			"mesh_name": "Violet City House.obj",
			"scene_model_name": "Violet_City_House.tscn",
			"surfaces": [
				{"name": "mat_window", "tex": "h_mado.png", "type": "scissor"},
				{"name": "mat_shadow", "tex": "h_kage.png", "type": "shadow"},
				{"name": "mat_door", "tex": "kk_h01_b.png", "type": "opaque"},
				{"name": "mat_walls_roof", "tex": "kk_h01_a.png", "type": "opaque"}
			],
			"scale": 0.08,
			"offset": Vector3(-0.16, -0.08, -0.24),
			"col_size": Vector3(5.8, 5.8, 4.2),
			"col_pos": Vector3(0.0, 2.9, 0.0)
		},
		{
			"id": "pastoria",
			"display_name": "House_Pastoria",
			"folder": "res://assets/models/placeholder houses/DS _ DSi - Pokemon Platinum - Map Objects - Pastoria City House/",
			"mesh_name": "Pastoria City House.obj",
			"scene_model_name": "Pastoria_City_House.tscn",
			"surfaces": [
				{"name": "mat_window", "tex": "h_mado.png", "type": "scissor"},
				{"name": "mat_door", "tex": "c6_h01_b.png", "type": "opaque"},
				{"name": "mat_shadow", "tex": "h_kage.png", "type": "shadow"},
				{"name": "mat_walls_roof", "tex": "c6_h01_a.png", "type": "opaque"}
			],
			"scale": 0.08,
			"offset": Vector3(-0.28, -0.08, 0.08),
			"col_size": Vector3(5.8, 5.8, 3.8),
			"col_pos": Vector3(0.0, 2.9, 0.0)
		}
	]
	
	for h in houses:
		print("\nProcessing ", h["display_name"], "...")
		var folder: String = h["folder"]
		var mesh_path: String = folder + h["mesh_name"]
		var mesh: Mesh = load(mesh_path) as Mesh
		if mesh == null:
			printerr("Failed to load mesh: ", mesh_path)
			continue
		
		# 1. Crear o actualizar materiales .tres en subcarpeta materials/
		var mat_dir: String = folder + "materials/"
		if not DirAccess.dir_exists_absolute(mat_dir):
			DirAccess.make_dir_absolute(mat_dir)
		
		var materials: Array[StandardMaterial3D] = []
		for s_idx in range(h["surfaces"].size()):
			var s_data = h["surfaces"][s_idx]
			var mat_path: String = mat_dir + s_data["name"] + ".tres"
			var tex_path: String = folder + s_data["tex"]
			var tex: Texture2D = load(tex_path) as Texture2D
			
			var mat := StandardMaterial3D.new()
			mat.resource_name = s_data["name"]
			mat.albedo_texture = tex
			mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
			
			match s_data["type"]:
				"opaque":
					mat.albedo_color = Color.WHITE
					mat.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					mat.roughness = 0.85
				"scissor":
					mat.albedo_color = Color.WHITE
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					mat.alpha_scissor_threshold = 0.5
				"shadow":
					mat.albedo_color = Color(1.0, 1.0, 1.0, 0.5)
					mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			
			ResourceSaver.save(mat, mat_path)
			var saved_mat: StandardMaterial3D = load(mat_path) as StandardMaterial3D
			materials.append(saved_mat)
			print("  Created material: ", mat_path)
		
		# 2. Crear escena de modelo simple (Visual) en la carpeta del modelo
		var model_root := Node3D.new()
		model_root.name = h["display_name"]
		var mi := MeshInstance3D.new()
		mi.name = "MeshInstance3D"
		mi.mesh = mesh
		for s_idx in range(materials.size()):
			mi.set_surface_override_material(s_idx, materials[s_idx])
		model_root.add_child(mi)
		mi.owner = model_root
		
		var packed_model := PackedScene.new()
		packed_model.pack(model_root)
		var model_scene_path: String = folder + h["scene_model_name"]
		ResourceSaver.save(packed_model, model_scene_path)
		print("  Saved model scene: ", model_scene_path)
		model_root.queue_free()
		
		# 3. Crear escena de Entidad para el Mundo (StaticBody3D con escala calibrada y colisión)
		var entity_root := StaticBody3D.new()
		entity_root.name = h["display_name"]
		
		var col_shape := CollisionShape3D.new()
		col_shape.name = "CollisionShape3D"
		var box := BoxShape3D.new()
		box.size = h["col_size"]
		col_shape.shape = box
		col_shape.position = h["col_pos"]
		entity_root.add_child(col_shape)
		col_shape.owner = entity_root
		
		var visual_node := Node3D.new()
		visual_node.name = "Visual"
		visual_node.scale = Vector3.ONE * h["scale"]
		visual_node.position = h["offset"]
		
		var entity_mi := MeshInstance3D.new()
		entity_mi.name = "MeshInstance3D"
		entity_mi.mesh = mesh
		for s_idx in range(materials.size()):
			entity_mi.set_surface_override_material(s_idx, materials[s_idx])
		
		visual_node.add_child(entity_mi)
		entity_root.add_child(visual_node)
		visual_node.owner = entity_root
		entity_mi.owner = entity_root
		
		var packed_entity := PackedScene.new()
		packed_entity.pack(entity_root)
		var entity_scene_path: String = "res://scenes/world/Entities/" + h["display_name"] + ".tscn"
		ResourceSaver.save(packed_entity, entity_scene_path)
		print("  Saved entity scene: ", entity_scene_path)
		entity_root.queue_free()
	
	print("\n--- ALL SCENES GENERATED SUCCESSFULLY! ---")
	quit(0)
