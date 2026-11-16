# Casas originales del pueblo

Tres modelos exteriores originales, construidos con geometría editable de Godot y texturas existentes del proyecto. No dependen de los modelos placeholder ni de sus atlas.

| Modelo | Ancho × fondo del edificio | Fachada |
|---|---|---|
| CasaRoja | 5.6 × 4.2 | Madera pintada roja |
| CasaEntramado | 5.8 × 4.2 | Yeso claro y vigas oscuras |
| CasaPorche | 5.8 × 4.6 | Roble oscuro y porche frontal de 1.35 unidades |

## Archivos y uso

- `.tscn`: fuente editable, piezas MeshInstance3D, materiales, colisión y marcador Entrance. Arrastrar al mapa a escala 1. Frente hacia +Z y origen al nivel del terreno.
- `.glb`: exportaciones de geometría/materiales para otras herramientas. Usar las escenas `.tscn` para conservar la configuración física y marcadores de Godot.
- `Preview.tscn`: vista conjunta para F6; `preview.png`: captura real del motor.
- `tools/build_nordic_houses.py`: generador reproducible de las tres escenas. Al regenerar sobrescribe estas escenas; exportaciones GLB y captura deben actualizarse después.

Las mallas incluyen cuerpo, frontones, dos faldones de tejado, cumbrera, aleros, marcos, cristales, travesaños, puertas, umbral y chimenea. Materiales con filtro Nearest. Las texturas se asignan por pieza, sin atlas compuesto. Son exteriores de formas simples para el escenario 2.5D; no interiores habitables ni puertas animadas.

La colisión es una caja para el volumen principal; no sigue tejado, aleros, umbral ni porche. Entrance indica una posición delante de la puerta para una futura transición. Sin lógica de interacción ni conexiones al gameplay.

## Integración pendiente

World_Town sigue usando casas placeholder con escalas 0.1 y 0.15. No sustituir sus recursos directamente sin normalizar escala, comprobar orientación, terreno, caminos, visibilidad y colisiones. Estas casas usan unidades del mundo y escala 1.

## Verificación

Las tres escenas se instanciaron correctamente en Godot 4.7.2; comprobados CollisionShape3D y Entrance, exportación GLB y render conjunto. Inspección visual de la captura completada. No se han sustituido casas ni probado recorridos en World_Town.
