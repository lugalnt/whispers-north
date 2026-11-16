# Camino nórdico v1

Tileset de tierra con exterior transparente. Arte generado con image_gen integrada; recurso de Godot preparado y probado con TileMapLayer.

## Archivos

- path_atlas.png: centro, cuatro bordes y cuatro esquinas exteriores.
- path_inner_corners.png: cuatro esquinas cóncavas.
- nordic_path_tileset.tres: 13 tiles de 32 × 32, dos fuentes.
- PathSample.tscn: parche rectangular pintado, compatible con source_scene de PathPatch.
- preview.png: captura de revisión en Godot, no parte del atlas.

Los originales son 1254 × 1254. Los archivos .png.import configuran process/size_limit=96, compresión sin pérdida y sin mipmaps. Godot importa cada atlas a 96 × 96; conservar estos ajustes para mantener la cuadrícula 3 × 3 de 32 px. No usar la resolución original como tamaño de celda. La importación reducida fue verificada en Godot.

## Coordenadas (x,y)

Fuente 0: (0,0) esquina NO, (1,0) norte, (2,0) NE; (0,1) oeste, (1,1) centro, (2,1) este; (0,2) SO, (1,2) sur, (2,2) SE.

Fuente 1: (0,0) recorte interior NO, (2,0) NE, (0,2) SO, (2,2) SE. Se usa una cuadrícula 3 × 3 también en este atlas para conservar tamaño y densidad de píxel, seleccionando solo sus cuatro celdas de las esquinas.

## Uso

Asignar el TileSet a TileMapLayer y pintar manualmente con filtro Nearest. Diseñado para caminos anchos de al menos tres celdas y plazas. Usar fuente 1 en entrantes; completar el resto con centro/bordes. No tiene terreno automático, piezas de callejón de una celda ni colisiones. Puede colocarse sobre pasto o nieve porque el exterior tiene alfa; no es una transición texturada de nieve acumulada.

PathPatch admite la escena fuente: empezar con meters_per_tile=0.5 y ajustar ancho en el mapa. No reemplazar directamente paths_tile_set.tres: cambian fuentes, coordenadas y tamaño de celda. Integrado en las cinco escenas de caminos de World y World_Town, conservando sus 1218 celdas y tamaño físico. Conversor idempotente en tools/migrate_paths.gd. Render de ambas zonas revisado; se aprecian variaciones de grano entre tiles.

## Verificación

Godot 4.7.2: ambas texturas importadas a 96 × 96; nueve tiles exteriores y cuatro interiores registrados. PathSample guardada y render rectangular inspeccionado. Las uniones de todas las combinaciones de esquinas y su aspecto en el mundo 3D requieren revisión al integrarse. Las variaciones generadas de grano/color no son matemáticamente seamless.

## Prompts exactos

Herramienta: image_gen integrada. transparent_background=true.

### Atlas exterior

Use case: stylized-concept. Production pixel-art game terrain TILESET ATLAS for Whispers of the North. Square canvas EXACTLY 1536x1536 if possible, divided conceptually into a 3 by 3 grid of equal square cells with NO gutters, NO grid lines and NO labels. Draw ONE continuous square patch of compact earth occupying the whole canvas except rounded-off outer corners and a thin transparent fringe around the OUTER perimeter. This is a nine-slice terrain: top left cell outer northwest corner, top center north edge, top right northeast corner; middle left west edge, center full earth, middle right east edge; bottom left southwest corner, bottom center south edge, bottom right southeast corner. All internal cell boundaries are uninterrupted earth with consistent color, no seams or margins. Earth should cover each edge cell except the outermost 10 percent band of its outward side. Rounded corner radius approximately 15 percent of whole canvas; outside is transparent. Soil muted taupe ochre brown matching a cozy Nordic village RPG with sage teal grass. Coarse deliberate square pixel clusters, quiet low contrast mottled dirt, sparse tiny flat pebbles, no directional shadows, no raised beveled border, no green grass baked in, no plants, no objects, no text or watermark. Top-down orthographic flat texture. Genuine transparent alpha outside soil, not a colored background. Keep opposite straight edges same pattern scale and same inset. Critical: this is one connected square dirt patch cut into nine cells by the engine, NOT nine disconnected squares.

### Esquinas interiores

Use case: stylized-concept. Production pixel art terrain INNER CORNERS atlas. Square canvas EXACTLY 1536x1536 if possible. A conceptual 2 by 2 grid with no gutters, no grid lines, no labels. All four cells filled with same low contrast muted taupe ochre brown compact earth, sparse small flat pebbles. In each cell remove ONLY a small quarter-circle notch of radius 28 percent of cell width at one corner, genuine transparent alpha: top left cell notch at its TOP LEFT corner; top right cell notch at its TOP RIGHT corner; bottom left cell notch at its BOTTOM LEFT corner; bottom right cell notch at its BOTTOM RIGHT corner. Everything else opaque earth. Thus the whole atlas is a square of earth with four small concave cutouts at its four outer corners; no holes at center or cell seams. Each cutout has clean stepped pixel-art edge. These are concave path tiles for a Nordic 2.5D RPG. Flat orthographic top down, crisp coarse square pixel clusters, no fine noise, no blur, no dark raised rim, no grass, no text, no objects. Match warm muted dirt_path ground and sage teal game palette. The transparency shows the underlying terrain. No borders between cells.

