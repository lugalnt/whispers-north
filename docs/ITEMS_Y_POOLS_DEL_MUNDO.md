# Sistema de Ítems, Inventario y Pools del Mundo (Loot Tables)

Guía completa para diseñadores y desarrolladores sobre cómo editar ítems existentes, crear nuevos objetos, colocarlos en el mundo 3D y configurar tablas de botín (pools) en jarrones, cofres y combates.

---

## 1. Resumen: ¿Cómo funciona ahora?

Anteriormente, los objetos estaban declarados de forma fija dentro del script de `GameState`, impidiendo editar sus sprites o atributos desde el editor de Godot.

Ahora el sistema está basado en **Recursos (`.tres`)**, **Entidades 3D (`ItemPickup3D`)** y **Tablas de Botín (`ItemPool`)**, totalmente integrados al Inspector visual de Godot:

1. **Ítems como Recursos (`.tres`)**: Cada ítem es un archivo editable en el Inspector sin tocar una sola línea de código.
2. **Sprites personalizados**: Los iconos viven en `res://assets/sprites/items/` y pueden cambiarse arrastrando cualquier textura PNG/SVG al Inspector.
3. **Escaneo Automático (`ItemDatabase`)**: Cualquier archivo `.tres` que guardes en `res://data/items/` es descubierto e indexado automáticamente por el juego.
4. **Entidad 3D para el Mundo (`ItemPickup3D`)**: Permite colocar ítems flotantes en los niveles 3D con previsualización en vivo en el viewport (`@tool`), cartel flotante emergente y sonido al recogerse.
5. **Tablas de Botín (`ItemPool`)**: Permite configurar probabilidades y pesos para drops aleatorios.
6. **Integración Total**: Jarrones (`Pot`), Cofres (`Chest`), Combates (`EncuentroCombate`) e Inventario inicial (`GameState`) exponen ranuras en el Inspector para asignar ítems y pools.

---

## 2. Ítems por Defecto

Los ítems predeterminados viven en `res://data/items/`:

| Archivo | ID | Nombre | Categoría | Efecto | Icono |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `data/items/queso_nordico.tres` | `queso_nordico` | Queso Nórdico | Consumible | Restaura +5 HP | `assets/sprites/items/queso_nordico.png` |
| `data/items/fragmento_ceramica.tres` | `fragmento_ceramica` | Fragmento de Cerámica | Objeto General | Material / Coleccionable | `assets/sprites/items/fragmento_ceramica.png` |
| `data/items/llave_antigua.tres` | `llave_antigua` | Llave Antigua de Hierro | Objeto Clave | Abre cerraduras nórdicas | `assets/sprites/items/llave_antigua.png` |

---

## 3. Cómo Editar un Ítem Existente

1. En el panel **FileSystem** (Archivos) de Godot, entra a `res://data/items/`.
2. Haz doble clic en el ítem que desees modificar (por ejemplo, `queso_nordico.tres`).
3. En el panel **Inspector** (a la derecha) verás:
   - **Id**: Identificador único en texto (ej. `queso_nordico`).
   - **Nombre**: Nombre visible en el menú de pausa y notificaciones del juego.
   - **Descripcion**: Texto multilínea explicativo.
   - **Icono**: Textura 2D. Arrastra cualquier imagen desde tu explorador de archivos al campo **Icono**.
   - **Categoria**: Selector desplegable con `OBJETO`, `CONSUMIBLE` o `CLAVE`.
   - **Cantidad Maxima**: Límite por stack (por defecto 99).
   - **Curacion Hp**: Si es un consumible, la cantidad de vida que restaura al usarse en el menú de pausa o combate.

---

## 4. Cómo Crear un Nuevo Ítem

1. Haz clic derecho sobre la carpeta `res://data/items/` en el panel FileSystem de Godot.
2. Selecciona **Create New -> Resource...** (Crear Nuevo -> Recurso...).
3. En el buscador escribe `InventoryItem` y pulsa **Crear**.
4. Guárdalo con el nombre que desees, por ejemplo `pocion_curativa.tres`.
5. Selecciona el archivo recién creado y en el Inspector rellena sus datos:
   - Asigna un `id` único (ej: `pocion_curativa`).
   - Asigna el nombre, descripción, icono y categoría.
6. ¡Listo! `ItemDatabase` registrará tu nuevo ítem en cuanto inicies el juego o abras el inventario.

---

## 5. Cómo Colocar Ítems Recogibles en el Mundo 3D

Para colocar objetos coleccionables tirados en el mapa que el jugador pueda ver y recoger:

1. Abre cualquier escena 3D (por ejemplo, `World.tscn`).
2. Instancia la escena `scenes/world/Entities/ItemPickup.tscn`:
   - Arrástrala directamente desde el FileSystem al viewport 3D o al árbol de nodos.
3. Posiciona el nodo donde quieras en el mapa.
4. En el **Inspector** del nodo `ItemPickup`:
   - **Item**: Arrastra el recurso `.tres` del ítem que otorgará (ej. `queso_nordico.tres`).
   - *(En el mismo instante verás en el viewport 3D de Godot cómo el sprite cambia automáticamente al icono del ítem)*.
   - **Cantidad**: Número de unidades a entregar (ej. 1, 3, 5).
   - **Auto Recoger**: `true` para recoger al pasar por encima; `false` si requiere pulsar `interact`.
   - **Tiempo Espera Recolección**: Período de inmunidad (`0.6s` por defecto) para que el jugador vea el rebote tras romper un jarrón o ganar un combate sin recolección instantánea involuntaria.
   - **Tamaño y Animación**: Renderizado en reposo a tamaño compacto equivalente a `32x32` píxeles (`escala = 0.5`). Al recogerlo, se expande cinemáticamente a `64x64` (`escala = 1.0`), flota elevándose en el aire y se desvanece suavemente.
   - **Mostrar Texto Flotante**: Muestra un texto "+2 Queso Nórdico" al recogerse.
   - **Sfx Recoger**: Sonido que sonará al recogerlo (por defecto `snd_item.wav`).
   - **Tiempo Vida**: `0.0` para que nunca desaparezca, o número de segundos antes de desvanecerse.

### Spawneo dinámico desde GDScript:
```gdscript
# Suelta un ítem en una posición 3D con arco de salto parabólico e inmunidad durante el rebote:
var queso: InventoryItem = ItemDatabase.obtener_item("queso_nordico")
ItemPickup3D.spawn_en_posicion(get_tree().current_scene, posicion_global, queso, 2, true)
```

---

## 6. Sistema de Tablas de Botín / Pools del Mundo (`ItemPool`)

Las pools permiten agrupar varios ítems y definir qué tan frecuente o raro es cada uno al romper jarrones, abrir cofres o ganar combates.

Ejemplo incluido en: `res://data/item_pools/pool_mundo_general.tres`.

### Cómo crear una nueva Pool:
1. Clic derecho en `res://data/item_pools/` -> **Create New -> Resource...** -> `ItemPool`.
2. Guarda el archivo (ej. `pool_bosque.tres`).
3. En el Inspector:
   - **Nombre**: Nombre descriptivo de la pool.
   - **Entradas**: Añade elementos al array. Cada elemento es un sub-recurso `ItemPoolEntry` con:
     - **Item**: Recurso `InventoryItem` (.tres).
     - **Peso**: Peso relativo en sorteos (ej: peso 60 es el doble de frecuente que peso 30).
     - **Probabilidad**: Probabilidad individual de 0.0 a 1.0 (para drops múltiples).
     - **Cantidad Min** / **Cantidad Max**: Rango de unidades a soltar.

---

## 7. Configuración en Entidades del Juego

### A. Jarrones (`Pot.tscn` / `pot.gd`)
En el Inspector del jarrón:
- **Soltar Item Al Romper**: Activa o desactiva los drops al ser destruido o empujado.
- **Item Garantizado**: Recurso `.tres` que siempre suelta al romperse (ej. `fragmento_ceramica.tres`).
- **Cantidad Drop Garantizado**: Unidades a soltar.
- **Pool Items**: Tabla de botín opcional (`ItemPool`) para otorgar drops adicionales con probabilidad.
- **Probabilidad Pool**: Chance (0.0 a 1.0) de que la pool se active.

### B. Cofres (`Chest.tscn` / `chest.gd`)
En el Inspector del cofre:
- **Contiene Rata**: `true` si es el cofre especial con la rata que salta a la cabeza; `false` si es un cofre de tesoro convencional.
- **Item Recompensa**: Recurso `.tres` que otorga el cofre al abrirse (opcional).
- **Cantidad Item**: Cantidad otorgada.
- **Pool Items**: Tabla de botín opcional para elegir un objeto al azar.
- **Soltar Como Pickup 3D**: `true` para que el cofre expulse el ítem físicamente al suelo; `false` para enviarlo directamente al inventario con notificación.

### C. Encuentros de Combate (`EncuentroCombate.gd`)
En el Inspector del nodo `EncuentroCombate`:
- **Exp Recompensa**: Experiencia otorgada en victoria.
- **Items Garantizados**: Array de `InventoryItem` `.tres` que se añaden al inventario al vencer.
- **Pool Recompensas**: Recurso `ItemPool` opcional para recompensas aleatorias tras el combate.
- **Probabilidad Pool**: Probabilidad de que se active el drop de la pool.

### D. Inventario Inicial del Jugador (`GameState`)
En `GameState` (`scripts/core/game_state.gd`):
- **Items Iniciales**: Array de `InventoryItem` asignados visualmente.
- **Cantidades Iniciales**: Array de enteros correspondientes.
