class_name BattlerAction
extends Resource

## Acción que un battler puede ejecutar en su turno (atacar, esquivar, objeto, habilidad...).
##
## Basado en `BattlerAction` de godot-open-rpg: cada acción es un Resource con su propia
## lógica en `ejecutar()`. Para crear una acción nueva:
##   1. Crea un script en `scripts/combat/acciones/` que haga `extends BattlerAction`.
##   2. Sobrescribe `ejecutar()` (puede usar `await` todo lo que necesite).
##   3. Añádela al array `acciones` del battler desde el Inspector.
##
## Dentro de `ejecutar()` la arena ofrece utilidades: `arena.comando` (comandos de acción
## estilo Paper Mario), `arena.mostrar_numero()`, `arena.mostrar_mensaje()`,
## `arena.sacudir_camara()`, `arena.reproducir_sonido()`, `arena.esperar()`.

enum Objetivo {
	ENEMIGO,        ## Un enemigo a elegir
	TODOS_ENEMIGOS, ## Todos los enemigos vivos
	ALIADO,         ## Un aliado a elegir (curar, etc.)
	UNO_MISMO,      ## Solo quien la usa (defender, cargar...)
}

## Texto del botón en el menú de combate
@export var nombre: String = "Acción"
## Descripción corta (se muestra al seleccionar la opción en el menú)
@export_multiline var descripcion: String = ""
@export var objetivo: Objetivo = Objetivo.ENEMIGO
## Daño base propio de la acción (se suma al ataque del battler)
@export var poder: int = 0

## Lógica de la acción. Se espera con `await accion.ejecutar(...)`.
## Debe dejar al battler de vuelta en su posición base al terminar.
func ejecutar(_origen: Battler, _objetivos: Array[Battler], arena: Node) -> void:
	push_warning("La acción '%s' no sobrescribe ejecutar()." % nombre)
	await arena.esperar(0.1)

## ¿Necesita que el jugador elija un objetivo concreto?
func requiere_elegir_objetivo() -> bool:
	return objetivo == Objetivo.ENEMIGO or objetivo == Objetivo.ALIADO

## Fórmula de daño común. `bonus` suele venir de un comando de acción acertado.
static func calcular_danio(origen: Battler, objetivo_battler: Battler, poder_accion: int, bonus: int = 0) -> int:
	var base: int = poder_accion + origen.stats.ataque - objetivo_battler.stats.defensa
	return maxi(1, base) + bonus
