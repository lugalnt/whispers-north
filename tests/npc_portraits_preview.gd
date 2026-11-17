extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var zona = load("res://scenes/world/World_Town.tscn").instantiate()
	root.add_child(zona)
	current_scene = zona
	await create_timer(0.6).timeout
	var globo = load("res://scenes/dialogue/NordicDialogueBalloon.tscn").instantiate()
	root.add_child(globo)
	globo.balloon.show()
	globo.responses_menu.hide()
	for nombre in ["Npc", "Npc_Exp", "Npc_Util"]:
		var dialogo = zona.get_node(nombre + "/InteraccionDialogo")
		assert(dialogo.retrato_hablante is AtlasTexture)
		globo._mostrar_retrato(dialogo.retrato_hablante)
		globo.character_label.text = dialogo.nombre_hablante
		globo.dialogue_label.text = dialogo.lineas_rapidas[0]
		globo.dialogue_label.visible_characters = -1
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("retrato_" + nombre + ".png"))
		print("PASS ", nombre, ": retrato reutiliza sprite existente")
	quit()
