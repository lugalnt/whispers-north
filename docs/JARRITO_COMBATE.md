# Jarrito en combate

## Estado vigente — 16 de noviembre de 2026

World_Town inicia una arena con los tres Jarritos; World conserva uno individual. El contacto físico inicia sin esperar las animaciones de alerta. PlayerBattler usa 32 × 32 y los cuadros coloreados 8–14 de `assets/sprites/player/movimiento/16x32 Attack.aseprite`, exportados a `finn_punch.png/json` y expuestos como `punch_down_site`. El margen inferior de Jarrito se compensa en su apoyo visual y se alinea en profundidad con el protagonista al atacar. Cámara base (0, 7.6, 12), inclinación -30°, FOV 44; enemigos separados en profundidad. Nuevo panorama y cielo integrados en la arena. Última prueba registrada de `grupo_jarrito_test.gd`: 16 de noviembre, cero fallos. Las validaciones fechadas del apartado inferior corresponden a la integración inicial.

La exportación encontrada es `assets/creatures/Jarro/combat/Jarro_Combat.png`
y su JSON homónimo (no `Jarrito_Combat`). PNG RGBA de 1216×64, con píxeles
transparentes y parcialmente opacos. Los 19 cuadros son regiones completas
de 64×64, sin rotación ni recorte. Los originales se conservan.

`data/combat/jarrito_frames.tres` contiene AtlasTexture reutilizables y traduce
las etiquetas Idle/Attack/Hurt/Defeat del JSON a idle/attack/hurt/defeat.

| Animación | Índices | Duraciones por cuadro (ms) | Bucle |
|---|---|---|---|
| idle | 0–3 | 150, 130, 150, 130 | Sí |
| attack | 4–9 | 150, 180, 180, 70, 100, 170 | No |
| hurt | 10–12 | 70, 110, 160 | No |
| defeat | 13–18 | 120, 130, 100, 100, 180, 300 | No |

SpriteFrames usa 10 FPS y pesos `duration_ms / 100`: representa todas las
duraciones del JSON sin redondearlas a una tasa uniforme. La presentación
temporal queda limitada por los frames de renderizado y speed_scale del motor.
Si se reexporta el atlas, actualizar regiones/pesos y tiempos de impacto de la
acción; el test compara el recurso persistente con el JSON.

JarritoBattler usa AnimatedSprite3D con Nearest, alpha mezclado (sin recorte
de alpha), billboard Y como PlayerBattler y pixel_size 0.04 (lienzo de 2.56
unidades). Se conserva el margen transparente original y el ajuste al suelo
de Battler. La orientación nativa se declara hacia la izquierda; la arena
aplica mirar_al_frente. La respiración procedural está desactivada.

La subclase mantiene la API Battler y evita que hurt/idle/attack interrumpan
defeat. La derrota conserva el último cuadro hasta liberar la arena. No hay
vínculo entre HP y la llama, que está integrada en cada cuadro exportado.

La acción exclusiva se aproxima, reproduce los 850 ms de attack completos,
embiste 0.6 unidades tras 510 ms de anticipación, aplica el daño normal y vuelve
a base. Invoca ComandoAccion al empezar attack, con impacto a los 680 ms,
indicador visible sobre el objetivo y ventana de 220 ms antes / 60 ms después.
Usa `interact` del Input Map (teclado y gamepad). Acertar inicia el salto del
objetivo y evita el daño; no pulsar o anticiparse aplica daño normalmente.
El indicador y las ventanas se pueden configurar en el recurso de la acción.
PotBattler y su acción
original siguen disponibles. Desde la integración inicial también se actualizaron Battler, CombatArena y la exploración para el apoyo visual, ataque, formación y grupos; el GLB fuente se conserva.

## Validación

Ejecutar `godot --headless --path . --script res://tests/jarrito_combat_test.gd`.
También ejecutar `tests/encuentros_test.gd` y `tests/recorrido_fase1_test.gd`.

Prueba manual: abrir `scenes/combat/tests/JarritoCombatTest.tscn` y ejecutar F6.
Revisar escala frente a Finn, pies/sombra y márgenes, orientación hacia el jugador,
nitidez y alpha. Dejar actuar a Jarrito, golpearlo y derrotarlo; observar attack
completo, hurt y último cuadro de defeat sin retorno a idle. En JarritoTest del
mundo, comprobar transición, huida y restauración del modelo 3D y su llama.
Comprobar también el indicador de esquive con teclado y gamepad, salto al acertar
y daño al pulsar demasiado pronto o dejar pasar la ventana. El test automatizado
cubre estos tres resultados mediante la acción `interact`.

Validación realizada (Godot 4.7.2, 2026-11-12): las tres suites finalizaron
con 0 fallos. También pasó la suite de Jarrito con renderizado OpenGL; captura
inspeccionada en `.godot/jarrito_combat_preview.png`, con sprite completo,
transparencia y píxeles nítidos junto a Finn. Para regenerarla, ejecutar el test
sin `--headless`, con `--rendering-method gl_compatibility` y añadir
`-- --capture`. Queda pendiente la revisión manual del ritmo y escala artística.
La importación headless reportó UID duplicados en sprites de Erland/otros sprites
del jugador ajenos a Jarrito; encuentros emite el aviso esperado de diálogo sin
configurar de su caso de prueba. No se cambiaron esos recursos.
