extends SceneTree

func _init() -> void:
	print("--- INSPECTING FOUNTAIN MODEL AND TEXTURES ---")
	var dir = DirAccess.open("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			print("File: ", file_name)
			if file_name.ends_with(".png"):
				var img = Image.load_from_file("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/" + file_name)
				if img:
					print("  Dimensions: ", img.get_width(), "x", img.get_height(), " Format: ", img.get_format())
			file_name = dir.get_next()
	
	# Load the imported DAE
	var dae_scene = load("res://assets/models/DS _ DSi - Pokemon Black 2 _ White 2 - Fountains - Fountain 02/c03_fountain_01.dae") as PackedScene
	if dae_scene:
		print("DAE scene loaded successfully!")
		var inst = dae_scene.instantiate()
		print("Root node: ", inst.get_class(), " name: ", inst.name)
		_print_children(inst, 1)
		inst.free()
	else:
		print("Failed to load DAE scene!")
	
	quit(0)

func _print_children(node: Node, indent: int) -> void:
	var prefix = "  ".repeat(indent)
	print(prefix, "- ", node.name, " (", node.get_class(), ")")
	if node is MeshInstance3D:
		var mesh = node.mesh
		if mesh:
			print(prefix, "  Mesh surfaces: ", mesh.get_surface_count())
			for i in range(mesh.get_surface_count()):
				var mat = node.get_surface_override_material(i)
				if mat == null:
					mat = mesh.surface_get_material(i)
				print(prefix, "    Surface ", i, " mat: ", (mat.resource_name if mat else "null"), " class: ", (mat.get_class() if mat else ""))
				if mat is StandardMaterial3D:
					print(prefix, "      Albedo tex: ", (mat.albedo_texture.resource_path if mat.albedo_texture else "none"))
					print(prefix, "      Transparency: ", mat.transparency)
					print(prefix, "      UV1 scroll/scale: ", mat.uv1_scale, " offset: ", mat.uv1_offset)
	if node is AnimationPlayer:
		print(prefix, "  AnimationPlayer anims: ", node.get_animation_list())
	for c in node.get_children():
		_print_children(c, indent + 1)
