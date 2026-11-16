# Decoración nórdica v1

Ocho sprites independientes, PNG RGBA de 1254 × 1254, fondo transparente. Generados con image_gen integrada usando el cofre existente como referencia de estilo. Prompts exactos en PROMPTS.md.

| Zona | Archivo | Objeto |
| --- | --- | --- |
| Casa | house_bookshelf.png | Estantería con libros, jarra y mantas |
| Casa | house_firewood.png | Leñero de abedul |
| Combate | combat_broken_pillar.png | Columna rota con musgo |
| Combate | combat_brazier.png | Brasero con llama estática |
| Pueblo | town_bench.png | Banco de madera y hierro |
| Pueblo | town_flower_planter.png | Jardinera con flores |
| Cueva | cave_stalagmites.png | Grupo de estalagmitas |
| Cueva | cave_mushrooms.png | Hongos sobre roca |

## Integración

Arte integrado en World_House, World_Town, World_Cave y CombatArena. Prefabs en scenes/world/Entities/NordicDecor. Son sprites de una sola vista, no modelos 3D. Usar Sprite3D/planos con transparencia y ajustar escala y apoyo al contenido visible, no al lienzo completo. Preferir filtro nearest para conservar los bordes escalonados. Revisar el resultado a la distancia de cámara real antes de reducir la resolución de importación.

No incluyen colisiones, interacción, luces ni animaciones. El brasero requiere luz y animación separadas si se desean; los hongos no son objetos de inventario. Situar columnas y braseros en el perímetro de combate para conservar visibilidad de personajes e interfaz. Revisar oclusión y pasos libres al colocar muebles y bancos.

## Validación realizada

Inspección visual de las ocho imágenes y comprobación de integridad PNG, tamaño y alfa (0–255) mediante Pillow. Posteriormente se verificaron escenas y capturas en Godot: combate grupal y paso libre de cueva sin fallos.


## Integración del paquete decorativo

Los ocho assets de nordic_decor_v1 están integrados mediante prefabs editables en scenes/world/Entities/NordicDecor. Recorte AtlasTexture con umbral alfa 128 para ignorar residuos casi transparentes, escala por altura visible y apoyo al suelo; originales PNG conservados.

- Casa: dos estanterías y un leñero.
- Pueblo: dos bancos y cuatro jardineras cerca de la plaza y fachadas.
- Arena: dos columnas, dos braseros con luz cálida y ocho elementos de borde reutilizados (rocas, hierba, arbustos y nieve). Centro reservado a combatientes.
- Cueva: ocho grupos de estalagmitas, ocho de hongos y cuatro leñeros junto a las paredes, además de los faroles/cajas/rocas existentes. Tonos fríos adaptados a la cueva.
- Decoración sin interacciones ni nuevas colisiones; los hongos no son recogibles y la llama dibujada del brasero sigue estática. No se modificó la dificultad ni el botín.
- Validación: grupo_jarrito_test.gd sin fallos; suggestions_test.gd sin fallos y corredor central libre en cuatro tramos. Capturas revisadas de arena, cueva, casa y plaza.
