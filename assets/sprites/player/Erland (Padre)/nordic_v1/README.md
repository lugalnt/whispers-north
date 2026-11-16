# Erland Erki — arte v1

Padre de Finn, empresario de 45 años: cabello blanco peinado, lentes, mostacho y barba corta; traje carbón, chaleco azul y camisa marfil. Diseño basado en los sprites actuales de Finn.

## Archivos

- `erland_idle_directions.png`: PNG RGBA 1254 × 1254, cuatro poses estáticas en cuadrícula 2 × 2. Frente, perfil derecho, espalda, perfil izquierdo (orden por filas).
- `erland_portrait.png`: PNG RGBA 1312 × 1199, busto sereno para diálogos y consejos.
- `PROMPTS.md`: instrucciones exactas y referencias utilizadas con image_gen integrada.

## Uso y estado

Originales de alta resolución con estética pixel art y fondo transparente. La hoja tiene cuatro celdas de 627 × 627; para AtlasTexture usar Rect2(0,0,627,627), Rect2(627,0,627,627), Rect2(0,627,627,627), Rect2(627,627,627,627). Ajustar pivote, tamaño visual y muestreo nearest al integrarlos. No es una hoja animada ni reemplazo directo del atlas antiguo de 16 × 16.

Generados y revisados visualmente; ambos PNG verificados con Pillow y alfa de 0 a 255. Integrados en World_House: las cuatro poses se seleccionan con scripts/world/erland_visual.gd al aproximarse el protagonista; retrato conectado al diálogo de Papá. AtlasTexture ajusta el recorte al alfa de cada celda, altura visual 1.9 y pies a 0.05 sobre el origen del NPC. Los originales se conservan sin remuestrear. Revisión visual del diálogo en Godot y casa_fase2_test.gd completados (23 pruebas, 0 fallos). Pendientes: cuadros de caminar/interacción y eventual adaptación artística a resolución final más baja.
