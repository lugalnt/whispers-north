# Coordinación compartida de encuentros

`CoordinadorEncuentros` es un autoload de `scripts/combat/coordinador_encuentros.gd`.
No reemplaza CombatArena, Battler, GameState ni EncuentroCombate. Serializa el acceso
a la arena existente y posee la restauración común del supramundo.

## Contrato y fases

1. **Disponibilidad:** jugador válido, visible, activo, sin `is_interacting`, sin
   diálogo/transición registrado, sin transición pendiente en GameState, sin pausa
   y sin protección temporal de salida.
2. **Reserva:** `reservar()` comprueba un Callable opcional de alcance y asigna un
   ticket exclusivo sin ningún await. Solo después pone `is_interacting = true`.
3. **Ejecución:** EncuentroCombate prepara y ejecuta la misma CombatArena de antes.
4. **Finalización:** se sincroniza HP como antes, se devuelve la cámara y se
   restauran visibilidades y controles anteriores. La arena sigue otorgando EXP;
   EncuentroCombate sigue otorgando sus ítems. No se duplican recompensas.
5. **Cancelación:** cierre idempotente; mata tweens, libera arena/cortina/jingle y
   restaura lo que pertenece a esa sesión, sin otorgar recompensas del componente.

El ticket (`sesion_encuentro.gd`) tiene señal `finalizada`, resultado, motivo y
estado de cancelación. Las esperas no dependen exclusivamente de señales de una
arena que podría desaparecer. El supervisor cancela ante eliminación del
propietario/objetivo/arena, cambio de mundo o tiempo límite. Las fases de
preparación/salida tienen 15 segundos; ejecución admite 1800 segundos de juego,
configurables en `limite_ejecucion`. La pausa detiene este reloj.

GDScript no permite capturar arbitrariamente todos los errores de ejecución:
las configuraciones inválidas de arena/battlers se rechazan anticipadamente y
el supervisor limita las esperas si una corrutina deja de avanzar. Un bloqueo
completo del motor no puede recuperarse desde `_process`.

## API para enemigos

```gdscript
var resultado = await encuentro.iniciar_combate(jugador, visual, sigue_en_alcance)
```

Los dos primeros argumentos y el enum de retorno son compatibles con el código
existente. El tercer argumento es un Callable sin argumentos que devuelve bool.
Se evalúa justo antes de reservar; no se vuelve a exigir alcance una vez aceptado
el encuentro y congelado el jugador. Los disparadores Area3D automáticos, Pot y
Jarrito proporcionan esta comprobación. Un disparador narrativo puede omitirla.

- `encuentro_rechazado(motivo)`: no se obtuvo reserva; no altera controles.
- `reserva_confirmada(sesion)`: permite registrar visuales de enemigos agrupados.
- `combate_iniciado()`: la arena está preparada.
- `combate_terminado(resultado)` y victoria/derrota/huida: resultado normal.
- `combate_cancelado(motivo)`: interrupción, separada de la señal de huida.
- `cancelar_combate(motivo)`: cancela solo la reserva de este componente.

Rechazos y cancelaciones devuelven HUIDA por compatibilidad con consumidores
antiguos; las nuevas señales distinguen esos casos. `ultima_cancelacion` describe
la última sesión cancelada (se reinicia al aceptar otra reserva).

El coordinador aplica 3 segundos de protección compartida después del cierre.
No sirve como cola: una solicitud rechazada debe recuperarse y volver a evaluar
disponibilidad más adelante. No se deben desbloquear controles desde la rama de
rechazo, pues podrían pertenecer a otro encuentro, diálogo o transición.

## Diálogos, transiciones y restauración

InteraccionDialogo y WorldTransition registran su actividad con referencias
débiles. Mantienen sus mecanismos de bloqueo/restauración propios. Ninguno puede
adquirir actividad mientras exista un encuentro; el coordinador no modifica sus
flags ni usa un booleano de combate para representar diálogos.

El bloqueo previo mediante `is_interacting` también se respeta, incluidos los
fundidos de entrada de World y World_Town. Si se elimina un dueño de actividad,
su referencia se retira. El error al cambiar de escena libera el bloqueo de la
transición y sus datos de aparición pendientes.

EncuentroCombate conserva la visibilidad **anterior**, incluso si era false.
Pot conserva sus reglas de destrucción/respawn, pero ya no libera a ciegas un
bloqueo ajeno al recibir HUIDA. Los integrantes de su grupo registran su visual y
su recuperación ante cancelación, incluso si desaparece el iniciador.

## Jarrito

Jarrito incluye un hijo EncuentroCombate configurable. De momento reutiliza
PotBattler, el combatiente existente; no se ha creado un battler artístico nuevo.

La animación Encounter es una anticipación sin reserva: el jugador puede escapar.
Al terminar, se vuelve a comprobar EncounterArea y la disponibilidad. Rechazo,
cancelación, huida o derrota devuelven a Idle con `tiempo_recuperacion` (3 segundos).
Victoria mantiene al enemigo en escena pero desactiva nuevas detecciones mediante
su estado de derrotado. No implementa persistencia de derrota entre cambios de mapa.
`inicio_combate` ahora notifica el inicio aceptado, no debe conectarse a otro
ejecutor que intente iniciar una segunda arena.

Idle/Alert/Walk/Encounter y los dos reproductores independientes de cuerpo/Flame
conservan sus recursos fuente. La configuración de recuperación no altera arte.

## Validación

Ejecutar desde la raíz del proyecto:

```text
godot --headless --path . --script res://tests/encuentros_test.gd
```

Pruebas automáticas: exclusión de dos componentes y dos Jarritos; entrada de
diálogo y actividad sin bloqueo físico; restauración de controles y visibilidad;
huida real de CombatArena; resultados victoria/derrota por señal; cancelación
idempotente; arena inválida; propietario/objetivo/arena eliminados; cambio de mundo;
watchdog; alcance; recuperación de Jarrito y grupos Pot; fuego independiente.

La prueba de diálogo sin recurso genera una advertencia esperada y verifica su
finalización. Las pruebas de victoria/derrota inyectan el resultado; no validan
el balance ni un combate completo ganado/perdido manualmente.

Validación visual pendiente: F6 en JarritoTest, huir mediante la UI, cámaras,
fundidos, audio y pausa; colocar dos instancias en World_Town; mantener un diálogo
abierto mientras se acercan; cruzar WorldTransition antes/después del combate;
completar victoria y derrota con la UI y comprobar las reglas propias de Pot.
