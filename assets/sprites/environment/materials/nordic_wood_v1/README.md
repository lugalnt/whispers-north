# Maderas nórdicas v1

Seis texturas originales creadas con image_gen integrada para Whispers of the North. Cada PNG incluye un StandardMaterial3D .tres con filtro Nearest, repetición activada y rugosidad 1.

| PNG / material | Uso sugerido |
|---|---|
| light_pine_planks | Pisos interiores y tarimas |
| dark_oak_panels | Paredes, vigas y puertas oscuras |
| birch_furniture | Mesas, estantes y muebles claros |
| red_painted_siding | Fachadas y cobertizos |
| weathered_boardwalk | Puentes, terrazas y pasarelas |
| mossy_old_timber | Ruinas y construcciones abandonadas |

## Uso en Godot

Arrastrar el .tres a Material Override de la malla. Ajustar UV1 Scale según la superficie y orientar los UV para alinear la veta. Mantener una escala consistente de tablones entre habitaciones. Abedul no tiene juntas y funciona mejor para piezas de mobiliario; las otras variantes representan varias tablas.

Son mapas de color opacos, sin normal ni ORM. Se solicitó repetición continua en ambos ejes; la continuidad exacta de bordes no está certificada y debe comprobarse al repetir sobre la malla final. Revisión visual de las imágenes y verificación de archivos PNG realizada; sin prueba visual en el motor. No se han modificado escenas ni reemplazado texturas existentes.

## Prompts exactos

Herramienta: image_gen integrada. transparent_background=false. Una generación por textura.

Use case: stylized-concept. One seamless repeating albedo texture for Whispers of the North, cozy mysterious Nordic village 2.5D pixel-art RPG. A flat material surface filling the entire square canvas. Orthographic straight-on, no perspective, no scene or objects, no border, no labels, no watermark. Crisp intentionally low-resolution pixel-art shapes, coarse square pixel clusters, limited restrained colors, no photographic grain, no blur, no smooth gradients. Matte finish, flat even illumination, no baked directional highlights, no cast shadows. Quiet medium-scale grain, sparse simple knots, high readability at game scale. Opposite edges should connect naturally on both axes for repeated surface use. Square image, opaque background. Shared palette family: muted walnut, honey ochre, warm gray, charcoal blue, dusty terracotta and sage; only use colors appropriate to the specified wood.

### light_pine_planks

Material: Light Nordic pine interior floorboards. Long horizontal staggered planks, pale honey and warm cream-beige, sparse small ochre knots and restrained straight grain. Narrow muted taupe seams, calm domestic wood floor. No nails, no moss.

### dark_oak_panels

Material: Dark aged oak wall paneling. Broad vertical boards in desaturated walnut and deep umber, sparse stepped grain and small knots, narrow charcoal brown seams. Cozy old house interior, visibly dark but readable. No decorative carvings.

### birch_furniture

Material: Smooth birch wood for tables, shelves and furniture. Pale warm ivory and gray-beige with very subtle horizontal pixel-cluster grain, almost uniform and gently varied. Continuous solid wood surface, NO plank seams, no bark, no large knots.

### red_painted_siding

Material: Traditional muted Nordic red-painted timber exterior siding. Even narrow vertical boards, dusty brick-red and burgundy paint, subtle small worn areas revealing brown timber, sparse dark straight grain, narrow plum-brown seams. Restrained wear, no moss, no white trim.

### weathered_boardwalk

Material: Weathered gray timber decking for bridges and outdoor boardwalks. Long horizontal staggered planks, silver gray and desaturated blue-gray with hints of taupe, sparse stepped cracks and tiny dark nail pairs at board ends. Even wear, no snow, no moss.

### mossy_old_timber

Material: Old damp wooden planks for forest ruins and abandoned exterior walls. Vertical dark desaturated walnut boards with slate-brown weathering, sparse moss in muted sage concentrated along narrow seams and a few small patches, restrained shallow splits. Mostly wood, no leaves, no mushrooms, no exposed background.

