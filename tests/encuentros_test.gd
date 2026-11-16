extends SceneTree
## Ejecutar: godot --headless --path . --script res://tests/encuentros_test.gd
var fallos: int = 0
var gestor: Node
var mundo: Node3D
var jugador: CharacterBody3D
var jarrito: CharacterBody3D
var resultados: Array[int] = []
var reservas: int = 0


func _initialize() -> void:
	_ejecutar.call_deferred()


func comprobar(valor: bool, mensaje: String) -> void:
	if valor:
		print("PASS ", mensaje)
	else:
		fallos += 1
		push_error(mensaje)


func cuadros(cantidad: int) -> void:
	for i in cantidad:
		await physics_frame
		await process_frame


func solicitar(componente: Node, visual: Node = null) -> void:
	var resultado: int = await componente.iniciar_combate(jugador, visual)
	resultados.append(resultado)


func nuevo_componente() -> Node:
	var componente: Node = load("res://scripts/combat/encuentro_combate.gd").new()
	componente.flash_activo = false
	componente.duracion_fundido_entrada = 0.01
	componente.duracion_fundido_salida = 0.01
	mundo.add_child(componente)
	return componente


func preparar() -> void:
	gestor.cancelar(null, "limpieza_test")
	await cuadros(3)
	gestor._proteccion = 0.0
	resultados.clear()
	jugador.is_interacting = false
	jugador.position = Vector3(-9, 1, 0)


func esperar_arena() -> void:
	for i in 180:
		if gestor.activa == null or gestor.activa.fase == 1:
			return
		await cuadros(1)
	comprobar(false, "La arena debe iniciar antes del límite del test")


func _ejecutar() -> void:
	gestor = root.get_node("CoordinadorEncuentros")
	gestor.encuentro_reservado.connect(func(_p: Node): reservas += 1)
	mundo = load("res://scenes/world/Tests/JarritoTest.tscn").instantiate()
	root.add_child(mundo)
	current_scene = mundo
	jugador = mundo.get_node("Player32")
	jarrito = mundo.get_node("Jarrito")
	jarrito.combate_habilitado = false
	await cuadros(5)
	var uno: Node = nuevo_componente()
	var dos: Node = nuevo_componente()
	var visual: Node3D = Node3D.new()
	mundo.add_child(visual)

	# Dos componentes simultáneos: solo uno obtiene reserva, el rechazado no restaura al jugador.
	solicitar(uno, visual)
	solicitar(dos)
	comprobar(gestor.ocupado() and reservas == 1, "Reserva exclusiva entre solicitudes simultáneas")
	comprobar(jugador.is_interacting and resultados.size() == 1, "Rechazar otra solicitud no desbloquea al jugador")
	await esperar_arena()
	comprobar(not visual.visible and not jugador.get_node("Sprite2_5D").visible, "Visuales ocultos durante ejecución")
	# Ejercita la ruta real de huida, incluido su mensaje y sincronización.
	gestor.activa.arena._intentar_huida()
	await cuadros(140)
	comprobar(not gestor.ocupado() and resultados.size() == 2, "Huida real cierra y devuelve ambos await")
	comprobar(not jugador.is_interacting and visual.visible and jugador.get_node("Sprite2_5D").visible, "Huida restaura controles y visuales")
	comprobar(not gestor.disponible(jugador), "Protección compartida contra reencuentros")

	await preparar()
	jugador.is_interacting = true
	solicitar(uno)
	comprobar(not gestor.ocupado() and jugador.is_interacting, "Interacción previa rechazada sin modificar su bloqueo")
	jugador.is_interacting = false
	# Contrato de diálogo incluso cuando bloquear_jugador está desactivado.
	var dialogo: Node = Node.new()
	mundo.add_child(dialogo)
	gestor.bloquear_actividad(dialogo)
	solicitar(uno)
	comprobar(not gestor.ocupado(), "Diálogo sin congelar al jugador excluye encuentros")
	dialogo.queue_free()
	await cuadros(2)
	comprobar(gestor.disponible(jugador), "Actividad destruida no deja bloqueos")
	# Entrada real de InteraccionDialogo: la reserva se rechaza antes incluso
	# de que dialogo_iniciado entregue el control al código consumidor.
	var charla: Node = load("res://scripts/dialogue/interaccion_dialogo.gd").new()
	mundo.add_child(charla)
	charla.dialogo_iniciado.connect(func():
		solicitar(uno)
		comprobar(not gestor.ocupado(), "Entrada real de diálogo excluye la reserva")
	)
	# Sin recurso, el propio componente finaliza inmediatamente y libera su actividad.
	charla.iniciar_dialogo(jugador)
	comprobar(not jugador.is_interacting and gestor.disponible(jugador), "Finalización del diálogo restaura su propio bloqueo")
	charla.queue_free()

	await preparar()
	visual.hide()
	solicitar(uno, visual)
	uno.cancelar_combate("cancelacion_entrada")
	uno.cancelar_combate("segunda_cancelacion")
	await cuadros(3)
	comprobar(not gestor.ocupado() and not jugador.is_interacting and not visual.visible, "Cancelación idempotente respeta visibilidad previa")
	comprobar(resultados.size() == 1 and uno.ultima_cancelacion == "cancelacion_entrada", "Cancelación completa una sola vez")
	visual.show()

	await preparar()
	solicitar(uno, visual)
	await esperar_arena()
	gestor.activa.arena.queue_free()
	await cuadros(5)
	comprobar(not gestor.ocupado() and not jugador.is_interacting and visual.visible, "Arena eliminada recupera controles y reserva")

	await preparar()
	var invalida: PackedScene = PackedScene.new()
	var nodo: Node = Node.new()
	invalida.pack(nodo)
	nodo.free()
	uno.escena_arena = invalida
	solicitar(uno)
	comprobar(not gestor.ocupado() and not jugador.is_interacting and uno.ultima_cancelacion == "escena_arena_invalida", "Configuración errónea cancela antes de ejecutar")
	uno.escena_arena = null

	await preparar()
	solicitar(uno)
	gestor.activa.restante = 0.01
	await cuadros(5)
	comprobar(not gestor.ocupado() and not jugador.is_interacting and uno.ultima_cancelacion == "tiempo_limite", "Watchdog libera una ejecución interrumpida")

	await preparar()
	solicitar(dos, visual)
	dos.queue_free()
	await cuadros(5)
	comprobar(not gestor.ocupado() and not jugador.is_interacting and visual.visible, "Propietario destruido no deja reserva ni controles bloqueados")
	await preparar()
	solicitar(uno, visual)
	var otro_mundo: Node3D = Node3D.new()
	root.add_child(otro_mundo)
	current_scene = otro_mundo
	await cuadros(4)
	comprobar(not gestor.ocupado() and not jugador.is_interacting, "Cambio excepcional de mundo cancela la reserva")
	current_scene = mundo
	otro_mundo.queue_free()
	await preparar()
	var original: CharacterBody3D = jugador
	jugador = load("res://scenes/player/player_32.tscn").instantiate()
	mundo.add_child(jugador)
	solicitar(uno)
	jugador.queue_free()
	await cuadros(4)
	comprobar(not gestor.ocupado(), "Objetivo eliminado no deja reserva")
	jugador = original

	# Resultados normales preservan la API enum y restauran antes del callback.
	for resultado in [0, 1]:
		await preparar()
		solicitar(uno, visual)
		await esperar_arena()
		gestor.activa.arena.combate_terminado.emit(resultado)
		await cuadros(40)
		comprobar(resultados == [resultado] and not gestor.ocupado() and not jugador.is_interacting, "Restauración para resultado %s" % resultado)

	await preparar()
	var reserva_fuera = gestor.reservar(uno, jugador, func(): return false)
	comprobar(reserva_fuera == null and not jugador.is_interacting, "Alcance se verifica antes de reservar")
	var transicion: Node = load("res://scripts/world/world_transition.gd").new()
	mundo.add_child(transicion)
	solicitar(uno)
	transicion._iniciar_transicion(jugador)
	comprobar(not transicion._transicionando, "Transición no invade un encuentro activo")
	var conversacion: Node = load("res://scripts/dialogue/interaccion_dialogo.gd").new()
	mundo.add_child(conversacion)
	conversacion.iniciar_dialogo(jugador)
	comprobar(not conversacion._en_dialogo, "Diálogo no invade un encuentro activo")
	transicion.queue_free()
	conversacion.queue_free()

	await preparar()
	jarrito.combate_habilitado = true
	jugador.position = Vector3(2.0, 1, 0)
	for i in 300:
		if gestor.ocupado():
			break
		await cuadros(1)
	comprobar(gestor.ocupado() and jarrito.estado == 3, "Jarrito recorre Idle/Alert/Walk/Encounter e inicia reserva")
	await esperar_arena()
	gestor.activa.arena._intentar_huida()
	await cuadros(140)
	comprobar(jarrito.estado == 0 and not jarrito._solicitando and not jugador.is_interacting, "Jarrito se recupera de huida real con controles restaurados")
	comprobar(jarrito.get_node("FlameAnimationPlayer").is_playing(), "Flame continúa independiente")

	# Dos Jarritos alcanzan el punto de solicitud el mismo frame.
	await preparar()
	jarrito.set_physics_process(false)
	jarrito.position = Vector3(0.8, 0, 0)
	var otro: CharacterBody3D = load("res://scenes/world/Entities/Jarrito.tscn").instantiate()
	otro.position = Vector3(-0.8, 0, 0)
	mundo.add_child(otro)
	otro.set_physics_process(false)
	jugador.position = Vector3(0, 1, 0)
	await cuadros(5)
	jarrito._objetivo = jugador
	otro._objetivo = jugador
	jarrito.estado = 3
	otro.estado = 3
	var anteriores: int = reservas
	jarrito._solicitar_encuentro()
	otro._solicitar_encuentro()
	comprobar(reservas == anteriores + 1 and otro.estado == 0, "Dos Jarritos: uno reserva y el rechazado vuelve a Idle")
	gestor.cancelar(null, "fin_test_doble")
	await cuadros(3)
	comprobar(jarrito.estado == 0 and otro.estado == 0, "Ningún Jarrito queda en Encounter")
	otro.queue_free()
	await preparar()
	jarrito._objetivo = jugador
	jarrito.estado = 3
	jugador.position = Vector3(12, 1, 0)
	await cuadros(3)
	jarrito._solicitar_encuentro()
	comprobar(not gestor.ocupado() and jarrito.estado == 0, "Alejarse durante Encounter cancela antes de reservar")

	# Compatibilidad: el jarrón antiguo sigue cargando y recupera su grupo al cancelar.
	await preparar()
	var pot: CharacterBody3D = load("res://scenes/world/Entities/Pot.tscn").instantiate()
	mundo.add_child(pot)
	pot.set_physics_process(false)
	jugador.position = Vector3(0.5, 1, 0)
	pot._iniciar_evento_combate(jugador)
	comprobar(gestor.ocupado(), "Pot reutiliza el mismo coordinador")
	gestor.cancelar(null, "cancelacion_pot")
	await cuadros(3)
	comprobar(pot.estado != 6 and pot.modelo.visible and not jugador.is_interacting, "Pot recupera estado y visibilidad tras cancelación")
	pot.queue_free()
	await preparar()
	pot = load("res://scenes/world/Entities/Pot.tscn").instantiate()
	var pot_companero: CharacterBody3D = load("res://scenes/world/Entities/Pot.tscn").instantiate()
	pot.combate_grupal = true
	pot_companero.combate_grupal = true
	pot.grupo_jarrones = &"test_grupo"
	pot_companero.grupo_jarrones = &"test_grupo"
	mundo.add_child(pot)
	mundo.add_child(pot_companero)
	pot.set_physics_process(false)
	pot_companero.set_physics_process(false)
	jugador.position = Vector3(0.5, 1, 0)
	pot._iniciar_evento_combate(jugador)
	pot.queue_free()
	await cuadros(5)
	comprobar(not gestor.ocupado() and pot_companero.estado != 6 and pot_companero.modelo.visible, "Grupo Pot se recupera aunque desaparezca su iniciador")
	pot_companero.queue_free()

	mundo.queue_free()
	await cuadros(4)
	comprobar(not gestor.ocupado(), "Sin reservas al liberar el mundo")
	print("RESULTADO: ", fallos, " fallos")
	quit(1 if fallos else 0)
