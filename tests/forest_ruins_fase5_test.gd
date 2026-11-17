extends SceneTree
## Pruebas de validación de la Escena 5 (Bosque y Ruinas) y Fase 6 (Arma importante, Jefe y Final de Demo).
## Ejecutar:
##   godot --headless --path . --script res://tests/forest_ruins_fase5_test.gd

var fallos: int = 0
var gs: Node


func _initialize() -> void:
	_ejecutar.call_deferred()


func comprobar(valor: bool, mensaje: String) -> void:
	if valor:
		print("PASS ", mensaje)
	else:
		fallos += 1
		push_error("FAIL: " + mensaje)


func cuadros(cantidad: int) -> void:
	for i in cantidad:
		await physics_frame
		await process_frame


func capturar(nombre: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	var ruta := OS.get_environment("TEMP").path_join("wotn_ruins_" + nombre + ".png")
	root.get_texture().get_image().save_png(ruta)
	print("CAPTURA: ", ruta)


func _ejecutar() -> void:
	gs = root.get_node("GameState")
	gs.nueva_partida()

	var item_mandoble := ItemDatabase.obtener_item("mandoble_ruinas")
	comprobar(item_mandoble != null and item_mandoble.icono != null, "Mandoble de las Ruinas registrado en ItemDatabase con icono")

	var escena: Node3D = load("res://scenes/world/World_ForestRuins.tscn").instantiate()
	escena.scene_file_path = "res://scenes/world/World_ForestRuins.tscn"
	root.add_child(escena)
	current_scene = escena
	await cuadros(10)

	var jugador: CharacterBody3D = escena.call("get_active_player") as CharacterBody3D
	jugador.set_physics_process(false)
	comprobar(jugador != null, "Jugador activo en World_ForestRuins")

	# 1. Verificar bosque denso generado y colisiones de arboleda
	var bosque_gen := escena.get_node_or_null("BosqueGenerado")
	var col_arboleda := escena.get_node_or_null("ColisionesArboleda")
	comprobar(bosque_gen != null and bosque_gen.get_child_count() > 150, "BosqueGenerado poblado con árboles y sotobosque (%d sprites)" % (bosque_gen.get_child_count() if bosque_gen else 0))
	comprobar(col_arboleda is StaticBody3D and col_arboleda.get_child_count() == 27, "ColisionesArboleda conserva los 27 volúmenes de colisión del bosque")

	# 2. Verificar arquitectura de ruinas 3D
	var nodo_ruinas := escena.get_node_or_null("Ruinas")
	comprobar(nodo_ruinas != null and nodo_ruinas.get_child_count() >= 45, "Arquitectura 3D de ruinas presente en las 5 zonas (%d piezas)" % (nodo_ruinas.get_child_count() if nodo_ruinas else 0))

	# 3. Verificar inscripciones leíbles
	var inscripciones := escena.get_node_or_null("InscripcionesRuinas")
	comprobar(inscripciones != null and inscripciones.get_child_count() == 6, "Seis estelas rúnicas leíbles distribuidas por las ruinas")

	# 4. Verificar cofres de tesoro y persistencia
	var cofre_se := escena.get_node_or_null("CofresRuinas/Cofre_RuinaSE")
	var cofre_este := escena.get_node_or_null("CofresRuinas/Cofre_RuinaEste")
	var cofre_no := escena.get_node_or_null("CofresRuinas/Cofre_RuinasNO")
	comprobar(cofre_se != null and cofre_este != null and cofre_no != null, "Tres cofres de tesoro presentes en las ruinas (SE, Este, NO)")

	var cristales_antes: int = gs.inventario.obtener_cantidad("cristal_bosque")
	await cofre_se.abrir(jugador)
	await cuadros(4)
	comprobar(cofre_se.esta_abierto and gs.tiene_progreso(&"cofre.ruinas_se"), "Cofre_RuinaSE abierto y registrado en GameState")
	comprobar(gs.inventario.obtener_cantidad("cristal_bosque") > cristales_antes, "Cofre_RuinaSE entrega Cristal del bosque")
	var msg_cofre: String = str(cofre_se.get_meta("ultimo_mensaje_recompensa", ""))
	comprobar("Cristal del bosque" in msg_cofre, "Cofre_RuinaSE notifica al jugador qué recompensa obtuvo (%s)" % msg_cofre.replace("\n", " "))

	# 5. Verificar encuentros y su visibilidad en cámara
	var encuentros := escena.get_node_or_null("EncuentrosRuinas")
	comprobar(encuentros != null and encuentros.get_child_count() == 6, "Seis Jarritos distribuidos en los 4 puntos de encuentro de las ruinas")

	# Capturas opcionales si se ejecuta con ventana gráfica
	if DisplayServer.get_name() != "headless":
		for par in [
			["Camera3", Vector3(66, 1.1, 61), "ruina_se"],
			["Camera5", Vector3(28, 1.1, 40), "ruina_oeste"],
			["Camera7", Vector3(18, 1.1, 14), "ruinas_no"],
			["Camera9", Vector3(68, 1.1, 16), "santuario_mandoble"],
			["Camera10", Vector3(86, 1.1, 17), "arena_jefe"],
		]:
			var cam := escena.get_node_or_null("Cameras/" + par[0]) as Camera3D
			if cam:
				jugador.global_position = par[1]
				cam.make_current()
				await capturar(par[2])

	# 6. Reclamar el Arma Grande / Ítem Importante (Mandoble de las Ruinas)
	var atq_inicial: int = gs.stats.ataque
	gs.actualizar_hp(5)
	escena._al_terminar_dialogo_pedestal()
	await cuadros(4)
	comprobar(gs.tiene_progreso(gs.OBJETO_IMPORTANTE_RUINAS), "Progreso OBJETO_IMPORTANTE_RUINAS marcado al reclamar el Mandoble")
	comprobar(gs.inventario.obtener_cantidad("mandoble_ruinas") == 1, "Mandoble de las Ruinas añadido al inventario")
	comprobar(gs.stats.ataque == atq_inicial + 4, "El Mandoble aumenta el ataque de Finn en +4 (%d -> %d)" % [atq_inicial, gs.stats.ataque])
	comprobar(gs.hp_actual == gs.stats.max_hp, "El altar restaura la salud de Finn antes del jefe")
	comprobar(not escena.espada_visual.visible, "El sprite del Mandoble sobre el pedestal se oculta tras recogerlo")

	# 7. Simular victoria contra el Jefe Final (Coloso de las Ruinas) y pantalla de Fin de Demo
	var boss_battler: Node = load("res://scenes/combat/battlers/BossRuinasBattler.tscn").instantiate()
	comprobar(boss_battler is Battler and boss_battler.nombre == "Coloso de las Ruinas", "BossRuinasBattler instancia válidamente como Battler")
	boss_battler.free()

	escena._completar_victoria_jefe()
	await cuadros(4)
	comprobar(gs.tiene_progreso(gs.JEFE_RUINAS_DERROTADO), "Progreso JEFE_RUINAS_DERROTADO registrado tras vencer al jefe")
	comprobar(gs.tiene_progreso(gs.DEMO_COMPLETADA), "Progreso DEMO_COMPLETADA registrado al terminar la pelea del jefe")
	comprobar(not escena.guardian_jefe.visible, "El Coloso de las Ruinas desaparece del mapa tras su derrota")
	var pantalla_fin := escena.get_node_or_null("PantallaFinDemo")
	comprobar(pantalla_fin != null, "Se muestra la pantalla de Fin de la Demo tras vencer al jefe")
	await capturar("fin_demo")

	var btn_explorar := pantalla_fin.find_child("BtnSeguirExplorando", true, false) as Button
	comprobar(btn_explorar != null, "Pantalla de Fin de Demo incluye botón para seguir explorando")
	if btn_explorar:
		btn_explorar.pressed.emit()
		await cuadros(3)
		comprobar( not jugador.is_interacting, "Cerrar pantalla de Fin de Demo devuelve el control al jugador")

	escena.queue_free()
	await cuadros(4)
	print("RESULTADO FASE 5/6 RUINAS: ", fallos, " fallos")
	quit(1 if fallos else 0)
