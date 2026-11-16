extends Node
## Exclusión de encuentros; la arena y las reglas siguen en EncuentroCombate.
const Sesion = preload("res://scripts/combat/sesion_encuentro.gd")

signal encuentro_reservado(propietario: Node)
signal encuentro_liberado(cancelado: bool, motivo: String)

@export var proteccion_salida: float = 3.0
## Seguro ante corrutinas interrumpidas/errores. Cuenta tiempo de juego, no pausa.
@export var limite_ejecucion: float = 1800.0
var activa: Sesion
var _proteccion: float = 0.0
var _actividades: Dictionary = {} # WeakRef de diálogos/transiciones; no usa su bool.


func ocupado() -> bool:
	return activa != null


func disponible(jugador: CharacterBody3D) -> bool:
	_limpiar_actividades()
	if ocupado() or _proteccion > 0.0 or not _actividades.is_empty() or get_tree().paused:
		return false
	if not _jugador_valido(jugador) or not ("is_interacting" in jugador) or jugador.is_interacting:
		return false
	var gs: Node = get_node_or_null("/root/GameState")
	return gs == null or not gs.hay_transicion_pendiente()


func _jugador_valido(jugador: CharacterBody3D) -> bool:
	if not is_instance_valid(jugador) or not jugador.is_inside_tree() or jugador.is_queued_for_deletion():
		return false
	if not jugador.is_visible_in_tree() or not jugador.can_process() or not jugador.is_physics_processing():
		return false
	var mundo: Node = get_tree().current_scene
	return mundo == null or not mundo.has_method("get_active_player") or mundo.call("get_active_player") == jugador


## Diálogos/transiciones conservan su restauración; únicamente excluyen reservas.
func bloquear_actividad(propietario: Node) -> bool:
	_limpiar_actividades()
	if ocupado() or not is_instance_valid(propietario):
		return false
	if not _actividades.is_empty() and not _actividades.has(propietario.get_instance_id()):
		return false
	_actividades[propietario.get_instance_id()] = weakref(propietario)
	return true


func liberar_actividad(propietario: Node) -> void:
	if is_instance_valid(propietario):
		_actividades.erase(propietario.get_instance_id())


func _limpiar_actividades() -> void:
	for id in _actividades.keys():
		var nodo: Node = _actividades[id].get_ref()
		if not is_instance_valid(nodo) or not nodo.is_inside_tree() or nodo.is_queued_for_deletion():
			_actividades.erase(id)


## Sin await entre validación y asignación: dos solicitudes no pueden reservar.
## validar_alcance se evalúa ANTES de bloquear al jugador, nunca después de ocultarlo.
func reservar(propietario: Node, jugador: CharacterBody3D, validar_alcance: Callable = Callable()) -> Sesion:
	if not is_instance_valid(propietario) or not propietario.is_inside_tree() or not disponible(jugador):
		return null
	if not validar_alcance.is_null() and (not validar_alcance.is_valid() or not validar_alcance.call()):
		return null
	var sesion: Sesion = Sesion.new()
	sesion.propietario = propietario
	sesion.jugador = jugador
	sesion.mundo = get_tree().current_scene
	sesion.camara = get_viewport().get_camera_3d()
	sesion.interaccion_anterior = jugador.is_interacting
	activa = sesion
	jugador.is_interacting = true
	jugador.velocity = Vector3.ZERO
	encuentro_reservado.emit(propietario)
	return sesion


func vigente(sesion: Sesion) -> bool:
	return sesion != null and activa == sesion and not sesion.terminada


func ejecutar(sesion: Sesion, arena: Node) -> void:
	if vigente(sesion):
		sesion.arena = arena
		sesion.fase = Sesion.Fase.EJECUTANDO
		sesion.restante = limite_ejecucion


func cancelar(propietario: Node = null, motivo: String = "cancelado") -> void:
	if activa != null and (propietario == null or activa.propietario == propietario):
		_cerrar(activa, true, motivo)


func finalizar(sesion: Sesion) -> void:
	if vigente(sesion):
		_cerrar(sesion, false, "")


func restaurar_visuales(sesion: Sesion) -> void:
	for entrada in sesion.visuales:
		if is_instance_valid(entrada.nodo):
			entrada.nodo.visible = entrada.visible
	if is_instance_valid(sesion.camara) and sesion.camara.is_inside_tree() and sesion.mundo == get_tree().current_scene:
		sesion.camara.make_current()


func _cerrar(sesion: Sesion, cancelado: bool, motivo: String) -> void:
	if not vigente(sesion):
		return
	sesion.terminada = true
	sesion.cancelada = cancelado
	sesion.motivo = motivo
	sesion.fase = Sesion.Fase.CERRADA
	if cancelado:
		sesion.resultado = 2
	for tween in sesion.tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	for recurso in sesion.recursos:
		if is_instance_valid(recurso) and not recurso.is_queued_for_deletion():
			if recurso is AudioStreamPlayer:
				recurso.stop()
			recurso.queue_free()
	restaurar_visuales(sesion)
	if is_instance_valid(sesion.jugador):
		sesion.jugador.is_interacting = sesion.interaccion_anterior
		sesion.jugador.velocity = Vector3.ZERO
	activa = null
	_proteccion = proteccion_salida
	sesion.finalizada.emit()
	encuentro_liberado.emit(cancelado, motivo)


func _process(delta: float) -> void:
	_proteccion = maxf(0.0, _proteccion - delta)
	_limpiar_actividades()
	if activa == null:
		return
	if not is_instance_valid(activa.propietario) or not activa.propietario.is_inside_tree() or activa.propietario.is_queued_for_deletion():
		cancelar(null, "propietario_eliminado")
		return
	if not _jugador_valido(activa.jugador) or activa.mundo != get_tree().current_scene:
		cancelar(null, "objetivo_o_mundo_invalido")
		return
	if activa.fase == Sesion.Fase.EJECUTANDO and (not is_instance_valid(activa.arena) or activa.arena.is_queued_for_deletion()):
		cancelar(null, "arena_eliminada")
		return
	activa.restante -= delta
	if activa.restante <= 0.0:
		cancelar(null, "tiempo_limite")
