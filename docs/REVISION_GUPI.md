# Revisión de pruebas Gupi

Revisión del 16 de noviembre de 2026. Se contrastaron el texto y las nueve imágenes de pruebasgupi.docx, fotogramas de ambos videos de WhatsApp y el código del proyecto. Los videos se analizaron visualmente; no se transcribió su audio. Los originales no se modificaron.

## Hallazgos y correcciones

| Evidencia | Causa y cambio | Estado |
|---|---|---|
| Video sin sufijo, 0–15 s: árboles desaparecen al acercarse | La atenuación automática llegaba a 80 %. Se limita a 35 % y se interpola; el árbol conserva su silueta. | Implementado; queda revisión manual de oclusión en todas las cámaras. |
| Video con (1), aproximadamente 0–6 s: salida junto a la roca y caída | Las colisiones individuales no cerraban el perímetro. World y World_Town generan barreras alrededor de la unión de sus suelos, sin cerrar las juntas internas. | Barreras comprobadas con rayos físicos. |
| Caída prolongada al vacío | No había recuperación desde un punto seguro. El protagonista vuelve al último suelo si cae más de ocho unidades. | Prueba de caída pasa en las dos zonas. |
| Documento: cámaras revelan extremos del mapa | El ajuste visual trasladaba las cámaras detrás del jugador. Ahora conserva su posición y solo corrige la orientación cuando el personaje llega al borde del encuadre. | Prueba de posición fija pasa. El encuadre de todos los rincones requiere una pasada manual. |
| Documento: huecos laterales y entrada del pueblo | Añadida extensión de terreno visual sin colisión fuera del área jugable. El suelo del pueblo se extiende además cuatro unidades hacia la cueva para que el perímetro quede detrás del sensor. | Capturas revisadas; entrada a cueva probada moviendo físicamente al jugador. |
| Documento: flores, hierbas y piedras parecen flotar | Se hunde levemente el pie del sprite y se eliminan las sombras proyectadas por los planos de vegetación/decoración que parecían separadas del objeto. | Implementado y revisado en capturas; no se alteran sus colisiones. |
| Documento: protagonista siempre oscuro | Su sprite deja de depender de la iluminación de la normal del billboard. | Implementado; se conservan los colores originales. |
| Documento: texto técnico de mando en tutorial e indicadores | Nuevo formateador de etiquetas a partir del Input Map: stick, cruceta, botones. Tutorial con fondo oscuro, ajuste de línea y ancho adaptable. | Pruebas y captura con mando pasan. |
| Documento: indicaciones de pausa siempre muestran teclado | Las pistas se actualizan según el último dispositivo utilizado y sus bindings. | Prueba y captura con mando pasan. |
| Documento: navegación en escalera en remapeo | Se asignan vecinos de foco explícitos para mantener la columna al subir/bajar y cambiarla con izquierda/derecha. | Verificadas ambas listas. |
| Documento: cama recortada | La geometría era una caja corta; no se encontró recorte de textura. Se alargaron base, colchón y manta dentro del cuarto. | Pruebas de casa pasan. Sigue siendo mobiliario provisional. |
| Documento: texto de vida sobre el marco | Más espacio interior y altura mínima en los paneles de combate. | Captura del combate con tres enemigos revisada. |
| Documento: jarrón permanece tras victoria | Era comportamiento explícito del código. Ahora se retira cada miembro derrotado y se guarda su identificador en GameState. | Victoria, huida, cancelación, regreso al pueblo y Nueva partida probados. Persistencia en memoria, no guardado en disco. |
| Documento: golpe anticipado en ataque especial | La carga reproducía la animación del ataque normal. Se sustituye por reposo durante la preparación. | Corregido en la secuencia; no se cambia el daño ni el comando de acción. |

## Validación ejecutada

- recorrido_fase1_test.gd: recorrido entre zonas y persistencia, sin fallos tras introducir límites.
- casa_fase2_test.gd: 23 pruebas, 0 fallos; tutorial, diálogo, escaleras y progreso.
- grupo_jarrito_test.gd: 0 fallos; contacto, grupo de tres, victoria que elimina, huida y cancelación.
- gupi_review_test.gd: 0 fallos; etiquetas de mando, foco, perímetro, posición de cámara y recuperación de caída. Capturas de casa, pausa, World y World_Town revisadas.
- gupi_persistence_test.gd: cinco comprobaciones, 0 fallos; derrota registrada, desaparición, regreso sin reaparición y reinicio con Nueva partida.
- cave_access_test.gd: acceso físico desde el pueblo a la cueva confirmado. No se invoca directamente la transición.

Las pruebas automatizadas no sustituyen una sesión completa con mando físico. La geometría de cobertura es funcional, pero no representa todavía el acabado artístico del horizonte.

## Sugerencias

1. Mantener las posiciones de cámara diseñadas y revisar sus límites de activación antes de introducir seguimiento. Hacer una pasada manual junto a todas las paredes con relaciones de aspecto 16:9 y 4:3.
2. Sustituir el terreno de relleno visible por una franja de bosque distante, lomas y niebla suave. El suelo extendido evita el vacío, pero su repetición se aprecia detrás de los árboles.
3. Usar glifos específicos para Xbox, PlayStation y Nintendo. Las etiquetas actuales son cortas y siguen el Input Map, pero presentan nombres compartidos.
4. Dar al dormitorio una lámpara de techo con intensidad moderada y mejorar el modelo de cama. Evitar subir toda la luz ambiente: las paredes ya muestran zonas muy luminosas.
5. Añadir un punto de interés al túnel, como cajas, una lámpara o un objeto recogible. Un enemigo debería introducirse junto con la planificación y balance de esa fase.
6. Sustituir las sombras de los planos decorativos por pequeñas sombras de contacto sobre el suelo cuando se cierre la dirección artística. El sprite del protagonista ahora prioriza legibilidad; una iluminación estilizada permitiría integrarlo mejor sin oscurecerlo.

## Sugerencias implementadas

- Bosque distante en World y World_Town reutilizando nordic_pine, fuera del perímetro jugable y sin colisión. Variación determinista de alturas/posiciones y color frío para cubrir el horizonte.
- Etiquetas según el nombre del mando conectado y último dispositivo usado: Xbox, PlayStation y Nintendo. Botones y gatillos en tutorial, pausa y remapeo; un dispositivo no reconocido usa nomenclatura Xbox. Validación de mapeo automatizada; falta prueba física de cada familia, especialmente mandos traducidos por Steam Input.
- Túnel: cuatro faroles, cuatro cajas y cuatro rocas junto a la pared posterior. Relleno cálido localizado; corredor central comprobado libre de colisión.
- Dormitorio: lámpara elevada y relleno suave para iluminar el centro sin aumentar la luz ambiente global.
- Validación: presentation_test.gd sin fallos (20 puntos de encuadre en cinco zonas); suggestions_test.gd sin fallos (familias de mando, decoración y paso central). Capturas de bosque, casa y túnel revisadas en Godot Compatibility.
- Siguen pendientes de pulido: sombras de contacto de decoraciones, mobiliario definitivo y recorrido manual exhaustivo con mando físico en varios formatos de pantalla. No se añadieron enemigos al túnel ni se modificó su progresión.
