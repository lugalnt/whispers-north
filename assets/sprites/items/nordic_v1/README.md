# Objetos nórdicos v1

11 assets PNG con transparencia, generados con image_gen integrada y revisados visualmente.

| Archivo | Uso |
|---|---|
| chest_closed.png | Cofre cerrado |
| chest_open.png | Cofre abierto vacío |
| rye_bread.png | Pan de centeno |
| nordic_cheese.png | Queso nórdico |
| wild_berries.png | Bayas del bosque |
| short_sword.png | Espada corta |
| wood_axe.png | Hacha de leñador |
| ceramic_shard.png | Fragmento de cerámica / drop |
| forest_crystal.png | Cristal / material de botín |
| coin_pile.png | Monedas de latón con emblema de pino |
| old_wood_key.png | Llave antigua de madera |

## Uso en Godot

Asignar el PNG al campo icono de un recurso InventoryItem o a Texture de Sprite2D/Sprite3D. Usar filtro Nearest y conservar relación de aspecto; probar iconos a 64–96 px en el inventario. Son originales de alta resolución con apariencia pixelada, no archivos nativos de 64 px.

Correspondencias con datos actuales: nordic_cheese → queso_nordico, ceramic_shard → fragmento_ceramica, old_wood_key → llave_antigua. No se han reemplazado iconos, estadísticas, tablas de drops ni recursos existentes. Armas y monedas son assets visuales: no añaden sistemas de equipamiento o economía.

Los dos cofres comparten diseño y lienzo cuadrado; mantener igual escala y revisar alineación al intercambiarlos en la escena final. No incluyen animación intermedia ni lógica de apertura.

## Prompts exactos

Herramienta: image_gen integrada. Fondo transparente (transparent_background=true). Una llamada por objeto.

Use case: stylized-concept. Production game sprite/icon for Whispers of the North, cozy mysterious contemporary Nordic fairy-tale RPG with pixel art characters in 2.5D. One isolated object, transparent background with genuine alpha. Clean bold square pixel clusters, low-resolution pixel art appearance, restrained palette, no photorealism, no smooth painted detail, no blur, no glow or particles. Muted walnut wood, slate blue-gray iron, sage greens, warm ochre and dusty terracotta. Three-quarter view with slightly visible top, consistent soft upper-left lighting. Simple very readable silhouette recognizable at 64px. Entire object centered inside a square canvas with 10 percent empty transparent padding; no floor, no ground shadow, no frame, no labels, no text, no watermark, no UI. Fantasy domestic village mood, restrained decoration.

### chest_closed

Subject: One small closed wooden treasure chest, walnut planks, slate iron bands, simple bronze central latch, subtle Nordic incised corner details, flat base. No treasure outside.

### rye_bread

Subject: One small rustic oval rye bread loaf, golden ochre crust with three simple score marks, one cut end showing pale crumb. No plate.

### nordic_cheese

Subject: One triangular wedge of smoked Nordic cheese, warm ivory interior with a few small holes and dusty ochre rind. No plate.

### wild_berries

Subject: One small cohesive cluster of five dusty red forest berries attached to a short stem and two sage green leaves.

### short_sword

Subject: One modest short iron sword, full blade and hilt visible, diagonal from lower left to upper right. Slate gray broad blade, simple crossguard, brown leather grip, no blood, no magical effects.

### wood_axe

Subject: One small practical woodcutter axe, short walnut handle angled lower left to upper right, single blue-gray iron head, simple leather wrap, no blood, no ornaments.

### ceramic_shard

Subject: One large broken curved pottery fragment, dusty terracotta with a simple faded sage geometric incised marking, pale clay visible along broken edges. No readable symbols.

### forest_crystal

Subject: One compact mineral cluster with three angular translucent-looking blue-green crystal points attached to a small slate base, muted teal facets, no glow.

### coin_pile

Subject: One small readable pile of five worn warm brass coins, one leaning face-on with a simple incised pine branch emblem, muted ochre gold, no letters or numerals, no sparkles.

### old_wood_key

Subject: One old mossy oak wooden key, large rounded bow with an open center, short shaft and two clearly visible teeth, restrained sage moss near bow, diagonal lower left to upper right, clearly a key rather than a weapon.

### chest_open (edición de chest_closed)

Use case: precise-object-edit. Edit this exact chest sprite into its OPEN, EMPTY state for the same game's sprite pair. Keep the lower chest body, front panel, carved corner motifs, metal bands, brass latch, perspective, scale, pixel style, color palette and position of the bottom edge unchanged. Only raise the hinged curved lid backwards to reveal a dark empty wooden interior. No coins, no glow, no items, no particles. Keep the same square canvas, transparent background and original alpha outside the object. Do not resize or recenter the lower body. Leave all of the open lid within canvas.

### coin_pile (limpieza final)

Use case: background-extraction. Clean this game coin sprite. Preserve the coins, pine emblem, color palette, pixel art style, size and placement exactly. Remove ALL stray gray and yellow speckles, halo, smudges, shadow and background residue outside the solid silhouette of the coins. Outside the coins must be fully transparent alpha zero. Crisp clean silhouette, no glow, no added elements. Preserve transparent background.

