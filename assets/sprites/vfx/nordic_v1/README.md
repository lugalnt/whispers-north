# Efectos pequeños nórdicos v1

Cuatro sprites PNG RGBA creados con image_gen integrada:

| Archivo | Uso | Duración sugerida |
|---|---|---|
| hit_spark.png | Impacto de golpe | 0.12–0.20 s |
| step_dust.png | Polvo de pisada | 0.25–0.40 s |
| water_splash.png | Salpicadura | 0.20–0.35 s |
| pickup_glint.png | Destello de recogida | 0.25–0.45 s |

## Uso y límites

Cada imagen es un único fotograma del efecto, no una animación ni spritesheet. Se pueden usar en Sprite2D, Sprite3D o partículas. Ajustar el tamaño a 32–64 px en pantalla; los originales conservan su resolución de generación. Usar Nearest. Mantener alfa para las transparencias suaves del impacto y polvo; no interpretar el fondo negro de algunas previsualizaciones como parte de la imagen.

Para animarlos, añadir escala breve y desvanecimiento con AnimationPlayer/Tween o un emisor one-shot. Las duraciones de arriba son sugerencias, no comportamiento implementado. Sin scripts, daño, audio, disparadores ni conexiones al combate/movimiento. Pendientes de integración y prueba visual sobre fondos claros/oscuros.

## Prompts exactos

Herramienta: image_gen integrada, transparent_background=true.

Use case: stylized-concept. One isolated SMALL game visual effect sprite for Whispers of the North, cozy mysterious Nordic 2.5D pixel-art RPG. Genuine transparent alpha background, one compact centered effect at its peak, not a sprite sheet, no ground, no border, no text. Entire effect visible with 15 percent transparent padding. Crisp coarse square pixel clusters, simple silhouette readable at 32 to 64 pixels, restrained palette, no photorealistic smoke, no blur, no diffuse glow, no black outline rectangle. Flat front view, no objects or characters. Colors consistent with muted sage, ivory, ochre and slate blue game palette.

### hit_spark

Subject: A compact asymmetric impact flash, warm ivory center with muted ochre four-point jagged burst, four small short detached pixel sparks, no fire, no explosion cloud.

### step_dust

Subject: A small low horizontal puff of footstep dust, three overlapping chunky light taupe and warm gray pixel clouds, a few square flecks, no feet, no rocks, no floor shadow.

### water_splash

Subject: A small upward splash of freshwater, pale icy blue and teal curved central splash with five clear detached chunky droplets, no water surface or background, crisp silhouette.

### pickup_glint

Subject: A compact four-point pale ivory and sage magical collectible sparkle with two tiny offset diamond sparkles, subdued cool palette, crisp pixel clusters, no aura or fog.

