# Texturas Nordic v1

Seis texturas originales generadas con la herramienta integrada image_gen para Whispers of the North. Inspiración: fantasía doméstica nórdica, escenarios 2.5D, texturas pixeladas y colores apagados del proyecto.

| Archivo | Uso |
|---|---|
| wood_wall.png | Fachadas de madera y vigas |
| red_roof.png | Tejados de teja roja |
| cold_grass.png | Suelo exterior y praderas |
| dirt_path.png | Caminos de tierra |
| combat_ground.png | Suelo de combate de bajo contraste |
| village_stone.png | Plazas, adoquines y ruinas |

## Uso en Godot

Cada PNG incluye un StandardMaterial3D .tres con filtro Nearest, repetición activada y rugosidad 1. Arrastrar el .tres a Material Override de la malla correspondiente. Ajustar UV1 Scale a las dimensiones de la superficie; comenzar con 1–4 repeticiones y revisar a distancia de juego. Para fachadas con atlas UV propio es necesario reasignar los UV o separar las superficies: no son reemplazos directos de los atlas de casas existentes.

Los assets están disponibles como paquete independiente; no se han cambiado las escenas existentes. Son mapas de color, sin mapas normal ni ORM. Se solicitó repetición en ambos ejes; la continuidad exacta de las juntas y la escala visual deben comprobarse en las mallas finales. Revisión visual realizada sobre las imágenes generadas, sin validación dentro del motor.

## Prompts exactos

Herramienta: image_gen integrada, fondo opaco, una generación por material.

Prompt base:

Use case: stylized-concept. Create one square seamless repeating game albedo texture for Whispers of the North, a cozy mysterious contemporary Nordic village fairy-tale RPG with pixel-art characters in a 2.5D world. Crisp low-resolution pixel art, visibly square pixel clusters, restrained 12-color palette, no antialiasing, no photographic detail. Orthographic flat material surface filling entire image, no perspective, no scene, no objects, no labels, no borders, no text, no watermark, no directional lighting or cast shadows. Match opposite edges for tiling on both axes. Quiet texture with readable medium-scale shapes and low contrast.

### wood_wall

Material: Weathered vertical Nordic timber siding, muted warm walnut and honey brown, narrow dark seams, sparse simple knots, domestic cabin facade, no snow.

### red_roof

Material: Regular staggered rows of small rounded red clay roof tiles, muted terracotta and dusty burgundy, subtle cool plum shadow lines, simple rhythmic pixel shapes.

### cold_grass

Material: Cold northern meadow grass, muted sage and teal greens, sparse tiny grass tufts, mostly calm even ground, no flowers, no rocks, no snow.

### dirt_path

Material: Compact village path earth, muted taupe and warm ochre, very sparse tiny flat pebbles, subtle wear patches, evenly distributed texture, no grass or border.

### combat_ground

Material: Quiet compact earth and fine gravel for a turn-based combat arena floor, cool gray taupe with faint desaturated sage patches, extremely low contrast center and edges alike, no arena circle, no symbols, no large rocks, no props. Keep fighters readable.

### village_stone

Material: Rounded irregular village cobblestones, medium sized slate gray and muted blue gray stones with sparse desaturated moss in narrow joints, flat stylized pixel clusters, domestic fairy-tale village pavement.

