# Cuadro de diálogo nórdico v1

Asset dialogue_panel.png, 2172 × 724 RGBA. Fondo oscuro opaco, exterior transparente y tallas en esquinas. Generado con image_gen integrada; prompt exacto en PROMPT.md.

Basado en NordicDialogueBalloon.tscn y la textura button_normal.png que usa actualmente: panel horizontal inferior, PortraitContainer opcional a la izquierda, CharacterLabel y DialogueLabel en el centro, ProgressIndicator a la derecha. Retrato, nombre, texto y flecha siguen siendo controles independientes; no están dibujados en el asset.

El original generado tiene relación 3:1 y márgenes transparentes; ajustar región y escalado de StyleBoxTexture al integrarlo. Para conservar tallas al cambiar tamaño, preparar nine-slice con esquinas protegidas; márgenes por calibrar en la resolución real del juego. No se promete ajuste directo sin revisión.

Estado: generado, inspeccionado visualmente y validado como PNG RGBA con alfa 0–255. No reemplaza todavía el fondo en la escena. Pendientes asignación, márgenes y revisión de diálogos largos, retratos y distintas resoluciones en Godot.


## Integrado — 17/11/2026
Asignado en NordicDialogueBalloon.tscn. Importación a 768×256 con región útil y nine-slice; original conservado. Retrato ampliado a la izquierda, nombre y texto a la derecha. Captura de revisión: tests/ui_dialogue_preview.gd. Esta integración sustituye el estado pendiente de la entrega original.
