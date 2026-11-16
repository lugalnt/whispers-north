# Decoración nórdica v1

Seis PNG RGBA originales generados con image_gen integrada (fondo transparente), y seis escenas listas para instanciar desde res://scenes/world/Entities/NordicProps/.

| Asset | Alto visible en unidades | Colisión |
|---|---:|---|
| nordic_pine | 5 | Cilindro, radio 0.38 |
| grass_tuft | 0.55 | Sin colisión; transitable |
| mossy_rock | 1.5 | Cilindro, radio 0.85 |
| snow_bank | 1.1 | Cilindro, radio 1 |
| wildflowers | 0.65 | Sin colisión; transitable |
| dense_bush | 1.35 | Cilindro, radio 0.8 |

Arrastrar las escenas .tscn al mapa. Origen al pie del sprite; filtro Nearest y billboard fijo sobre Y para mantenerlo vertical. Alpha scissor 0.5 elimina el halo semitransparente de los originales. Los archivos PNG mantienen el alfa original. Las colisiones ocupan la base, no toda la copa del árbol. StaticBody3D en capa 1, compatible con personajes cuya máscara incluya esa capa.

Para límites continuos, solapar ligeramente los cilindros de rocas, arbustos o nieve; la amplitud visual del follaje no equivale a su colisión. El pino bloquea solo el tronco. Ajustar CollisionShape3D en el editor según cada camino. Para una variante decorativa, activar CollisionShape3D.disabled. Pasto y flores no bloquean.

No se han modificado ni poblado los mapas existentes. Tamaños y colisiones iniciales requieren ajuste visual al diseño de cada mapa.

## Prompts exactos

Herramienta: image_gen integrada. Una llamada por asset, transparent_background=true.

Use case: stylized-concept. Asset type: one isolated transparent-background Sprite3D game prop for Whispers of the North, cozy mysterious contemporary Nordic village fairy-tale RPG. Match a muted pixel-art world with sage/teal grass, warm walnut timber, dusty terracotta roofs and blue-gray cobblestones. True crisp pixel-art appearance, large clean square pixel clusters, restrained palette, no antialiasing or photographic microtexture. Front three-quarter view with a little visible top surface, suitable as a camera-facing billboard in a 2.5D RPG. One complete object centered, entirely inside canvas with modest transparent padding. Base resting on a single horizontal baseline. Transparent background with genuine alpha, no ground plane, no cast shadow outside the object, no text, no labels, no border, no watermark. Gentle upper-left highlights, readable silhouette, domestic fairy tale rather than epic Viking fantasy.

### nordic_pine

Subject: A single tall Nordic evergreen pine tree, layered slightly asymmetric triangular boughs, deep desaturated teal and sage foliage, visible short warm brown trunk at bottom, no snow.

### grass_tuft

Subject: One compact clump of wild northern grass, several pointed blades spreading naturally, desaturated sage and teal greens with a few straw-colored tips, no soil mound.

### mossy_rock

Subject: One broad solid irregular boulder that clearly blocks a path, blue-gray slate planes with sparse muted moss along top crevices, solid base, softened angular silhouette.

### snow_bank

Subject: One broad deep piled snowbank that clearly blocks passage, softly stepped irregular mound, ivory-white top and pale blue lavender pixel shadows, small rounded lobes forming one cohesive bank, no grass or rocks.

### wildflowers

Subject: One small natural clump of Nordic wildflowers, five tiny ivory and dusty lavender blossoms with muted ochre centers and sage stems and leaves, varied heights, no pot, no ground.

### dense_bush

Subject: One dense wide rounded Nordic shrub suitable for a hedge barrier, overlapping readable foliage masses in desaturated dark teal and sage green, sparse light leaf clusters, broad solid leafy silhouette, no berries or flowers.

