extends SceneTree

func _initialize() -> void:
	var vp = SubViewport.new()
	vp.size = Vector2i(512, 512)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	
	var world3d = World3D.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.4, 0.6, 0.9)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.8)
	world3d.environment = env
	vp.world_3d = world3d
	
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 45, 0)
	vp.add_child(light)
	
	var cam = Camera3D.new()
	cam.position = Vector3(0, 4, 8)
	cam.look_at(Vector3(0, 2.5, 0))
	vp.add_child(cam)
	
	# Load Cianwood house
	var mesh = load("res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Cianwood City House/Cianwood City House.obj")
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	
	# Scale by 0.08 so ~6 meters tall, centered
	mi.scale = Vector3.ONE * 0.08
	mi.position = Vector3(0, 0, 0)
	
	# Overrides
	var dir = "res://assets/models/placeholder houses/DS _ DSi - Pokemon HeartGold _ SoulSilver - Map Objects - Cianwood City House/"
	var mat_mado = StandardMaterial3D.new()
	mat_mado.albedo_texture = load(dir + "_mado.png")
	mat_mado.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat_mado.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.set_surface_override_material(0, mat_mado)
	
	var mat_kage = StandardMaterial3D.new()
	mat_kage.albedo_texture = load(dir + "_kage.png")
	mat_kage.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat_kage.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat_kage.albedo_color = Color(1, 1, 1, 0.5)
	mat_kage.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.set_surface_override_material(1, mat_kage)
	
	var mat_in = StandardMaterial3D.new()
	mat_in.albedo_texture = load(dir + "h_in.png")
	mat_in.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat_in.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.set_surface_override_material(2, mat_in)
	
	var mat_main = StandardMaterial3D.new()
	mat_main.albedo_texture = load(dir + "tn_h01_02.png")
	mat_main.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat_main.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.set_surface_override_material(3, mat_main)
	
	vp.add_child(mi)
	
	for i in range(5):
		await process_frame
	
	var img = vp.get_texture().get_image()
	img.save_png("res://scratch/cianwood_preview.png")
	print("Saved preview to scratch/cianwood_preview.png")
	quit(0)
