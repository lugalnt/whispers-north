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

## Integración en el pueblo — 16 de noviembre de 2026

World_Town usa estos modelos en sus 13 casas. Escala 0.76 salvo House_C2 a 1.05; apoyo en Y=0.07861329 y fachadas orientadas hacia las calles. Las puertas continúan siendo decorativas. El exterior de la casa del protagonista en World mantiene su modelo y conexión existentes.

## Verificación

Instanciación y render del pueblo revisados en Godot Compatibility. recorrido_fase1_test.gd completado sin fallos tras la sustitución. Esta prueba cubre transiciones y llegadas; no simula caminar alrededor de cada vivienda.
