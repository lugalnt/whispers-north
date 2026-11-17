# Casa y ambiente v1 — 16 de noviembre de 2026

14 PNG generados con image_gen integrada. Prompts finales en PROMPTS.md.
Nueve mapas de color RGB y cinco sprites RGBA con transparencia. Todos 1254 × 1254 excepto wall_clock (1199 × 1312). Originales conservados sin reducción.

## Análisis de escenas y asignación prevista

Revisión de los nodos y materiales de scenes/world/World_House.tscn (Cuarto y PlantaBaja), escenas House_Violet y modelos assets/models/nordic_houses. Interior construido principalmente con CSGBox3D, con maderas compartidas y varios colores planos. No hay nodos de ventanas en World_House al momento de esta revisión. Los modelos exteriores originales sí tienen Frame, Glass, Mullion, Cross y Sill.

| Textura | Destino |
| --- | --- |
| furniture_oak.png | Cama, MesaDiario y patas, MesaComedor, BarreraComedor, cuerpos de Ropero/Aparador, EspejoMarco, CuadroMarco; también marcos/travesaños de ventanas |
| bed_linen.png | Colchon y Almohada; material independiente del papel del diario |
| book_pages.png | Cuarto/Diario/Paginas, líneas paralelas al canto |
| diary_cover.png | Cara superior de Cuarto/Diario/Tapa |
| window_glass.png | Glass de ventanas exteriores y cara visible de Espejo; reflexión dibujada, no espejo real |
| nordic_wool.png | Manta y Alfombra, un panel ajustado a cada superficie |
| cabinet_front.png | Cara frontal de PuertaRopero y Aparador |
| moving_crate.png | CajaMudanza, CajaSobrepuesta y CajasMudanza |
| mountain_painting.png | Cara visible de PlantaBaja/Cuadro, dentro del marco existente |

Puertas, escalera, peldaños, suelo y paredes ya tienen materiales nórdicos; conservarlos. Para frontales con tiradores, cubierta del diario y cuadro usar UV 0–1 por cara o plano frontal separado: no aplicar el dibujo mediante triplanar a todo el bloque. furniture_oak y bed_linen admiten repetición como intención artística; continuidad seamless no verificada. Las demás texturas se diseñaron como paneles, no tiles. Glass es opaco y sin marco porque las ventanas exteriores ya tienen marco geométrico. Los modelos heredados requieren revisar sus UV por separado.

## Pared y ambiente

- wall_clock.png: reloj de pared frontal con péndulo, estático.
- wall_herbs.png: riel de hierbas secas para pared de cocina/comedor.
- falling_leaf.png: hoja aislada para partículas de caída y giro.
- dragonfly.png: libélula vista desde arriba, una pose de vuelo.
- flying_bird.png: ave con alas elevadas hacia la derecha, una pose.

Los tres elementos ambientales son imágenes base, no ciclos animados. Pendientes emisión, trayectoria, variación de escala, aleteo y prueba de lectura a distancia. Sprites de pared sin billboard, apoyados en un plano paralelo a la pared.

## Estado y comprobación

Generados y revisados visualmente. Verificada integridad de los 14 PNG con Pillow y alfa 0–255 de los cinco sprites. Se regeneraron cuatro sprites para eliminar halos visibles. No se han asignado estos archivos a escenas ni cambiado geometría o gameplay. Pendientes materiales, UV, escala y validación visual dentro de Godot; no se afirma que las superficies estén ya texturizadas en el juego.


## Integración posterior
Integración realizada el 16/11/2026. Véase docs/ASSETS_INTEGRACION.md, sección «Integración de casa y aldeanos». El estado pendiente anterior documenta la entrega original. Los tres sprites ambientales permanecen sin integrar.
