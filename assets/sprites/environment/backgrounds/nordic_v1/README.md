# Fondo de montañas nórdicas v1

Asset: snowy_mountain_panorama.png. PNG RGBA de 1774 × 887 px (2:1), generado con image_gen integrada el 16 de noviembre de 2026. Cielo transparente, cordillera nevada y estribaciones verde pino. Las capas están dibujadas en una única imagen, no separadas para parallax.

## Uso en Godot

Asignar a Texture de Sprite3D del fondo; filtro Nearest, sin sombras. Mantener la relación 2:1 y situar la base detrás del terreno visible. Comprobar el encuadre con las cámaras del mapa y de combate por separado. La textura anterior mide 510 × 271: al sustituirla, reducir pixel_size por el factor 510/1774 (aprox. 0.2875) conserva la anchura, pero se debe ajustar altura/posición por la diferencia de proporción y silueta. No conservar la escala sin revisar, pues el fondo crecería.

Se solicitó continuidad lateral aproximada, pero no está certificada como mosaico sin juntas. Evitar repetir el pico principal muchas veces: preferir un panorama amplio y evaluar uniones/solapamientos. No incluye cielo, nubes, animación ni una capa de niebla independiente.

Estado: generado y verificado como PNG con alfa; no aplicado a World, World_Town ni CombatArena. Se conserva mountain_snowy_background.png. Falta validación visual en las cámaras finales.

## Prompt exacto

Herramienta: image_gen integrada. transparent_background=true.

Use case: stylized-concept. Asset type: production panoramic mountain-background sprite for Whispers of the North, a cozy mysterious Nordic village fairy-tale RPG with pixel art characters in a 2.5D world. Create an original wide roughly 2:1 landscape strip of snowy Nordic mountains, isolated on a genuinely transparent sky. Mountain terrain fills the entire bottom edge and reaches both left and right edges; only the area ABOVE the ridgeline is transparent. No isolated floating island, no empty margin at bottom. Three restrained layers: distant desaturated blue-gray peaks, middle slate and muted lavender rock with warm ivory snow caps, nearer dark desaturated pine-teal foothills forming a continuous solid base. Five or six irregular readable peaks, highest peak offset from center, smaller peaks toward edges. Match left/right edge height and color as closely as possible to support side-by-side placement. Crisp deliberate pixel art with broad stepped silhouettes and coarse square pixel clusters, simple snow shapes, limited muted palette, minimal texture noise, no photorealism, no painterly blur, no hatching. Snow highlights gentle, low contrast slopes, dark calm base. Domestic fairy-tale mood, peaceful cold daylight, not epic fantasy. Flat frontal distant landscape, no perspective ground plane, no water, no houses, no trees drawn as individual foreground objects, no characters, no sun, no clouds, no stars, no mist halo outside silhouette, no text, no watermark, no border. The image is a flat background cutout, NOT a seamless material surface. Keep all peaks inside image with a small transparent margin above the tallest peak.

