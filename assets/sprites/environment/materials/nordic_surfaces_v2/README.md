# Superficies complementarias v2

8 texturas generadas con image_gen integrada para Whispers of the North:

| Archivo | Uso |
|---|---|
| cave_rock.png | Paredes y techo de cueva |
| fractured_rock.png | Roca agrietada para acantilados y entradas |
| ruin_masonry.png | Muros, columnas y arcos de mampostería |
| cream_plaster.png | Yeso de interiores y fachadas |
| packed_snow.png | Suelo de nieve |
| frozen_ice.png | Hielo de estanques |
| nordic_water.png | Superficie de agua tranquila |
| woven_wool.png | Tela para alfombras y mantas |

## Uso y límites

Cada PNG tiene un StandardMaterial3D .tres con Nearest y repetición activada. Asignar a una superficie con UV adecuados y ajustar UV1 Scale. Son mapas de color: no incluyen normal/ORM ni crean relieve o geometría. Se solicitó continuidad de bordes, pero hay que verificar el mosaico y escala visual en el mapa final.

El agua es una textura estática opaca: no incluye shader de oleaje, transparencia, refracción, orillas ni colisión. El hielo tampoco añade deslizamiento. woven_wool es un patrón de tejido, no una alfombra con bordes o flecos. Estas texturas no reemplazan atlas UV de casas, tilesets de transición ni modelos arquitectónicos.

Paquete disponible sin asignar a los mapas actuales. Revisión visual de originales y verificación de PNG; no prueba visual dentro del motor.

## Prompts exactos

Herramienta: image_gen integrada, transparent_background=false.

Use case: stylized-concept. One production seamless repeating albedo game surface for Whispers of the North, cozy mysterious Nordic village 2.5D pixel-art RPG. Square, opaque full-bleed material texture. Flat orthographic view, no perspective, no scene, no horizon, no objects, no borders, no lettering. Crisp coarse pixel clusters, low-resolution pixel-art look, restrained palette, no photo texture or fine noise, no blur. Uniform subdued lighting without cast shadows, no ambient vignette, no focal point, evenly distributed detail. Opposite edges should connect naturally on both axes. Muted slate blue-gray, sage, walnut, warm ivory, dusty terracotta family as appropriate. Quiet readable shapes so game characters remain legible.

### cave_rock

Subject: Dark rough cave rock for walls and ceiling. Large irregular slate-gray and cool charcoal stone planes, subdued shallow cracks and a few stepped lighter edges. Solid continuous rock, no masonry joints, no moss, no stalactites, no holes.

### fractured_rock

Subject: Weathered rock with several connected medium-scale branching fractures for cliffs and cave entrances. Muted gray taupe and desaturated blue-gray, dark thin stepped fissures, broad quiet stone faces, no abyss or transparent holes.

### ruin_masonry

Subject: Ancient Nordic ruin masonry, staggered rows of irregular rectangular slate blocks, cool gray-blue with sparse sage moss within narrow joints and occasional chipped corners. Flat continuous wall material, no arch, no column, no runes.

### cream_plaster

Subject: Warm ivory lime plaster for domestic house walls. Very subtle warm gray and cream pixel-cluster wear, a few tiny chips exposing ochre undercoat, extremely quiet low contrast. No boards, no bricks, no cracks, no wallpaper design.

### packed_snow

Subject: Continuous packed snow ground, ivory-white with very pale blue and lavender sparse soft stepped pixel patches suggesting shallow snow depressions. Very low contrast, no footprints, no rocks, no plants, no snowflakes, no hill silhouette.

### frozen_ice

Subject: Continuous frozen pond ice, muted pale icy blue and teal, sparse small angular pale frost lines and broad low-contrast facet patches. No deep cracks, no holes, no reflections of scenery, no snow border.

### nordic_water

Subject: Top-down calm shallow Nordic freshwater surface, muted dark teal-blue base with sparse short pale sage-blue horizontal ripple clusters and subtle broad tonal patches. Low contrast pixel art, no shore, no objects, no fish, no seabed, no sky reflections, no white foam border. Static water albedo for a repeated plane.

### woven_wool

Subject: Flat woven wool textile for rugs and blankets. Dusty burgundy and desaturated terracotta base, small regular stepped ivory and sage diamond weave motif widely spaced, restrained coarse pixel art, no rug silhouette, no fringe, no border, no text. Pattern repeats on both axes.

