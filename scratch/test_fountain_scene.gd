extends SceneTree

func _init() -> void:
	print("\n==================================================")
	print("TESTING FOUNTAIN IMPORT & ANIMATIONS")
	print("==================================================")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var passed = 0
	var failed = 0
	
	# 1. Cargar escena
	print("\n--- 1. Testing Fountain.tscn Loading ---")
	var fountain_scene = load("res://scenes/world/Entities/Fountain.tscn") as PackedScene
	if fountain_scene:
		print("[PASS] Fountain.tscn cargado correctamente")
		passed += 1
	else:
		print("[FAIL] No se pudo cargar Fountain.tscn")
		failed += 1
		quit(1)
		return
	
	var fountain = fountain_scene.instantiate()
	root.add_child(fountain)
	await process_frame
	
	# 2. Verificar estructura de nodos
	print("\n--- 2. Testing Node Hierarchy ---")
	var col = fountain.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var visual = fountain.get_node_or_null("Visual") as Node3D
	var mesh_inst = fountain.get_node_or_null("Visual/FountainMesh") as MeshInstance3D
	var anim_player = fountain.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var audio_player = fountain.get_node_or_null("AudioStreamPlayer3D") as AudioStreamPlayer3D
	
	if col and visual and mesh_inst and anim_player and audio_player:
		print("[PASS] Todos los nodos requeridos existen en Fountain.tscn")
		passed += 1
	else:
		print("[FAIL] Faltan nodos en la jerarquía")
		failed += 1
	
	# 3. Verificar colisión
	print("\n--- 3. Testing Collision ---")
	if col and col.shape is CylinderShape3D:
		var cyl = col.shape as CylinderShape3D
		print("[PASS] CollisionShape3D es un CylinderShape3D con radio=", cyl.radius, " altura=", cyl.height)
		passed += 1
	else:
		print("[FAIL] CollisionShape3D no es válido")
		failed += 1

	# 4. Verificar materiales y filtros
	print("\n--- 4. Testing Materials & Pixel Art Filters ---")
	if mesh_inst and mesh_inst.mesh and mesh_inst.mesh.get_surface_count() == 7:
		print("[PASS] Mesh tiene 7 superficies")
		passed += 1
		var mats_ok = true
		for i in range(7):
			var mat = mesh_inst.get_surface_override_material(i) as StandardMaterial3D
			if mat == null:
				mats_ok = false
				print("  [FAIL] Surface override ", i, " es null")
			elif mat.texture_filter != BaseMaterial3D.TEXTURE_FILTER_NEAREST:
				mats_ok = false
				print("  [FAIL] Surface override ", i, " no tiene filtro NEAREST")
		if mats_ok:
			print("[PASS] Todas las 7 superficies tienen materiales con filtro NEAREST asignados")
			passed += 1
		else:
			failed += 1
	else:
		print("[FAIL] MeshInstance3D o superficies inválidas")
		failed += 1

	# 5. Verificar transparencias del agua
	print("\n--- 5. Testing Water Transparency & Double-Sided Rendering ---")
	var stream_mat = mesh_inst.get_surface_override_material(4) as StandardMaterial3D # hunsui_water
	var pool_mat = mesh_inst.get_surface_override_material(3) as StandardMaterial3D   # lambert15
	var rim_mat = mesh_inst.get_surface_override_material(1) as StandardMaterial3D    # c03_foun_02
	
	if stream_mat and stream_mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA and stream_mat.cull_mode == BaseMaterial3D.CULL_DISABLED:
		print("[PASS] Material de cascada (hunsui_water) tiene Alpha y Cull Disabled (doble cara)")
		passed += 1
	else:
		print("[FAIL] Configuración de material de cascada incorrecta")
		failed += 1

	# 6. Verificar AnimationPlayer y animación de flujo
	print("\n--- 6. Testing AnimationPlayer & Water Flow ---")
	if anim_player.has_animation("flow"):
		print("[PASS] Animación 'flow' existe en AnimationPlayer")
		passed += 1
		var anim = anim_player.get_animation("flow")
		if anim.loop_mode == Animation.LOOP_LINEAR:
			print("[PASS] Animación 'flow' configurada en modo LOOP continuo")
			passed += 1
		else:
			print("[FAIL] Animación 'flow' no está en loop")
			failed += 1
			
		# Probar que la animación altera los UVs
		anim_player.play("flow")
		anim_player.advance(0.5)
		if is_equal_approx(stream_mat.uv1_offset.y, -0.5):
			print("[PASS] Animación avanza UVs de la cascada de agua correctamente (-0.5 a 0.5s)")
			passed += 1
		else:
			print("[FAIL] uv1_offset no avanzó como se esperaba: ", stream_mat.uv1_offset)
			failed += 1
	else:
		print("[FAIL] Animación 'flow' no encontrada")
		failed += 1

	# 7. Verificar script controlador
	print("\n--- 7. Testing Fountain Script Controller ---")
	if fountain is Fountain:
		print("[PASS] Fountain tiene script Fountain adjunto con class_name registrado")
		passed += 1
		fountain.velocidad_flujo = 2.0
		if is_equal_approx(anim_player.speed_scale, 2.0):
			print("[PASS] velocidad_flujo actualiza speed_scale del AnimationPlayer reactivamente")
			passed += 1
		else:
			print("[FAIL] speed_scale no coincidió")
			failed += 1
	else:
		print("[FAIL] fountain no es de clase Fountain")
		failed += 1

	fountain.queue_free()
	await process_frame

	print("\n==================================================")
	print("RESULTADOS FINALES: PASARON %d / %d" % [passed, passed + failed])
	print("==================================================")
	quit(0 if failed == 0 else 1)
