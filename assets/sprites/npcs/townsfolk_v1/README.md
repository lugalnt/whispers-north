# NPCs genéricos del pueblo

Tres personajes originales, PNG con transparencia, una pose frontal de cuerpo completo por personaje.

- villager_woman.png: vecina con trenza, chaqueta verde y falda terracota.
- villager_worker.png: trabajador con gorro azul, barba y chaqueta ocre.
- villager_elder.png: vecina mayor con moño gris, chal azul y vestido burdeos.

Generados con image_gen integrada; prompts finales en PROMPTS.md. Son sprites estáticos de alta resolución con estética pixel art; no son atlas de caminar ni retratos separados. Pendientes de colocación, escala, pivote, vistas laterales/traseras y animación. No modifican NPCs ni diálogos existentes. Ajustar apoyo a los pies y usar filtrado nearest al integrarlos. Revisión visual realizada; sin pruebas dentro de Godot.


## Integración posterior
Integración realizada el 16/11/2026. Véase docs/ASSETS_INTEGRACION.md, sección «Integración de casa y aldeanos». El estado pendiente anterior documenta la entrega original. Los tres sprites ambientales permanecen sin integrar.


## Selección del usuario — 17/11/2026

Restaurados los tres primeros diseños como PNG principales (1024 × 1536). Las segundas versiones se conservan en alternatives_second_pass/. Prefabs del pueblo ajustados al nuevo recorte alfa y escala para mantener las alturas existentes. Se conserva el arte original sin modificar sus píxeles; el recorte usa el umbral alfa 128 acorde al alpha scissor del sprite. Prompts de la segunda versión permanecen como historial en PROMPTS.md. No se repitieron las pruebas visuales de Godot.
