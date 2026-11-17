# Avance de Implementación de la Demo (`plandeescenasWOTN.docx`)

## Correcciones de pruebas Gupi — 16 de noviembre de 2026

Revisión de dos videos y pruebasgupi.docx. Detalles, validaciones y recomendaciones en [REVISION_GUPI.md](REVISION_GUPI.md).

- Límites físicos alrededor de los suelos de World y World_Town, cobertura visual exterior y recuperación ante caídas; acceso físico a la cueva verificado.
- Las cámaras mantienen su posición; ajuste de orientación al borde del encuadre. Este comportamiento sustituye el desplazamiento automático documentado anteriormente.
- Atenuación de vegetación reducida a 35 % con transición gradual; apoyo ligeramente hundido y sombras de planos desactivadas. Protagonista sin sombreado del billboard para preservar sus colores.
- Indicaciones compactas de mando en tutorial, diario y pausa; navegación vertical estable en remapeo. Cama alargada y márgenes del HUD de combate ampliados.
- Jarritos retirados tras victoria y derrota recordada al regresar al mapa; Nueva partida los restaura. Se elimina el puñetazo anticipado de la carga de Barrida Vórtice.
- Pruebas de recorrido, casa, grupo, revisión Gupi, persistencia y acceso físico a cueva sin fallos. Pendientes de pulido: horizonte, sombras de contacto y revisión manual exhaustiva de cámaras con mando.


## Erland integrado — 16 de noviembre de 2026

- Sustituido el sprite provisional del padre en World_House por las cuatro vistas estáticas de nordic_v1, con orientación hacia el protagonista cercano y ajuste de pivote/altura.
- Retrato nuevo conectado a sus diálogos iniciales y posteriores; se conservan textos y progresión.
- Validación: captura del diálogo revisada en Godot Compatibility y casa_fase2_test.gd con 23 pruebas, 0 fallos, sin errores del controlador visual.
- Pendiente: el paquete no contiene animaciones de caminar/interacción. Los PNG originales se conservan sin modificación.


## Integración de casas y caminos — 16 de noviembre de 2026

- World_Town: 13 casas sustituidas por CasaRoja, CasaEntramado y CasaPorche; escala, orientación y apoyo ajustados. Colisión incluida en los modelos. Puertas decorativas sin nuevos interiores.
- World y World_Town: cinco escenas de caminos migradas a nordic_path_v1, con 1218 celdas conservadas y tamaño físico compensado al pasar de 8 a 32 px por tile.
- Validación ejecutada: render de ambas zonas con decoration_preview.gd e inspección de capturas; recorrido_fase1_test.gd sin fallos. No equivale a un recorrido manual de cada fachada.
- Pendiente artístico: variaciones de grano/uniones del tileset y nieve acumulada. La casa del protagonista conserva su exterior y transición existentes.


Registro de avance por fases para la demo jugable de **Whispers of the North**, siguiendo el recorrido:
**Casa (`World_House`) → Vecindad (`World`) → Pueblo (`World_Town`) → Cueva (`World_Cave`) → Bosque y ruinas (`World_ForestRuins`) → Jefe → Final de demo**.

---

## Estado vigente — 16 de noviembre de 2026

El proyecto es una demo en desarrollo en Godot 4.7.2, renderizador GL Compatibility. Este resumen prevalece sobre las decisiones fechadas del historial inferior. Implementado no equivale a arte final ni a validación manual completa.

| Fase | Estado actual | Trabajo restante |
| --- | --- | --- |
| 0 — Baseline | Completada | Conservar el historial de pruebas y avisos previos. |
| 1 — Recorrido y estado | Implementada: cinco zonas conectadas de ida y vuelta | Recorrido manual exhaustivo; el estado entre mapas vive en memoria, no es guardado en disco. |
| 2 — Casa | Implementada: diario/tutorial, muebles provisionales, escalera, progenitor y salida | Arte definitivo, revisión auditiva y recorrido con mando físico. |
| 2.5A — Inventario de exploración | Implementada | Revisar excedentes entregados directamente por NPC/cofres/combate. Los pickups conservan sobrantes. |
| 2.5B — Objetos en combate | Pendiente | Selección, objetivo, cancelación y gasto de turno/consumible. |
| 2.5C — Organización y persistencia | Parcial: nueve iconos nórdicos integrados | Filtros y guardado/carga de partida completa. |
| 3 — Vecindad y pueblo | Parcial: mapas, Jarritos, persecución, grupo, decoración e iluminación | Contenido narrativo, recompensa única del NPC, justificación del arbusto y pulido de colisiones/encuadres. |
| 4 — Cueva | Parcial: túnel, cámaras, transiciones y materiales | Encuentro, cofre oculto, botín y relieve definitivo. |
| 5 — Bosque y ruinas | Parcial: trazado, cámaras, marcadores y decoración/materiales | Arquitectura, cuatro tesoros, encuentros y progresión interactiva. |
| 6 — Jefe y final | Pendiente | Jefe, objeto narrativo y secuencia/pantalla final. |
| 7 — Pulido | Parcial: interfaz, cámara, iluminación y assets | Balance, mando/audio, recorrido integral y arte final. |

### Comportamiento actual

- Nueva partida comienza en `World_House.tscn` y reinicia HP, inventario, acompañante y progreso. Ruta: Casa → World → World_Town → World_Cave → World_ForestRuins.
- Un Jarrito en World; tres en el pueblo unidos a `trio_jarritos_pueblo`. Detectan a 9 m, persiguen a velocidad 3.4, abandonan a 18 m y regresan al origen; hay línea de vista configurable y sonido de detección. El contacto físico inicia el encuentro sin esperar Alert/Encounter. No hay navegación alrededor de laberintos.
- Combate con protagonista de 32 × 32 y ataque coloreado `punch_down_site`, siete cuadros 8–14 de `16x32 Attack.aseprite`. Cámara base (0, 7.6, 12), inclinación de 30° hacia abajo y FOV 44; formación separada en profundidad y encuadre automático.
- Inventario de exploración con consumo útil, cantidades/límites y foco conservado. Espada, hacha y monedas son recursos de inventario; no implementan equipamiento ni economía. El pool general conserva fragmento, queso y llave.
- Presentación: opciones legibles, pausa adaptable, apoyo visual de vegetación, protección de encuadre y atenuación de vegetación que tapa al jugador. La corrección de apoyo no rehace colisiones de árboles; todavía pueden existir oclusiones por edificios.
- Decoración: 28 instancias alrededor de la casa y 42 en el pueblo. Casa con cinco faroles visibles; sol y ambiente equilibrados en vecindad, pueblo y bosque.
- Assets: 47 PNG nórdicos en ocho paquetes con referencias en escenas/scripts/recursos, incluidos materiales y temas. Panorama nuevo en World, World_Town y CombatArena, con escala adaptada y cielo de soporte en combate. Detalle y límites en [ASSETS_INTEGRACION.md](ASSETS_INTEGRACION.md).

### Validación disponible y límites

Esta actualización es documental: contrasta archivos y resultados registrados; no vuelve a ejecutar las suites ni declara nuevos resultados.

| Evidencia | Última ejecución registrada en este trabajo |
| --- | --- |
| `recorrido_fase1_test`, `casa_fase2_test`, `inventario_fase25_test`, `encuentros_test`, `assets_nordic_test`, `presentation_test` | 14 de noviembre: cero fallos funcionales; casa 23 comprobaciones e inventario 20. |
| `grupo_jarrito_test` | 16 de noviembre, tras integrar el panorama: cero fallos. Comprueba contacto, grupo, encuadre y restauración; inyecta resultados y no evalúa balance manual. |
| `decoration_preview`, `lighting_preview` | 16 de noviembre: escenas cargadas y capturas revisadas en Compatibility. Son ayudas visuales, no suites de aserciones. |
| Mando físico, audio y recorrido completo | Pendientes de revisión manual. Las capturas y muestras de cámara no cubren todos los puntos del mapa. |

Avisos conocidos: referencias de audio `snd_item.wav` retenidas al cerrar la prueba de inventario y UID duplicados de Erland/plantilla durante la importación. No confundir cero fallos funcionales con cierre sin advertencias.

Pendientes de arte: atlas de casas y caminos, árboles frondosos/variantes nevadas, mobiliario y retratos definitivos, relieve y arquitectura de ruinas, jefe/final. La fuente conserva el chorro con forma de cúpula. El panorama nuevo sustituye el fondo repetido anterior, pero no está certificado como seamless para cualquier ángulo.

Siguiente trabajo funcional recomendado: Fase 2.5B (consumibles en combate), seguida del contenido pendiente de Fase 3. No se ha completado una fase narrativa por integrar su decoración.

---

## Historial de implementación

Las secciones siguientes conservan las decisiones y resultados de cada entrega. Las configuraciones antiguas de cámara, ataque blanco, trío individual y detección quedan sustituidas por el resumen vigente y las correcciones posteriores.

## Plan actualizado: inventario integrado (13 de noviembre de 2026)

Se intercala la Fase 2.5 sin renumerar las fases de escenarios. Fases 0–2 implementadas; se conserva la revisión manual pendiente de casa, mando y audio.

| Fase | Alcance | Estado |
| --- | --- | --- |
| 2.5A — Inventario de exploración | Cantidades seguras, consumo útil, información del menú, recogida parcial y pruebas | Implementada |
| 2.5B — Objetos en combate | Seleccionar consumible y objetivo, gastar turno solo al confirmar, sincronizar cantidades y HP, cancelar sin consumo | Pendiente |
| 2.5C — Organización y persistencia | Filtros por categoría, iconos definitivos, guardado/carga integrado con la partida completa | Pendiente |
| 3 — Vecindad y pueblo | Contenido previsto más entrega única de recompensas de NPC y tratamiento de excedentes | Pendiente |
| 4 — Cueva | Encuentro y cofre con contenido definido; comprobar capacidad y conservación de botín | Pendiente |
| 5 — Bosque y ruinas | Tesoros, objetos clave y uso contextual para progresión | Pendiente |
| 6 — Jefe y final | Objeto importante del desenlace, recompensas únicas y validación de progresión | Pendiente |
| 7 — Pulido | Balance de curación/botín, presentación, mando físico y recorrido completo | Pendiente |

### Fase 2.5A — Resultado

- Inventory.agregar y GameState.agregar_item devuelven las unidades realmente aceptadas; límites y cantidades inválidas se controlan. Quitar más unidades de las disponibles no modifica la pila.
- Lista ordenada por categoría y nombre, con registros independientes de los datos internos.
- Consumo en exploración: no gasta comida con HP completo ni la usa para revivir; los objetos clave no se consumen. Cura hasta el máximo y retira exactamente una unidad.
- Menú: cantidad/límite, curación efectiva, botón deshabilitado con motivo cuando no procede, nombre/cantidad al pasar el cursor y conservación de selección al actualizar. Elimina las casillas antiguas de la cuadrícula antes de reconstruirla.
- Recogibles: solo el protagonista activo puede recogerlos. El sobrante permanece en el suelo si la pila llega al límite; con pila llena no desaparecen. Tras liberar espacio se puede volver a acercar o interactuar. La notificación indica la cantidad realmente recibida. Un recogible sin recurso no se convierte silenciosamente en queso.
- En esa entrega se conservó el arte provisional; posteriormente se integraron nueve iconos nórdicos. El inventario inicial se conserva. No se presenta el guardado aislado del recurso Inventory como guardado completo de partida.
- Los excedentes de recompensas entregadas directamente por cofres/NPC/combate quedan para la integración posterior; esta entrega garantiza conservación en los recogibles del mundo.

Validación: tests/inventario_fase25_test.gd cubre 20 comprobaciones de cantidades, consumo, menú real, foco, recogida parcial, exclusión de enemigos y Nueva partida. Se inspeccionó captura renderizada del menú. Prueba manual sugerida: perder vida en combate, abrir pausa, usar queso, comprobar curación y que no permite desperdiciarlo con HP completo.

## Fase 0 — Baseline

### 1. Ejecutable Godot y pruebas base
- **Ejecutable localizado:** `C:\Users\angel\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe` (`Godot Engine v4.7.2.stable.official.ed1daf0bf`, compatible con `config/features = ["4.7", "GL Compatibility"]`).
- **Ejecución de pruebas existentes (`res://tests/encuentros_test.gd`):**
  - Comando: `godot --headless --path . --script res://tests/encuentros_test.gd`
  - Resultado: **34 PASS, 0 fallos**.
  - Advertencia esperada del propio test: `WARNING: InteraccionDialogo en '@Area3D@15' no tiene diálogo configurado.`
- **Separación de errores previos vs. introducidos:**
  - *Previo:* al cerrar `MainMenu.tscn` en modo headless aparece `WARNING: 2 ObjectDB instances were leaked at exit` / `ERROR: 1 resources still in use at exit`.
  - *Previo (corregido en Fase 1):* `CameraSwitchManager._ready()` forzaba `Camera1` mediante `call_deferred` incluso cuando una transición de mundo acababa de activar otra cámara de llegada; y `WorldTransition._asegurar_colision()` compartía el subrecurso `BoxShape3D` del prefab entre instancias de una misma escena.
  - *Introducidos:* **0 errores**.

### 2. Estado inicial por requisito de `plandeescenasWOTN.docx`

| Escena / Sistema | Requisito del documento (incl. imágenes incrustadas) | Estado en Baseline (Fase 0) | Estado tras Fase 1 |
| :--- | :--- | :--- | :--- |
| **Recorrido global** | Conectar Casa → Vecindad → Pueblo → Cueva → Bosque y ruinas (ida y vuelta) | **Parcial** (solo `World` ↔ `World_Town`) | **Implementado** (5 zonas conectadas con `WorldTransition`) |
| **Progresión y Nueva partida** | Estado persistente entre mapas (tutorial, recompensas únicas, cofres, encuentros, jefe) y reinicio en Nueva partida | **Parcial** (`GameState` guardaba stats, HP, inventario, rata y acciones, pero no banderas de mundo ni reiniciaba en Nueva partida) | **Implementado** (`GameState.progreso`, `reclamar_unico()`, `nueva_partida()` conectado en `MainMenu.gd`) |
| **Escena 1: Interior Casa (`World_House.tscn`)** | Cuarto (Cámara 1) + Planta baja (Cámara 2) como cubos interiores que oculten el exterior | **Pendiente** (no existía escena) | **Parcial (base geométrica, cámaras y transiciones listas en Fase 1)** |
| **Escena 1: Interior Casa** | Muebles (cama, ropero, cajas, espejo, mesa/diario), tutorial de controles 1 vez, transición con pasos/delay y charla con progenitor | **Pendiente** (`Door.tscn` solo alternaba sprite 16x16/32x32) | **Pendiente (Fase 2)** |
| **Escena 2: Vecindad (`World.tscn`)** | Terreno, casa exterior, cámaras, encuentro con Pot, cofre con rata, arbusto teletransportador y salida al pueblo | **Parcial** (prototipada y jugable; usa switches antiguos `SwitchC_*`) | **Parcial** (conectada además con `World_House.tscn`; ajustes visuales/narrativos en Fase 3) |
| **Escena 2: Vecindad** | Mejoras de iluminación, colisiones de árboles, encuadre de Fire Mountain, esconder rata, justificar arbusto | **Pendiente** | **Pendiente (Fase 3)** |
| **Escena 3: Pueblo (`World_Town.tscn`)** | Calles, casas placeholder, fuente, `CameraSwitch`, 3 NPCs de prueba y trío de Pots | **Parcial** (falta salida hacia cueva a la derecha; diálogos de prueba; recompensa de `Npc_Util` repetible al recargar) | **Parcial** (añadida salida derecha a `World_Cave.tscn` con `Camera12` y `Switch_11_12`; ajustes de NPCs/decoración en Fase 3) |
| **Escena 4: Pasaje de Cueva (`World_Cave.tscn`)** | Túnel recto oscuro iluminado por grietas, cámaras sucesivas, rocas, encuentro y cofre oculto | **Pendiente** (no existía escena) | **Parcial (túnel, 4 cámaras, iluminación base y transiciones listas en Fase 1; rocas, encuentro y cofre en Fase 4)** |
| **Escena 5: Bosque y Ruinas (`World_ForestRuins.tscn`)** | Mapa del boceto incrustado (`image1.png`): entrada inferior izquierda, bifurcaciones, 5 áreas de ruinas, 4 tesoros, encuentros y ruta al jefe arriba a la derecha | **Pendiente** (no existía escena) | **Parcial (trazado del mapa del DOCX, 10 cámaras y marcadores de referencia listos en Fase 1; ruinas interactivas, cofres y encuentros en Fase 5)** |
| **Desenlace: Jefe y Final** | Arma/objeto importante en el extremo derecho, secuencia breve, combate de jefe y pantalla de final de demo | **Pendiente** | **Pendiente (Fase 6)** |
| **Presentación y Relieve** | Relieve/vegetación sobre superficies de pasto compatible con `gl_compatibility` y pulido general | **Pendiente** | **Pendiente (Fase 7)** |

### 3. Recursos visuales locales aprovechables e inventario de faltantes
- **Aprovechables en el repositorio:**
  - *Personajes:* `player.tscn` (16x16), `player_32.tscn` (16x32), `placeholder_npc.tscn`, hojas de sprites en `assets/sprites/player/Finn (Prota)/` y `assets/sprites/player/Erland (Padre)/`.
  - *Criaturas y combate:* `Pot.tscn`, `Jarrito.tscn` (`assets/creatures/Jarro/model/Jarron_3D.glb`), `PotBattler.tscn`, `PlayerBattler.tscn`, `CombatArena.tscn`.
  - *Entorno y materiales:* `pokemon_grass.png`, `dirtpath.png`, `rock01_snow_c.png` / `rock01_snow_n.png`, `woodTexture.png`, `lightwood_wall.png`, `darkwood_wall.png`, `creamwall.png`, `redroof.png`, `puerta.png`, `window.png`, `Tree.tscn`, `Tree_Pine.tscn`, `Bush.tscn`, `Chest.tscn`, `Fountain.tscn`, casas (`House_Cianwood`, `House_Violet`, `House_Pastoria`) y `fire_mountain.tscn`.
  - *Ítems y pools:* `fragmento_ceramica.tres`, `queso_nordico.tres`, `llave_antigua.tres`, `pool_mundo_general.tres`.
- **Faltantes (requieren geometría/materiales/recursos provisionales documentados):**
  - Modelos 3D de mobiliario interior (cama, ropero, cajas, mesa, diario, espejo) y de columnas/arcos de ruinas estilo Pokémon DP (`image2.png`).
  - Recurso `InventoryItem` del objeto/arma importante del desenlace y `Battler` propio para el jefe final.
  - Packs externos de Itch.io mencionados en el documento (no presentes en el repositorio).
- **Decisiones provisionales adoptadas:**
  - Nombre oficial confirmado por el usuario el 17/11/2026: `"Finn"`, aplicado globalmente en juego y documentación.
  - Conservar el inicio de Nueva partida en `World.tscn` durante la Fase 1 y conmutarlo a `World_House.tscn` al completar y validar la Fase 2.

---

## Fase 1 — Recorrido y Estado

### 1. Resultado implementado y archivos afectados

#### Archivos nuevos
- [scripts/world/zona_mundo.gd](C:/Users/angel/Documents/GitHub/whispers-north/scripts/world/zona_mundo.gd): controlador base `ZonaMundo` reutilizado por `World_House`, `World_Town`, `World_Cave` y `World_ForestRuins`. Gestiona la instancia de `PauseMenu` (acción `pause`), recepción de `WorldTransition` (posición por marcador, activación de cámara, restauración de la rata acompañante y fundido de entrada), registro de `GameState.zona_actual` y arranque limpio sin transición (`F6` o Nueva partida).
- [scenes/world/World_House.tscn](C:/Users/angel/Documents/GitHub/whispers-north/scenes/world/World_House.tscn): escena interior de la casa con dos estancias separadas (`Cuarto` con `Camera1` y `PlantaBaja` con `Camera2`), colisiones cerradas, `CameraSwitch` en modo `ZONA_FIJA` y `WorldTransition` entre plantas y hacia la vecindad (`World.tscn`).
- [scenes/world/World_Cave.tscn](C:/Users/angel/Documents/GitHub/whispers-north/scenes/world/World_Cave.tscn): pasaje subterráneo recto a lo largo del eje `+X` con colisiones, iluminación de bocas y grietas superiores, 4 cámaras sucesivas (`Camera1`..`Camera4` con `ZonaCam_1`..`ZonaCam_4`), marcadores de referencia para la Fase 4 y `WorldTransition` hacia `World_Town.tscn` (oeste) y `World_ForestRuins.tscn` (este).
- [scenes/world/World_ForestRuins.tscn](C:/Users/angel/Documents/GitHub/whispers-north/scenes/world/World_ForestRuins.tscn): escena de bosque y ruinas que reproduce la topología del mapa incrustado en `plandeescenasWOTN.docx` (`image1.png`): entrada inferior izquierda desde la cueva, camino inferior con claro sureste, ramal central norte con desvíos este y oeste, sector de ruinas noroeste, camino superior este, ruina grande noreste y explanada del jefe en el extremo superior derecho; 10 cámaras y zonas (`Camera1`..`Camera10`) y marcadores `Ref_*` para los encuentros y tesoros de las Fases 5 y 6.
- [tests/recorrido_fase1_test.gd](C:/Users/angel/Documents/GitHub/whispers-north/tests/recorrido_fase1_test.gd): suite automatizada de pruebas de la Fase 1.

#### Archivos modificados
- [scripts/core/game_state.gd](C:/Users/angel/Documents/GitHub/whispers-north/scripts/core/game_state.gd): añadidas constantes de escenas del recorrido (`ESCENA_CASA`, `ESCENA_VECINDAD`, `ESCENA_PUEBLO`, `ESCENA_CUEVA`, `ESCENA_BOSQUE`), identificadores estables de progresión (`PROGRESO_TUTORIAL_DIARIO`, `PROGRESO_CHARLA_PROGENITOR`, `RECOMPENSA_NPC_UTIL`, `ENCUENTRO_POT_VECINDAD`, `ENCUENTRO_TRIO_POTS_PUEBLO`, `COFRE_CUEVA_OCULTO`, `OBJETO_IMPORTANTE_RUINAS`, `JEFE_RUINAS_DERROTADO`, `DEMO_COMPLETADA`), API de progreso (`marcar_progreso`, `tiene_progreso`, `obtener_progreso`, `reclamar_unico`) y `nueva_partida()`.
- [scripts/ui/MainMenu.gd](C:/Users/angel/Documents/GitHub/whispers-north/scripts/ui/MainMenu.gd): al iniciar partida llama a `GameState.nueva_partida()` y carga `GameState.escena_nueva_partida`.
- [scripts/world/world_town.gd](C:/Users/angel/Documents/GitHub/whispers-north/scripts/world/world_town.gd): refactorizado para heredar de `res://scripts/world/zona_mundo.gd`, eliminando duplicación con las nuevas zonas.
- [scripts/world/world.gd](C:/Users/angel/Documents/GitHub/whispers-north/scripts/world/world.gd): registra `GameState.zona_actual` y verifica por nodo la existencia del marcador de entrada.
- [scripts/world/world_transition.gd](C:/Users/angel/Documents/GitHub/whispers-north/scripts/world/world_transition.gd): duplica defensivamente el `BoxShape3D` cuando no es `resource_local_to_scene` para evitar que varias transiciones en una misma escena alteren mutuamente su tamaño.
- [scripts/world/camera_switch_manager.gd](C:/Users/angel/Documents/GitHub/whispers-north/scripts/world/camera_switch_manager.gd): evita sobrescribir en diferido la cámara activada por una transición de entrada cuando el viewport ya tiene una `Camera3D` activa.
- [scenes/world/World.tscn](C:/Users/angel/Documents/GitHub/whispers-north/scenes/world/World.tscn): añadidos `Entrada_Casa` (`WorldTransition` frente a la puerta de la casa hacia `World_House.tscn`) y el marcador `Llegada_DesdeCasa`. Conserva exclusivamente su sistema `SwitchC_*` sin mezclar `CameraSwitch`.
- [scenes/world/World_Town.tscn](C:/Users/angel/Documents/GitHub/whispers-north/scenes/world/World_Town.tscn): añadidos en el extremo derecho `Camera12`, `Switch_11_12`, `Salida_Cueva` (`WorldTransition` hacia `World_Cave.tscn`), `Llegada_DesdeCueva` y geometría provisional `BocaCueva`; reubicado el trío de Pots unos metros al oeste (`X ≈ 34..35`) para despejar el punto de aparición desde la cueva.

### 2. Mapa de conexiones entre zonas

| Origen | Nodo `WorldTransition` | Destino | Marcador de llegada | Cámara activada |
| :--- | :--- | :--- | :--- | :--- |
| `World_House.tscn` (Cuarto) | `Puerta_Cuarto_Escalera` | `World_House.tscn` | `Llegada_Escalera` | `Camera2` |
| `World_House.tscn` (Planta baja) | `Escalera_Subir` | `World_House.tscn` | `Llegada_PuertaCuarto` | `Camera1` |
| `World_House.tscn` (Planta baja) | `Puerta_Salida_Vecindad` | `World.tscn` | `Llegada_DesdeCasa` | `Camera1` |
| `World.tscn` (Vecindad) | `Entrada_Casa` | `World_House.tscn` | `Llegada_DesdeVecindad` | `Camera2` |
| `World.tscn` (Vecindad) | `Marker_Exit_World` | `World_Town.tscn` | `Marker_Exit_World` | `Camera1` |
| `World_Town.tscn` (Pueblo, izq.) | `Marker_Exit_World` | `World.tscn` | `Marker_Exit_World` | `Camera6` |
| `World_Town.tscn` (Pueblo, der.) | `Salida_Cueva` | `World_Cave.tscn` | `Llegada_DesdePueblo` | `Camera1` |
| `World_Cave.tscn` (Oeste) | `Entrada_Pueblo` | `World_Town.tscn` | `Llegada_DesdeCueva` | `Camera12` |
| `World_Cave.tscn` (Este) | `Salida_Bosque` | `World_ForestRuins.tscn` | `Llegada_DesdeCueva` | `Camera1` |
| `World_ForestRuins.tscn` (Inf. izq.) | `Entrada_Cueva` | `World_Cave.tscn` | `Llegada_DesdeBosque` | `Camera4` |

### 3. Pruebas ejecutadas y resultados (Headless)
1. **Suite de recorrido y estado (`res://tests/recorrido_fase1_test.gd`):**
   - Comando: `godot --headless --path . --script res://tests/recorrido_fase1_test.gd`
   - Resultado: **136 PASS, 0 fallos**.
   - Cobertura comprobada:
     - `GameState.reclamar_unico()`, `marcar_progreso()`, `tiene_progreso()`, señal `progreso_cambiado` y reinicio completo con `nueva_partida()`.
     - Carga limpia de las 5 escenas, presencia de `PauseMenu`, `get_active_player()`, cámara inicial activa y ausencia total de mezcla entre `SwitchC_*` y `CameraSwitch`.
     - Recorrido completo de ida y vuelta por las 10 transiciones verificando posición segura sobre suelo tras simular física, cámara de destino activa, ausencia de solapamiento con triggers de retorno (sin bucles) y persistencia de HP, inventario, acompañante (`Rat`) y progreso.
2. **Suite de coordinación de encuentros (`res://tests/encuentros_test.gd`):**
   - Comando: `godot --headless --path . --script res://tests/encuentros_test.gd`
   - Resultado: **34 PASS, 0 fallos** (sin regresiones).

### 4. Pasos para probarlo manualmente en Godot (Validación visual pendiente)
> Las pruebas anteriores se ejecutaron en modo `--headless`; la comprobación visual en ventana queda pendiente de inspección manual en el editor:
1. Abrir el proyecto en Godot 4.7 y ejecutar `scenes/world/World_House.tscn` con `F6`:
   - Caminar hacia la puerta derecha del cuarto para bajar a la planta baja (`Camera2`), volver a subir por la escalera izquierda (`Camera1`) y salir por la puerta derecha hacia `World.tscn`.
2. En `World.tscn`, comprobar que al volver a acercarse al umbral de la casa (`Entrada_Casa`) se regresa a la planta baja de `World_House.tscn`, y que `Door` sigue pudiendo usarse si se interactúa con `[E]`.
3. Recorrer `World.tscn` → `World_Town.tscn` y caminar por la calle principal hacia el extremo derecho hasta cruzar `Salida_Cueva` (`Camera11` → `Camera12` → `World_Cave.tscn`).
4. Cruzar `World_Cave.tscn` hacia la derecha observando el cambio entre `Camera1`..`Camera4` hasta salir a `World_ForestRuins.tscn`.
5. En `World_ForestRuins.tscn`, recorrer los senderos (inferior, central, desvíos y extremo superior derecho) y luego regresar hasta la casa comprobando el menú de pausa (`Escape` / `P`).

### 5. Recursos provisionales y decisiones pendientes
- La geometría interior de `World_House.tscn`, la abertura `BocaCueva` en `World_Town.tscn`, el túnel de `World_Cave.tscn` y las masas de arboleda (`Masa_01`..`Masa_27`) de `World_ForestRuins.tscn` usan bloques `CSGBox3D` con materiales locales existentes.
- En la Fase 1 el cambio entre plantas de `World_House.tscn` reutiliza `WorldTransition` como conexión base; en la Fase 2 se reemplazará por la transición dedicada con sonido de pisadas y demora con blackout que pide el documento.

### 6. Próxima fase
- **Fase 2 — Casa (`World_House.tscn`):** mobiliario rústico moderno (cama, ropero, cajas de mudanza, espejo, mesa con diario), tutorial de movimiento e interacción dinámico según controles configurados (una sola vez por partida), transición entre plantas con sonido de pasos y delay con fade blackout, conversación con progenitor mediante `InteraccionDialogo` y activación de `World_House.tscn` como escena inicial de Nueva partida.


---

## Fase 2 — Casa (12 de noviembre de 2026)

### Resultado implementado

- `World_House.tscn`: cuarto con cama, almohada/manta, ropero, mesa y diario, cajas, espejo decorativo y alfombra; planta baja con aparador, cuadro, zona de comedor delimitada, cajas, peldaños y progenitor. Mobiliario editable como nodos CSG y materiales en el Inspector. Marcador junto a la cama desplazado fuera de la colisión del mueble.
- `scripts/world/casa.gd`: hereda de ZonaMundo. El diario explica movimiento, interacción y pausa con los eventos existentes del Input Map. La indicación cambia al recibir teclado o mando. La lectura completa reclama `tutorial.diario_casa`, desactiva el diario y oculta la ayuda; al volver a casa no se repite. La puerta del cuarto recuerda leerlo antes de permitir bajar.
- Progenitor Erland (nombre visible: Papá), con Sprite3D que referencia el recurso local `Erland (Padre)/16x16 Walk-Sheet.png`. Conversación mediante InteraccionDialogo; registra `dialogo.progenitor_casa` al finalizar y utiliza un saludo breve en visitas posteriores. No concede estadísticas ni recompensas.
- `scripts/world/transicion_casa.gd`: especialización de WorldTransition aplicada exclusivamente a los dos pasos entre plantas. Conserva nombres, destinos y marcadores de Fase 1; realiza fundido, tres pasos y demora negra de 0.75 s, mueve al jugador y cambia de cámara sin recargar la casa. Usa CoordinadorEncuentros; restaura controles y reserva al terminar o al eliminar el componente. El sonido es sustituible desde el Inspector.
- La salida y el regreso entre casa y vecindad siguen usando WorldTransition existente.
- `scripts/core/game_state.gd`: Nueva partida ahora carga ESCENA_CASA. Mantiene el reinicio de progresión de Fase 1.
- Los recursos rápidos privados de los diálogos de la casa liberan las referencias a sí mismos inyectadas por Dialogue Manager al completar la lectura. La última ejecución de Fase 2 cierra sin avisos de recursos retenidos; no se modificó el addon.

### Validación ejecutada

- Baseline de recorrido antes de editar: `recorrido_fase1_test.gd`, 0 fallos.
- `tests/casa_fase2_test.gd`: **23 comprobaciones, 0 fallos**, tanto en headless como en ejecución renderizada (la ejecución renderizada final terminó sin errores ni avisos de recursos retenidos).
- La prueba de casa abre diálogos reales y avanza su globo mediante InputEventAction; verifica bloqueo antes del diario, progreso al finalizar, conservación de la escena/jugador en escaleras, cámaras, retorno a casa, saludo posterior, cancelación durante fundido y reinicio. Comprueba textos de teclado/mando, pero no sustituye una prueba con mando físico.
- Regresión: `recorrido_fase1_test.gd`, 0 fallos; `encuentros_test.gd`, 0 fallos. La advertencia del diálogo sin recurso en encuentros_test es esperada por esa prueba.
- Inspección de capturas renderizadas de cuarto, planta baja y diálogo. Se amplió el encuadre de planta baja para incluir la puerta de salida. Esta inspección no constituye un recorrido manual exhaustivo ni una escucha del audio.
- La importación detectó UID duplicados en sprites existentes de Erland y del paquete de plantilla. No se cambiaron esos recursos ni sus identidades para resolverlos dentro de esta fase.

Comandos (sustituir `godot` por la ruta al ejecutable registrada en Fase 0):

```text
godot --headless --path . --script res://tests/casa_fase2_test.gd
godot --headless --path . --script res://tests/recorrido_fase1_test.gd
godot --headless --path . --script res://tests/encuentros_test.gd
godot --path . --rendering-method gl_compatibility --windowed --max-fps 60 --script res://tests/casa_fase2_test.gd
```

### Cómo probarlo manualmente

1. Iniciar Nueva partida desde el menú: se aparece junto a la cama. También puede ejecutarse World_House con F6.
2. Intentar bajar sin leer el diario: permanece en el cuarto y se muestra el recordatorio.
3. Acercarse al diario sobre la mesa, usar el control indicado y completar las cinco líneas. Comprobar teclado y mando físico.
4. Cruzar la puerta derecha del cuarto: fundido, pasos, demora negra y aparición frente a la escalera de planta baja.
5. Acercarse a Papá, completar la conversación y repetirla: debe usar el saludo breve.
6. Subir, bajar, salir por la puerta derecha y volver desde la vecindad: no deben repetirse el tutorial ni la charla introductoria.
7. Comprobar pausa, inventario, acompañante, audibilidad de los pasos y todas las colisiones de los muebles.
8. Volver al menú e iniciar Nueva partida: el diario y la charla inicial vuelven a estar disponibles.

### Recursos provisionales y límites

- Arte de mobiliario mediante geometría simple y materiales existentes; no se presenta como arte final.
- El padre usa el sprite local existente, de aspecto genérico; no se dibujó un personaje definitivo. El nombre oficial Finn quedó confirmado por el usuario el 17/11/2026 y aplicado en GameState.
- El espejo es decorativo: no simula reflejos ni abre estadísticas (el plan lo proponía como interacción opcional).
- Pasos sintetizados como tres golpes suaves de madera al no localizarse un recurso local específico; pendiente aprobación auditiva o sustitución por foley final en `sonido_pasos`.
- Diálogo del progenitor provisional y breve, sin añadir lore definitivo. Hablar con él es opcional; completar el diario sí es requisito para bajar por primera vez.
- Estado de progresión en memoria por partida; no se añadió guardado en disco.
- Queda pendiente el recorrido manual completo con teclado/mando físico y prueba auditiva. En ese cierre aún no se había iniciado el contenido de Fase 3; actualmente hay mejoras parciales de combate y presentación, sin completar la fase.

### Prueba de Jarrito en los mapas existentes (12 de noviembre de 2026)

Antes de Fase 3, se sustituyeron las cuatro instancias de Pot de World (una) y World_Town (tres) por Entities/Jarrito.tscn. Conservan posiciones y usan JarritoBattler con sus animaciones y embestida/esquive. Detección configurada a 4 m y abandono a 6 m para limitar la persecución durante las pruebas.

Los tres enemigos del pueblo son encuentros individuales: no se transfirió el sistema de grupo exclusivo de Pot. Los recursos antiguos siguen disponibles para pruebas y referencias; no se eliminaron. No se añadieron enemigos a cueva ni bosque ni se inició Fase 3.

Validación: cuatro instancias con JarritoBattler, combate habilitado y apoyo sobre suelo; recorrido_fase1_test y jarrito_combat_test con 0 fallos. Jarrito se verificó también con renderizado OpenGL, sin los errores de consulta de teclas físicas que el indicador actual emite en headless. La comprobación temporal de instancias emitió avisos de recursos retenidos al cerrar; no se presenta como cierre limpio.

Para probar: ejecutar World_Town.tscn con F6, avanzar hacia la derecha hasta los Jarritos próximos al camino de salida a la cueva y acercarse. Para probar solo la arena, ejecutar scenes/combat/tests/JarritoCombatTest.tscn con F6. Victoria desactiva nuevas detecciones de esa instancia hasta recargar el mapa, según el comportamiento actual de Jarrito.

### Persecución y puñetazo del jugador (12 de noviembre de 2026)

- Jarrito recupera los valores de persecución del antiguo Pot: velocidad 3.4, detección 9 m y abandono 18 m. World y World_Town tienen esos alcances. Se incorpora línea de vista configurable, regreso físico al punto de aparición al perder al jugador y reacquisición durante el regreso. Conserva las animaciones Alert/Walk/Encounter y la llama independiente. Se detiene durante diálogo, transición, protección o combate. Se preservan los valores de los estados anteriores; RETURN se añade al final.
- No se trasladan los eventos cómicos de explosión, empuje ni el combate grupal de Pot: este cambio recupera la persecución y el regreso solicitados. El movimiento utiliza colisiones y dirección directa, como el Pot anterior; no implementa navegación alrededor de laberintos.
- El recurso fuente se llama Punch_Down_Side en ambos archivos Attack.aseprite de la plantilla Eris Esra. Se expone como down_site_punch. Los nuevos SpriteFrames player_punch_16.tres y player_punch_32.tres referencian la segunda fila completa del PNG existente (6 cuadros de 24x24 y 7 de 32x32), con las duraciones originales 100/100/200/50/100/100 ms y un último cuadro de 100 ms adicional para 16x32. No se modifican ni generan imágenes.
- PlayerBattler ahora usa scripts/combat/player_battler.gd, subclase de Battler. Copia los frames del jugador, duplica el recurso y añade el ataque adecuado a su tamaño. Los SpriteFrames de exploración permanecen intactos. Los ataques consecutivos reinician desde el primer cuadro.
- Golpear inicia la secuencia completa y configura el impacto/QTE a 0.4 s, sin la deformación procedural de respaldo; espera la recuperación antes de volver a la base. Otros combatientes conservan el respaldo anterior. La acción especial también puede reproducir anim_ataque sin cambios en sus reglas.
- Arte provisional: el atlas de ataque disponible es el de la plantilla, sin la personalización visual de Finn. No existe un atlas de ataque propio en Finn (Prota); sustituir los recursos cuando se aporte.
- Validación: tests/persecucion_punch_test.gd con 0 fallos (obstáculo bloquea visión, persecución física a 8 m, pausa por diálogo, regreso, llama, variantes 16/32, recursos sin mutación, repetición de ataque, Golpear real, daño y retorno). Captura renderizada del golpe inspeccionada. encuentros_test.gd y recorrido_fase1_test.gd: 0 fallos. La prueba de integración sigue emitiendo avisos de recursos retenidos al cerrar, también observados antes de este cambio en la comprobación de Jarrito en mapas; no se declara cierre limpio.

Para probar: F6 en World_Town, aproximarse a un Jarrito y alejarse hasta que regrese. En combate elegir Golpear y pulsar interact cuando lo indique el QTE. Para ejecutar la nueva prueba sin las limitaciones headless del indicador: godot --path . --rendering-method gl_compatibility --windowed --max-fps 60 --script res://tests/persecucion_punch_test.gd.

### Correcciones de combate confirmadas (13 de noviembre de 2026)

Esta sección sustituye las decisiones provisionales anteriores sobre el ataque blanco, el tamaño variable del jugador y los encuentros individuales del trío.

- Ataque personalizado: se exportaron los cuadros 8–14 de Aseprite (índices 7–13) de assets/sprites/player/movimiento/16x32 Attack.aseprite, secuencia Punch_Down_Side, con autorización expresa del usuario. finn_punch.png y finn_punch.json contienen los siete cuadros coloreados; el archivo fuente permanece intacto. La animación de combate se llama punch_down_site y conserva las duraciones de origen.
- PlayerBattler usa siempre player_32.tscn como base, incluso cuando el personaje de exploración es de 16 píxeles. Duplica los SpriteFrames antes de añadir el ataque. player_punch_16.tres queda sin uso.
- Los tres Jarritos de World_Town comparten grupo_encuentro = trio_jarritos_pueblo: una reserva y una arena con tres enemigos. Los tres se ocultan al confirmar el encuentro, se restauran al huir o cancelar y quedan derrotados al ganar. El Jarrito de World mantiene su encuentro individual. Se conserva la IA de persecución, línea de vista y regreso.
- Cada Jarrito reproduce snd_mysterygo.wav al entrar en alerta, mediante audio 3D en el bus SFX a -6 dB. Se comprobó que la reproducción se inicia; queda pendiente valorar su volumen mediante escucha manual.
- Cámara de combate más baja y alejada: posición (0.56, 2.4, 8.4), inclinación -8 grados y giro -7 grados; FOV 44 y encuadre automático conservados. Captura del trío inspeccionada sin recortes.

Validación realizada antes de este cierre documental: grupo_jarrito_test.gd, persecucion_punch_test.gd, encuentros_test.gd y recorrido_fase1_test.gd terminaron con 0 fallos. La prueba del grupo verifica tres enemigos, sonido de detección, tamaño fijo, restauración tras huida/cancelación y victoria conjunta; inyecta los resultados de huida/victoria y no evalúa el balance de una partida manual. La prueba de ataque ejecuta Golpear y comprueba daño, repetición y retorno. Captura del impacto inspeccionada con el ataque coloreado. La advertencia de diálogo sin recurso en encuentros_test es esperada.

Para probar manualmente: ejecutar World_Town.tscn con F6, acercarse al trío, comprobar el aviso sonoro y la entrada de los tres en la arena. Elegir Golpear y comprobar el ataque coloreado. Huir y verificar que vuelven los tres al mundo. Pendientes: escucha manual y valoración del encuadre y balance jugando.

Ajuste posterior de cámara (13 de noviembre de 2026): a petición del usuario, se eleva la cámara de combate de 2.4 a 2.8 y se cambia la inclinación de -8 a -11 grados. Se mantienen distancia Z 8.4, giro -7 grados y FOV 44. Pendiente valoración visual del usuario.

Referencia visual de combate (13 de noviembre de 2026): cámara elevada a (0, 7.6, 12), mirando 30 grados hacia abajo, sin giro lateral y FOV 44. Formación de ambos bandos en profundidad: hasta tres filas separadas 2.8 unidades, alternando 1.5 unidades laterales; grupos mayores abren columnas adicionales. El encuadre automático aleja la cámara sin comprimir las posiciones. Captura renderizada del trío inspeccionada, con los tres enemigos separados y visibles. Sustituye los ajustes anteriores de cámara.

Contacto de inicio de combate: el sensor del Jarrito usa el tamaño del cuerpo (radio 0.65, altura 1.0) con tolerancia de 0.02 para el margen físico, en vez del antiguo radio de proximidad 1.25. Al tocar al jugador reserva el encuentro sin esperar Alert/Encounter. Se mantienen detección, persecución, protección tras huida y encuentro grupal. grupo_jarrito_test verifica que la cercanía no inicia combate y que el contacto inicia dentro de cuatro cuadros físicos: 0 fallos.

### Integración visual de assets nórdicos
Se integraron los paquetes de objetos, materiales, props y UI en escenas jugables. Detalle de reemplazos y faltantes en ASSETS_INTEGRACION.md. Los iconos de inventario ya tienen arte; equipamiento/economía, atlas de casas/caminos y arte final de escenarios siguen pendientes. Esta integración no marca como completadas las Fases 3–7.


## Integración de assets y correcciones visuales — 14 de noviembre de 2026

- Integradas seis maderas, ocho superficies complementarias y cuatro efectos de impacto/pasos/agua/recogida. Asignaciones y pendientes concretos en ASSETS_INTEGRACION.md.
- Opciones con fuente legible, panel adaptable y fondo que cubre ventanas altas. Pausa/inventario/estadísticas con más espacio interior y contenido dentro del marco.
- Casa: materiales e iluminación coherentes en ambos pisos. Árboles/arbustos apoyados visualmente en suelo, billboard vertical y arbustos desplazados al borde del camino.
- Protección del encuadre en cinco zonas y atenuación de vegetación delante del protagonista. Se conserva el sistema de switches y se excluye la cámara de combate. Se verificaron muestras de encuadre; queda revisión manual exhaustiva de oclusiones por edificios.
- Validación: assets_nordic_test, presentation_test, recorrido_fase1_test, casa_fase2_test (23), inventario_fase25_test (20), grupo_jarrito_test y encuentros_test: cero fallos funcionales. Capturas revisadas de casa, opciones, pausa/inventario y World; pruebas visuales en formato ancho y 900 × 700.
- Aviso adicional: inventario_fase25_test termina con referencias de audio snd_item.wav pendientes de liberar (AudioStreamWAV/Playback); no falla ninguna comprobación, pero el cierre del audio de la prueba requiere seguimiento.
- Pendientes visuales adicionales: repetición del fondo de montaña, bordes verdes del tileset de caminos, árboles frondosos anteriores y malla de chorro de fuente. No se considera terminada la arquitectura de bosque/ruinas ni se avanza a una fase narrativa nueva.


## Auditoría de assets y panorama — 16 de noviembre de 2026

Revisados los 47 PNG de ocho paquetes. El pendiente nuevo era snowy_mountain_panorama: integrado en World, World_Town y CombatArena, con escala corregida, capas exteriores redundantes ocultas y cielo de soporte en combate. Capturas inspeccionadas y grupo_jarrito_test con cero fallos. ASSETS_INTEGRACION.md actualizado con los pendientes de creación/adaptación y la distinción entre iconos registrados y sistemas de gameplay aún pendientes.

## Sugerencias implementadas

- Bosque distante en World y World_Town reutilizando nordic_pine, fuera del perímetro jugable y sin colisión. Variación determinista de alturas/posiciones y color frío para cubrir el horizonte.
- Etiquetas según el nombre del mando conectado y último dispositivo usado: Xbox, PlayStation y Nintendo. Botones y gatillos en tutorial, pausa y remapeo; un dispositivo no reconocido usa nomenclatura Xbox. Validación de mapeo automatizada; falta prueba física de cada familia, especialmente mandos traducidos por Steam Input.
- Túnel: cuatro faroles, cuatro cajas y cuatro rocas junto a la pared posterior. Relleno cálido localizado; corredor central comprobado libre de colisión.
- Dormitorio: lámpara elevada y relleno suave para iluminar el centro sin aumentar la luz ambiente global.
- Validación: presentation_test.gd sin fallos (20 puntos de encuadre en cinco zonas); suggestions_test.gd sin fallos (familias de mando, decoración y paso central). Capturas de bosque, casa y túnel revisadas en Godot Compatibility.
- Siguen pendientes de pulido: sombras de contacto de decoraciones, mobiliario definitivo y recorrido manual exhaustivo con mando físico en varios formatos de pantalla. No se añadieron enemigos al túnel ni se modificó su progresión.

## Bosque de fondo denso e irregular

Sustituida la cuadrícula de pinos del fondo de World y World_Town por distribución continua determinista con separación mínima entre troncos, mezcla de pinos y árboles de copa verde/nevada, variación de altura, anchura, orientación horizontal y tono. Se añaden grupos de arbustos, hierba, rocas musgosas y nieve como sotobosque. La franja queda entre 9 y 32 unidades fuera de los suelos jugables; no incluye colisiones ni ocupa accesos. Límite de 650 árboles por zona, con decoración agrupada adicional, reutilizando texturas existentes. Las escenas se renderizaron en Godot Compatibility sin errores y se revisaron capturas de casa y pueblo. No se ha realizado un benchmark en hardware de gama baja.

## Integración del paquete decorativo

Los ocho assets de nordic_decor_v1 están integrados mediante prefabs editables en scenes/world/Entities/NordicDecor. Recorte AtlasTexture con umbral alfa 128 para ignorar residuos casi transparentes, escala por altura visible y apoyo al suelo; originales PNG conservados.

- Casa: dos estanterías y un leñero.
- Pueblo: dos bancos y cuatro jardineras cerca de la plaza y fachadas.
- Arena: dos columnas, dos braseros con luz cálida y ocho elementos de borde reutilizados (rocas, hierba, arbustos y nieve). Centro reservado a combatientes.
- Cueva: ocho grupos de estalagmitas, ocho de hongos y cuatro leñeros junto a las paredes, además de los faroles/cajas/rocas existentes. Tonos fríos adaptados a la cueva.
- Decoración sin interacciones ni nuevas colisiones; los hongos no son recogibles y la llama dibujada del brasero sigue estática. No se modificó la dificultad ni el botín.
- Validación: grupo_jarrito_test.gd sin fallos; suggestions_test.gd sin fallos y corredor central libre en cuatro tramos. Capturas revisadas de arena, cueva, casa y plaza.

## Ajuste de escala e iluminación de NordicDecor — 16/11/2026

- Los ocho prefabs usan `shaded = true`: reciben iluminación ambiental, luces locales y sombras del escenario en lugar de mantener brillo constante. Se mantienen sin proyectar sombras planas de billboard.
- Alturas base antes de la escala de cada instancia: estantería 1.85, leñero 0.50, banco 0.90, jardinera 0.65, columna 2.10, brasero 1.20, estalagmitas 1.65 y hongos 0.34 unidades.
- Recalculado pixel_size desde el recorte visible y apoyo a -0.015 del suelo. Matices moderados de madera, vegetación y piedra; retirada la corrección azul oscura artificial de cueva para usar luz real.
- Luz del brasero reubicada a la altura de la llama, con alcance 3.2 acorde al nuevo tamaño.
- Validación visual: capturas de casa, planta baja, plaza, arena y cueva. grupo_jarrito_test y suggestions_test: cero fallos. lighting_preview y decoration_preview finalizaron sin errores.
- Limitación: los assets siguen siendo sprites con perspectiva dibujada; la iluminación real mejora su integración pero no sustituye el volumen de un modelo 3D.

## Correcciones tras revisión de capturas — 16/11/2026

- Aumentadas las alturas base de estanterías (2.65), leñeros (1.05), bancos (1.65) y jardineras (1.20). Sustituyen los tamaños anteriores del ajuste de NordicDecor.
- Finn usa el 70% de escala visual solo en World_House, conservando apoyo de pies, cápsula y lógica de interacción. Combate y exteriores conservan su tamaño.
- En cueva el sprite recibe iluminación real y un relleno frío limitado a su capa visual para que no brille a intensidad completa ni quede negro; no ilumina el entorno.
- Cambios de cámara cercanos interpolados en 0.45 segundos. Teletransportes lejanos conservan su fundido. Mientras se mantiene una misma dirección de entrada, el movimiento conserva el rumbo del mundo al cruzar cámaras; al soltar o cambiar de dirección se toma la cámara nueva.
- Arena: montañas alejadas a Z=-22, vegetación intermedia con alturas y posiciones variadas, suelo con borde posterior oculto por vegetación y cielo ampliado. Luz solar orientada hacia el suelo, sombras habilitadas y sombras suaves de contacto bajo decoraciones.
- Validación: camera_comfort_test (4 comprobaciones), casa_fase2_test (23), suggestions_test y grupo_jarrito_test sin fallos. Capturas finales revisadas de casa, plaza, cueva y arena. La comodidad de cámaras durante recorridos largos queda sujeta a prueba manual del jugador; no se cambió el mapa de controles.

## Bosque de arena, sombras y cámaras fijas — 16/11/2026

- La arena reutiliza las tres especies del bosque del pueblo (pino, árbol nevado y verde): hasta 135 árboles con separación mínima, posiciones continuas, alturas 2.8–5.0 y varias profundidades. Montañas reducidas y alejadas a Z=-32; terreno extendido bajo el bosque. Captura de combate revisada y grupo_jarrito_test sin fallos.
- Árboles y decoración del mundo proyectan sombras con recorte alfa y doble cara, incluido el bosque distante y NordicDecor. Los prefabs con atlas conservan su apoyo original al suelo. decoration_preview finaliza sin errores.
- Eliminados por completo el giro automático look_at y la interpolación de transformaciones en world_presentation. Solo cambia la cámara activa cuando existe un encuadre fijo válido, con margen y espera de 0.65 para evitar oscilaciones. Se conserva el rumbo del movimiento mientras se mantiene la entrada.
- Tres cámaras fijas adicionales en el pueblo cubren la plaza sur, plaza este y calle central (Camera13–15). Validado el encuadre completo en siete puntos y que las 15 cámaras mantengan su transformación; fixed_cameras_test sin fallos. camera_comfort_test actualizado al contrato de cámaras fijas, sin fallos.
- Muebles cercanos a la fuente desplazados al exterior: centros a más de 6.5 unidades de ella. Añadidos tres bancos y cinco jardineras; total del paquete en el pueblo: cinco bancos y nueve jardineras. Captura revisada sin intersecciones con la fuente.
- Esta revisión sustituye la interpolación de cámaras descrita en el registro anterior. No se ha medido el coste de sombras adicionales en hardware de gama baja.


## Nombre oficial del protagonista — 17/11/2026

Finn es el nombre oficial confirmado. Actualizados GameState, menú de pausa, nombre base de combate, resolución del retrato de diálogo, reconocimiento por nombre del jugador, comentarios, mensajes de pruebas y documentación. El plan DOCX no contenía menciones del nombre anterior.


## Escala de Finn frente a aldeanos — 17/11/2026

Reducida la escala visual de exploración al 75% (32 px × 0.08 × 0.75 = 1.92 unidades), comparable a los aldeanos de 1.85–2.05. Compensada la posición vertical para conservar los pies. La casa mantiene el 70% ya aplicado; la arena usa su combatiente independiente. Sin cambios en movimiento ni colisiones de interacción.

## Márgenes de combate, diálogo nórdico y cruces — 17/11/2026

- HUD de combate: márgenes laterales 38 y verticales 28, panel mínimo 236×128 y nombres con ajuste de línea. Vida y texto permanecen dentro de la zona libre del marco tallado.
- Diálogo: reutiliza button_normal del paquete nordic_carved_v1, texto marfil, opciones verde oscuro y bordes oliva/dorados. Mayor espacio interior y altura; captura de revisión en tests/ui_dialogue_preview.gd.
- Caminos: sustituidos 24 tiles cóncavos que introducían huecos de pasto y diferencias de tono dentro de cruces conectados. Conservadas las 1218 celdas y las dimensiones de las cinco escenas; herramientas de migración actualizadas para no reintroducirlos. Los bordes exteriores conservan su atlas; el grano de los originales todavía presenta variación entre tiles.
- Verificación: capturas del HUD con tres Jarritos, diálogo y cruce central del pueblo revisadas. grupo_jarrito_test sin fallos; casa_fase2_test 23 pruebas, 0 fallos.

## Opciones centradas y árboles de arena — 17/11/2026
- CheckPantalla y OpcionesResolucion centrados tanto en escena como en creación dinámica para evitar invadir los adornos laterales.
- Árboles de combate: AtlasTexture recortado a píxeles con alfa >= 0.5, descompresión previa de imágenes importadas, base calculada sobre ese recorte y raíces hundidas 0.12 unidades. Se mantiene distribución, iluminación y sombras.
- Capturas de opciones a 900×700 y combate revisadas; botón dentro del panel y grupo_jarrito_test sin fallos.
