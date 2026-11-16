extends SceneTree

var fallos := 0

func _initialize() -> void:
	ejecutar.call_deferred()

func comprobar(ok: bool, mensaje: String) -> void:
	if ok:
		print("PASS ", mensaje)
	else:
		fallos += 1
		push_error("FAIL " + mensaje)

func ejecutar() -> void:
	var gs = root.get_node("GameState")
	gs.nueva_partida()
	var item: InventoryItem = load("res://data/items/queso_nordico.tres").duplicate()
	item.cantidad_maxima = 3
	var inv := Inventory.new()
	comprobar(inv.agregar(item, 5) == 3, "Añadir devuelve cantidad aceptada y respeta límite")
	comprobar(inv.agregar(item, 1) == 0, "Pila llena rechaza sin aumentar cantidad")
	comprobar(not inv.quitar(item.id, 4) and inv.obtener_cantidad(item.id) == 3, "Retirada excesiva no destruye la pila")
	comprobar(not inv.quitar(item.id, 0), "Retirada de cero se rechaza")
	var lista := inv.obtener_lista_items()
	lista[0]["cantidad"] = 999
	comprobar(inv.obtener_cantidad(item.id) == 3, "Lista de UI no puede modificar cantidades internas")
	gs.inventario.items.clear()
	gs.inventario.agregar(item, 2)
	gs.actualizar_hp(gs.stats.max_hp)
	comprobar(not gs.usar_item(item.id) and gs.inventario.obtener_cantidad(item.id) == 2, "Vida llena no consume comida")
	gs.actualizar_hp(gs.stats.max_hp - 2)
	comprobar(gs.usar_item(item.id) and gs.hp_actual == gs.stats.max_hp and gs.inventario.obtener_cantidad(item.id) == 1, "Curación parcial aplica solo HP faltante y consume una unidad")
	var clave: InventoryItem = load("res://data/items/llave_antigua.tres")
	gs.inventario.agregar(clave)
	comprobar(not gs.usar_item(clave.id) and gs.inventario.obtener_cantidad(clave.id) == 1, "Objeto clave no se consume")
	gs.actualizar_hp(0)
	comprobar(not gs.usar_item(item.id), "Comida no actúa como objeto de resurrección")
	gs.actualizar_hp(gs.stats.max_hp - 1)
	var menu: PauseMenu = load("res://scenes/ui/PauseMenu.tscn").instantiate()
	root.add_child(menu)
	menu.abrir_menu()
	menu._mostrar_detalle_item(item)
	comprobar(not menu.detalle_btn_usar.disabled and "+1 HP" in menu.detalle_btn_usar.text, "Menú muestra curación efectiva")
	comprobar("1 / 3" in menu.detalle_categoria.text, "Detalle muestra cantidad y límite")
	menu._usar_item_seleccionado()
	await process_frame
	comprobar(gs.inventario.obtener_cantidad(item.id) == 0 and menu._botones_slots.size() == 1, "Usar última unidad retira slot y conserva otros objetos")
	comprobar(root.gui_get_focus_owner() in menu._botones_slots, "Foco sigue en un objeto válido tras consumir")
	gs.inventario.agregar(item, 2)
	menu._mostrar_detalle_item(item)
	comprobar(menu.detalle_btn_usar.disabled and menu.detalle_btn_usar.text == "Salud completa.", "Menú explica y bloquea consumo con vida llena")
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("TEMP").path_join("wotn_inventario.png"))
	menu.cerrar_menu()
	menu.queue_free()
	await process_frame
	var pickup: ItemPickup3D = load("res://scenes/world/Entities/ItemPickup.tscn").instantiate()
	pickup.item = item
	pickup.cantidad = 4
	pickup.auto_recoger = false
	pickup.tiempo_espera_recoleccion = 0
	pickup.sfx_recoger = null
	pickup.mostrar_texto_flotante = false
	root.add_child(pickup)
	var enemigo := CharacterBody3D.new()
	root.add_child(enemigo)
	comprobar(not pickup._es_jugador(enemigo), "Enemigos no pueden recoger objetos")
	pickup.recoger(enemigo)
	comprobar(pickup.cantidad == 4, "Contacto de enemigo no entrega ni consume botín")
	pickup.recoger()
	comprobar(gs.inventario.obtener_cantidad(item.id) == 3 and pickup.cantidad == 3 and not pickup._ya_recogido, "Recogida parcial conserva sobrante en el mundo")
	pickup.recoger()
	comprobar(pickup.cantidad == 3 and not pickup.is_queued_for_deletion(), "Inventario lleno no elimina el coleccionable")
	gs.inventario.quitar(item.id, 3)
	await pickup.recoger()
	comprobar(gs.inventario.obtener_cantidad(item.id) == 3, "Sobrante se puede recoger después de liberar espacio")
	enemigo.queue_free()
	gs.nueva_partida()
	comprobar(gs.inventario.obtener_cantidad("queso_nordico") == 2, "Nueva partida restaura inventario inicial")
	await process_frame
	await create_timer(0.7).timeout # Esperar recogida y VFX transitorios antes de cerrar el motor.
	print("RESULTADO INVENTARIO: ", fallos, " fallos")
	quit(1 if fallos else 0)
