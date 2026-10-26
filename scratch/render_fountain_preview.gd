extends SceneTree

func _init() -> void:
	print("--- RENDERING FOUNTAIN PREVIEW ---")
	call_deferred("_render")

func _render() -> void:
	var viewport = SubViewport.new()
	viewport.size = Vector2i(1024, 768)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	
	var world_3d = World3D.new()
	viewport.world_3d = world_3d
	
	var fountain_scene = load("res://scenes/world/Entities/Fountain.tscn") as PackedScene
	var fountain = fountain_scene.instantiate()
	viewport.add_child(fountain)
	
	# Light
	var light = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, 35, 0)
	light.light_color = Color(1.0, 0.98, 0.92)
	light.light_energy = 1.3
	light.shadow_enabled = true
	viewport.add_child(light)
	
	# Environment
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.25, 0.32)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.65, 0.72, 0.8)
	env.ambient_light_energy = 0.8
	env_node.environment = env
	viewport.add_child(env_node)
	
	# Ground
	var ground = MeshInstance3D.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(30, 30)
	var ground_mat = StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.85, 0.88, 0.92) # snow/paving
	ground.mesh = plane_mesh
	ground.material_override = ground_mat
	viewport.add_child(ground)
	
	# Camera
	var cam = Camera3D.new()
	cam.position = Vector3(0, 7.5, 12.0)
	cam.look_at(Vector3(0, 1.8, 0), Vector3.UP)
	cam.current = true
	viewport.add_child(cam)
	
	for i in range(10):
		await process_frame
	
	var img = viewport.get_texture().get_image()
	if img:
		img.save_png("res://scratch/fountain_preview.png")
		print("[SUCCESS] fountain_preview.png saved successfully!")
	else:
		print("[FAIL] Failed to capture viewport image")
	
	viewport.queue_free()
	quit(0)
