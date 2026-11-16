# Integración de assets nórdicos — estado al 16 de noviembre de 2026

Estado general por fases: [AVANCE_DEMO.md](AVANCE_DEMO.md). Esta revisión documental no vuelve a ejecutar pruebas ni cambia assets.

## Modelos originales de casas — 16 de noviembre de 2026

- Paquete `assets/models/nordic_houses/`: CasaRoja, CasaEntramado y CasaPorche, cada una en `.tscn` editable y `.glb` exportado. Geometría original con texturas ya existentes; no añade nuevas texturas PNG al catálogo. `preview.png` es una captura de revisión, no un asset de superficie.
- Fachadas roja, yeso con entramado y madera oscura con porche; tejados a dos aguas, ventanas en cuatro lados, puertas, chimeneas, zócalos y molduras. Fuente reproducible: `tools/build_nordic_houses.py`.
- Escenas `.tscn` con colisión de volumen principal y marcador Entrance. Frente +Z, origen al suelo, escala 1. Puertas visuales, sin interiores ni transiciones. Aleros y porche no amplían la caja de colisión.
- Validación: instanciación de las tres escenas, comprobación de colisión/marcador, exportación GLB y captura conjunta inspeccionada en Godot 4.7.2. Abrir `assets/models/nordic_houses/Preview.tscn` para revisar.
- **Pendiente de integrar en World_Town**: sustituir las casas placeholder con ajuste explícito de escala/orientación, apoyo y recorridos. El pueblo conserva sus casas anteriores; los nuevos modelos no se han probado dentro del mapa.

## Catálogo de assets generados

Actualizado el 16 de noviembre de 2026 mediante revisión de archivos y referencias de escenas, scripts y recursos. Hay **49 PNG originales en nueve paquetes** (sin contar capturas de revisión). «Generado» significa que el archivo está disponible; «integrado» significa que existe una referencia en el juego. La creación de un material o una escena reutilizable no implica que se haya colocado en un mapa.

Las rutas de esta tabla son relativas a `res://`. Los README de cada paquete conservan sus prompts de `image_gen`, instrucciones y limitaciones de generación; este documento registra el estado de integración posterior.

| Paquete | Ruta | PNG | Contenido y estado |
| --- | --- | ---: | --- |
| Superficies base | `assets/sprites/environment/materials/nordic_v1/` | 6 | `wood_wall`, `red_roof`, `cold_grass`, `dirt_path`, `combat_ground`, `village_stone`. Integrados en superficies compatibles; detalles abajo. |
| Vegetación y obstáculos | `assets/sprites/environment/nordic_props_v1/` | 6 | `nordic_pine`, `grass_tuft`, `mossy_rock`, `snow_bank`, `wildflowers`, `dense_bush`. Incluyen escenas en `scenes/world/Entities/NordicProps/`; integración inicial y restricciones descritas abajo. |
| Interfaz Nordic Carved | `assets/sprites/ui/nordic_carved_v1/` | 5 | `button_normal`, `button_hover`, `button_pressed`, `menu_panel`, `inventory_slot`. Temas de menú/gameplay integrados. Foco y deshabilitado son estilos, no PNG adicionales. |
| Objetos | `assets/sprites/items/nordic_v1/` | 11 | Cofre `chest_closed`/`chest_open`; comida `rye_bread`, `nordic_cheese`, `wild_berries`; armas `short_sword`, `wood_axe`; drops `ceramic_shard`, `forest_crystal`; dinero `coin_pile`; llave `old_wood_key`. Nueve iconos de inventario y dos estados de cofre integrados. |
| Maderas por superficie | `assets/sprites/environment/materials/nordic_wood_v1/` | 6 | Seis PNG y seis materiales `.tres` disponibles. Integradas en casa, fachada, vigas, pasarela y ruinas; ver asignaciones abajo. |
| Superficies complementarias y agua | `assets/sprites/environment/materials/nordic_surfaces_v2/` | 8 | `cave_rock`, `fractured_rock`, `ruin_masonry`, `cream_plaster`, `packed_snow`, `frozen_ice`, `nordic_water`, `woven_wool`. Integradas en cueva, rocas, ruinas, casa, detalles de nieve/hielo y piscina de fuente. |
| Efectos visuales pequeños | `assets/sprites/vfx/nordic_v1/` | 4 | `hit_spark`, `step_dust`, `water_splash`, `pickup_glint`. PNG con alfa, animados mediante Tween y conectados a daño, pasos, agua y recogidas. |
| Fondo de montañas | `assets/sprites/environment/backgrounds/nordic_v1/` | 1 | `snowy_mountain_panorama.png`: panorama nevado con cielo transparente. Integrado en World, World_Town y CombatArena con escala normalizada y revisión visual. |

## Fondo de montañas integrado — 16 de noviembre de 2026

- `snowy_mountain_panorama.png` (1774 × 887, RGBA) sustituye la textura antigua en World, World_Town y CombatArena.
- Pixel size normalizado por 510/1774 para conservar anchura del recurso anterior. En exteriores se ocultan las copias superpuestas y la fila vertical duplicada; se conservan cuerpos y límites físicos existentes.
- Combate: cielo opaco detrás de la transparencia del panorama y ampliación moderada del fondo al encuadrar grupos. No se modifica la formación ni la cámara del combate.
- Validación: importación y capturas de vecindad, pueblo y combate de tres jarritos. `grupo_jarrito_test.gd`: 0 fallos. Las capturas comprueban estos encuadres; no constituyen una validación de todos los ángulos posibles ni de repetición seamless.
- Auditoría de los ocho paquetes: 47 PNG con referencia en escenas, scripts, materiales, temas o recursos. La auditoría incluye dependencias en `assets/` y excluye tests y la escena de preview del tema. Registrar iconos en ItemDatabase no equivale a distribuir todos los objetos como botín ni implementar equipamiento/economía.

## Asignaciones completadas — 14 de noviembre de 2026

| Paquete | Uso efectivo |
| --- | --- |
| Maderas | `light_pine_planks`: ambos pisos de la casa; `birch_furniture`: muebles, puertas y escalera con tintes coherentes; `dark_oak_panels`: vigas exteriores; `red_painted_siding`: fachada de la casa de World; `weathered_boardwalk`: tablones de la cueva; `mossy_old_timber`: vigas caídas de las ruinas. |
| Superficies | `cave_rock`: paredes/techo de cueva; `fractured_rock`: reborde de cueva y rocas de pueblo/bosque; `ruin_masonry`: seis conjuntos decorativos de pilares del bosque; `cream_plaster`: paredes de la casa; `woven_wool`: manta y alfombra; `packed_snow`/`frozen_ice`: detalles de entrada y charco en cueva; `nordic_water`: material de piscina de la fuente. |
| VFX | `scripts/vfx/nordic_vfx.gd`: impacto al recibir daño efectivo en Battler; polvo por desplazamiento real sobre suelo del jugador; destello tras recoger una cantidad aceptada; salpicadura periódica con la fuente animada. Escala y fundido, con liberación automática en 0.18–0.38 s. |

Los materiales usan filtro Nearest y escalas adaptadas. Las superficies nuevas no añaden mecánicas de hielo/agua. Los detalles de ruinas y cueva son decoración sin colisión y no completan sus fases de diseño. La fuente conserva la malla y el atlas anterior de su chorro; solo la piscina cambia de textura.

## Correcciones de presentación — 14 de noviembre de 2026

- Opciones: fuente legible, fondo oscuro uniforme, controles dentro del panel, centrado y adaptación al tamaño de ventana. Fondo del menú ampliado para cubrir formatos altos sin franja gris.
- Pausa: panel lógico de 960 × 600 adaptable, margen interior adicional, estadísticas de menor tamaño, perfil más compacto y relleno en paneles interiores.
- Casa: pino de piso menos amarillo, muebles de abedul más cálidos, puertas y escaleras de la misma familia e iluminación más neutra en ambos pisos.
- `world_presentation.gd`: apoyo visual de árboles, pinos, arbustos y decoraciones sobre el suelo mediante raycast y límite alfa de textura; orientación vertical del billboard. Conserva las colisiones y marcadores originales.
- Arbustos de World retirados del centro del camino hacia su borde; se conservan referencias y teletransporte.
- Encuadre: zona segura central con corrección de cámara al salir el jugador de ella. Aplicado a las cinco zonas, incluidas cámaras bajo `Cameras`; no modifica cámaras de combate. Mantiene altura de cámara y usa inclinación de 30° al corregir. Atenúa la vegetación que se interpone delante del protagonista.

## Integrado

- Materiales cold_grass, dirt_path, wood_wall y red_roof en las superficies compatibles de World, World_Town, World_House y World_ForestRuins. World_Cave también referencia dirt_path para el suelo. CombatArena usa combat_ground. Las cinco plataformas de ruinas del bosque usan village_stone. Se mantienen los tamaños y colisiones originales.
- Iconos nuevos de queso, fragmento de cerámica y llave en sus recursos existentes.
- Seis recursos nuevos registrados en ItemDatabase: pan_centeno (6 HP), bayas_bosque (3 HP), espada_corta, hacha_lenador, cristal_bosque y monedas_laton. Los valores de curación son provisionales. No se añaden al inventario inicial ni a los drops automáticamente; se pueden asignar desde el Inspector a cofres y recogibles. Espada, hacha y monedas son objetos de inventario, no sistemas de equipamiento o economía.
- Cofre abierto/cerrado sustituido en Chest.tscn y retrato del cofre. Se conserva su lógica y se ajusta tamaño/apoyo a los PNG nuevos.
- Bush.tscn usa dense_bush conservando el teletransporte. Tree_Pine usa nordic_pine conservando nodos y colisiones; sus dos variantes visuales usan por ahora el mismo pino sin nieve.
- Pasto, flores, roca y nieve colocados como decoración inicial junto a caminos del bosque. Sus obstáculos se desactivan en esas instancias para mantener el recorrido actual. Esto no completa el diseño de bosque/ruinas de Fase 5.
- Menú principal, pausa/inventario y paneles de combate usan Nordic Carved. Casillas cuadradas usan inventory_slot. En gameplay se conserva una fuente legible mediante nordic_gameplay_theme.tres; el menú principal mantiene BridgeParapet.
- Los recogibles ajustan pixel_size al tamaño del PNG para no aparecer gigantes. Se preservan los archivos antiguos por si otras escenas o herramientas los necesitan.

## Todavía faltan assets o adaptación

| Elemento | Pendiente concreto |
| --- | --- |
| Casas del pueblo | Tres modelos originales disponibles en nordic_houses (roja, entramado y porche), con materiales por pieza. Falta sustituir las instancias del pueblo y ajustar escalas, orientación, terreno y recorridos. Las casas de prueba todavía conservan sus atlas; los modelos nuevos no necesitan esos atlas. |
| Caminos de vecindad y pueblo | nordic_path_v1 disponible: centro, bordes y esquinas con exterior transparente. Falta migrar/repintar caminos, revisar curvas y escala. No es reemplazo directo del atlas anterior; autotiling y nieve acumulada siguen pendientes. |
| Vegetación | Árbol frondoso original y variantes nevadas de árbol y pino. Árboles frondosos anteriores siguen en uso; el pino nuevo no incluye versión nevada. |
| Casa | Arte definitivo de cama, ropero, mesa, sillas, diario, espejo, cajas y alfombras. Maderas, cream_plaster y woven_wool ya asignadas; no sustituyen muebles ni alfombras completas. |
| Cueva y relieve | cave_rock y fractured_rock ya cubren los mapas de color de roca y grietas. Materiales aplicados; faltan entrada/relieve definitivos y revisión de UV en esas futuras mallas; mossy_rock sigue siendo un sprite decorativo. |
| Ruinas | Columnas, arcos, muros rotos y piezas arquitectónicas. village_stone y ruin_masonry integrados en plataformas/pilares de prueba; falta arquitectura definitiva. |
| Agua y terreno invernal | Agua, nieve y hielo ya tienen texturas base. Colocados detalles de cueva y agua de piscina; faltan orillas/transiciones definitivas y comportamiento del terreno. |
| Efectos visuales | Cuatro efectos conectados con animación por escala/fundido. Faltan spritesheets si se requieren animaciones dibujadas cuadro a cuadro. |
| Fondo de combate y paisaje | Panorama integrado en vecindad, pueblo y combate. Faltan variantes específicas por bioma si se desean fondos diferentes para cueva, bosque o jefe. |
| Personajes | Retratos definitivos del protagonista/NPC y arte pendiente de personajes de prueba. |
| Jefe/final | Sprite y animaciones del jefe, objeto narrativo definitivo y presentación del final. La espada nueva no se ha asignado por inferencia al objeto del desenlace. |
| Interfaz complementaria | Iconos de estados/acciones, barras y selector propios; panel de controles y diálogo todavía conservan estilos anteriores. |

## Comprobación

- Catálogo: 49 PNG en nueve paquetes; los dos atlas del camino siguen pendientes de integración; las seis maderas, ocho superficies complementarias y cuatro VFX tienen usos conectados en el proyecto. El panorama nuevo está integrado y revisado como se detalla arriba. Las pruebas siguientes conservan su historial previo.
- `assets_nordic_test.gd`: carga/render de escenas y recursos, 0 fallos; inspeccionada la casa con la nueva paleta.
- `presentation_test.gd`: opciones dentro del panel, estadísticas dentro del marco, vegetación registrada para apoyo, veinte muestras de encuadre en cinco zonas y vida útil de cuatro VFX, 0 fallos. Capturas revisadas de opciones, pausa y World en formato ancho y ventana 900 × 700. Son muestras automatizadas, no una revisión manual de cada punto del mapa ni garantía contra toda oclusión por edificios.
- Regresiones ejecutadas: recorrido_fase1, casa_fase2, inventario_fase25, grupo_jarrito y encuentros; consultar el registro de avance para resultados finales.
- Pendientes visuales observados: atlas de caminos aún con bordes verdes, árboles frondosos antiguos y malla de chorro de fuente con forma de cúpula. Se conservan hasta contar con sustitutos adecuados; no confundirlos con texturas nuevas sin integrar.
- El bosque conserva geometría de prototipo. La importación mantiene avisos previos de UID duplicado de Erland/plantilla.

## Mantenimiento al generar nuevos assets

Al añadir un paquete o variante, actualizar este documento con nombre, ruta, cantidad, uso previsto y estado de integración. Registrar por separado generación, asignación a recursos/escenas y validación visual o pruebas efectivamente realizadas. Añadir los pendientes concretos y revisar el total del catálogo. No dar por resuelto un pendiente de modelado, UV, animación o gameplay solo porque exista un PNG relacionado.

## Decoración exterior — 16 de noviembre de 2026

- World (zona exterior de la casa): 28 instancias de flores silvestres, hierbas y piedras musgosas, agrupadas junto a la fachada y los bordes del sendero.
- World_Town: 42 instancias distribuidas por la plaza de la fuente, los jardines de las fachadas y las zonas verdes hacia la cueva.
- Instancias editables bajo DecoracionEntorno en cada escena; reutilizan NordicProps. Las piedras de estos grupos tienen collision_layer y collision_mask a cero. No se modifican sus prefabs ni las colisiones de piedras existentes en otras zonas.
- Altura visual adaptada al suelo por WorldPresentation y tamaños variados moderadamente. Entradas, caminos y encuentro de los tres jarritos conservados.
- Verificación: ambas escenas cargadas y capturadas en Godot sin errores. Inspección visual de decoración junto a casa y plaza. Script de revisión: tests/decoration_preview.gd.

## Iluminación — 16 de noviembre de 2026

- Casa: cinco faroles de pared visibles (dos en cuarto, tres en planta baja), con luz cálida localizada y sombras de muebles. Prefab editable FarolInterior.tscn, sin colisión. Relleno general reducido y ambiente neutro/frío para conservar lectura sin teñir toda la habitación de amarillo.
- World, World_Town y World_ForestRuins: sol compartiendo orientación (-48°, 32°), energía 0.55 y tono ligeramente cálido; ambiente frío 0.32 para iluminar sombras. Opacidad de sombra 0.72 y reflejo especular moderado. No se modifica la iluminación de cueva ni de combate.
- Validación visual en Godot Compatibility: cuarto, planta baja y los tres exteriores cargados/capturados sin errores con tests/lighting_preview.gd. Intensidad y altura de faroles ajustadas tras revisar la primera captura para reducir zonas sobreexpuestas y mantener las luminarias visibles.

## Tileset de camino — 16 de noviembre de 2026

- Paquete: `assets/sprites/environment/tilesets/nordic_path_v1/`. Dos atlas PNG RGBA, `nordic_path_tileset.tres` y `PathSample.tscn`. Arte generado con image_gen; prompts y coordenadas en README.
- 13 tiles: centro, cuatro bordes, cuatro esquinas exteriores y cuatro interiores. Exterior transparente para superponer sobre pasto/nieve. No incluye acumulación de nieve ni terrain/autotiling.
- Originales 1254 × 1254, importados por Godot a 96 × 96 con process/size_limit=96 en los .png.import. Celdas de 32 × 32; conservar estos ajustes. Fuente 0: nueve celdas. Fuente 1: cuatro esquinas.
- Verificación Godot 4.7.2: resolución importada y conteo correctos, escena de muestra guardada y render rectangular inspeccionado. Falta revisar todas las combinaciones de curvas en el mapa; la continuidad del grano no es matemáticamente garantizada.
- Disponible para pintura manual y PathPatch. No se reemplazó paths_tile_set ni se cambiaron recorridos. Migrar coordenadas y revisar escala antes de aplicarlo.
- preview.png es una captura de revisión, excluida del conteo de assets originales.
