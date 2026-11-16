extends RefCounted
## Ticket exclusivo. Persiste hasta que todos los consumidores reciban el cierre.
signal finalizada

enum Fase { RESERVADA, EJECUTANDO, FINALIZANDO, CERRADA }
var fase: Fase = Fase.RESERVADA
var propietario: Node
var jugador: CharacterBody3D
var mundo: Node
var camara: Camera3D
var interaccion_anterior: bool = false
var terminada: bool = false
var cancelada: bool = false
var motivo: String = ""
var resultado: int = 2 # CombatArena.ResultadoCombate.HUIDA (compatibilidad).
var restante: float = 15.0
var arena: Node
var recursos: Array[Node] = []
var tweens: Array[Tween] = []
var visuales: Array[Dictionary] = []


func recordar_visual(nodo: Node) -> void:
	if not is_instance_valid(nodo) or not ("visible" in nodo):
		return
	for entrada in visuales:
		if entrada.nodo == nodo:
			return
	visuales.append({"nodo": nodo, "visible": nodo.visible})


func registrar_resultado(valor: int) -> void:
	if not terminada and fase == Fase.EJECUTANDO:
		resultado = valor
		fase = Fase.FINALIZANDO
		restante = 15.0
