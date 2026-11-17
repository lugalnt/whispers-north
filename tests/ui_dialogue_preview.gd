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
	globo._mostrar_retrato(load("res://assets/sprites/player/Erland (Padre)/nordic_v1/erland_portrait.png"))
	globo.character_label.text = "[b][color=#ffd700]Erland[/color][/b]"
	globo.dialogue_label.text = "El camino atraviesa el pueblo y continúa hacia las ruinas. Antes de salir, voy a comprobar que llevo todo lo necesario."
	globo.dialogue_label.visible_characters = -1
	globo.responses_menu.hide()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("dialogue_nordic.png"))
	quit()
