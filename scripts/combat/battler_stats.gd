class_name BattlerStats
extends Resource

## Estadísticas de un combatiente (jugador, aliado o enemigo).
##
## Basado en `BattlerStats` de godot-open-rpg, reducido a lo esencial.
## Se edita desde el Inspector (en la escena del battler) o guardándolo como .tres
## en `data/bestiary/` para reutilizarlo entre varios enemigos.
##
## Fórmula de daño actual (ver BattlerAction.calcular_danio):
##     daño = max(1, poder_accion + ataque_origen - defensa_objetivo) + bonus_comando
##
## TODO (a futuro): elementos/afinidades (README: "Elementos"), FP/flor, insignias,
## estados alterados, crecimiento por nivel, etc.

## Puntos de vida máximos
@export var max_hp: int = 10
## Daño base que suma a cada acción ofensiva
@export var ataque: int = 1
## Resta al daño recibido
@export var defensa: int = 0
## Orden de turno: actúa antes quien tenga más velocidad (empate: aliados primero)
@export var velocidad: int = 10
