# Sistema de Combate RPG por Turnos (Estilo Paper Mario)

Documentación técnica y guía de uso para desarrolladores y diseñadores en Godot 4 (GDScript).

---

## 1. Visión General

El sistema de combate está inspirado en el ritmo dinámico de **Paper Mario** y la arquitectura modular de **Godot Open RPG**:
- **Combate por turnos 2.5D**: Los combatientes se ordenan por iniciativa (velocidad).
- **Comandos de Acción (Timing / QTE)**: El jugador puede potenciar sus ataques o esquivar impactos presionando el botón de acción en el momento justo.
- **Totalmente desacoplado del supramundo**: La batalla ocurre en una arena aislada en altura (`Y = 200.0`), garantizando cero colisiones o interferencias con el escenario exterior.
- **Configurable visualmente**: Toda la orquestación se gestiona mediante el nodo personalizado `EncuentroCombate`, editable directamente desde el Inspector de Godot sin necesidad de programar.

---

## 2. Nodo Custom: `EncuentroCombate`

- **Ruta del script:** [`res://scripts/combat/encuentro_combate.gd`](../scripts/combat/encuentro_combate.gd)
- **Tipo de nodo:** `Node` (puede colocarse como hijo de cualquier entidad, cuerpo físico, NPC o disparador `Area3D`).

### Propiedades en el Inspector de Godot

| Grupo | Propiedad | Tipo | Valor por Defecto | Descripción |
|---|---|---|---|---|
| **Estado del Encuentro** | `activo` | `bool` | `true` | Habilita o deshabilita el combate con un solo clic. Si está desactivado, el trigger ignora la pelea. |
| **Combatientes** | `enemigos` | `Array[PackedScene]` | `[PotBattler.tscn]` | Escenas de los enemigos que aparecerán en la arena (1 o más). |
| | `aliados` | `Array[PackedScene]` | `[PlayerBattler.tscn]` | Escenas de los aliados (jugador por defecto). |
| **Personalización Arena** | `escena_arena` | `PackedScene` | `CombatArena.tscn` | Escena de la arena a instanciar. |
| | `musica_combate` | `AudioStream` | `null` | Música personalizada para este encuentro (si es `null`, usa la de la arena). |
| | `textura_fondo` | `Texture2D` | `null` | Textura de fondo (2D/3D) para el escenario (e.g. cueva, bosque, nieve). |
| | `altura_aislamiento` | `float` | `200.0` | Altura `Y` a la que se instancia la arena en el mundo para evitar clipping. |
| **Efecto de Inicio (Flash y Jingle)** | `flash_activo` | `bool` | `true` | Produce un destello en pantalla al comenzar el combate. |
| | `color_flash` | `Color` | `Color.WHITE` | Color del destello en pantalla. |
| | `cantidad_flashes` | `int` | `2` | Número de parpadeos en el destello inicial. |
| | `duracion_flash` | `float` | `0.07` | Duración en segundos de cada parpadeo del destello. |
| | `jingle_inicio` | `AudioStream` | `null` | Jingle de inicio. Si se deja en `null`, **hereda automáticamente el jingle asignado en el nodo principal de CombatArena.tscn**. Si se asigna aquí o en la entidad, tiene prioridad. |
| **Textos del Encuentro (HUD)** | `texto_inicio_combate` | `String` | `""` | Mensaje al iniciar la batalla. Si se deja vacío, usa el de la arena. |
| | `texto_victoria` | `String` | `""` | Mensaje en banner al ganar. Si se deja vacío, usa el de la arena. |
| | `texto_derrota` | `String` | `""` | Mensaje en banner al perder. Si se deja vacío, usa el de la arena. |
| | `texto_huida` | `String` | `""` | Mensaje en banner al huir. Si se deja vacío, usa el de la arena. |
| | `texto_titulo_recompensas` | `String` | `""` | Título del banner de recompensas (ej. "RECOMPENSAS", "BOTÍN"). |
| **Recompensas** | `exp_recompensa` | `int` | `20` | Puntos de experiencia otorgados en victoria. |
| | `texto_recompensas` | `String` (multilínea) | Ver texto por defecto | Mensaje que se despliega en el panel de victoria. |
| **Transición** | `color_fundido_entrada` | `Color` | `Color.WHITE` | Color del destello/cortina al iniciar la pelea. |
| | `duracion_fundido_entrada` | `float` | `0.16` | Duración en segundos de la transición de entrada. |
| | `color_fundido_salida` | `Color` | `Color.BLACK` | Color del fundido al volver al supramundo. |
| | `duracion_fundido_salida` | `float` | `0.22` | Duración en segundos de la transición de salida. |
| **Disparador Automático** | `auto_iniciar_en_area` | `bool` | `false` | Si el padre es un `Area3D`, inicia el combate automáticamente al entrar el jugador. |
| | `auto_eliminar_padre_en_victoria` | `bool` | `false` | Si es `true`, destruye el nodo padre tras la victoria. |

### Configuración de Textos del HUD en `CombatArena.tscn`

En el **nodo principal** (`CombatArena`), se expone el grupo `@export_group("Textos de la Interfaz (HUD)")` para editar o localizar todos los textos de la interfaz directamente desde el Inspector:
- `texto_inicio_combate`: "¡Empieza el combate!"
- `formato_texto_turno`: "Turno de %s"
- `texto_titulo_acciones`: "ACCIONES"
- `texto_opcion_huir`: "Huir"
- `texto_descripcion_huir`: "Escapar del combate y volver al mapa."
- `texto_victoria`: "¡Victoria!"
- `texto_derrota`: "Has sido derrotado..."
- `texto_huida`: "¡Escapaste del combate!"
- `texto_titulo_recompensas`: "RECOMPENSAS"
- `formato_hp`: "%d / %d HP"

### Edición desde el Nodo Principal en Entidades (Ej. `Pot.tscn`)

Para máxima comodidad al diseñar niveles, las entidades del mundo exponen estas mismas propiedades directamente en su **nodo principal** bajo el grupo `@export_group("Combate RPG")`:
- `jingle_combate`: AudioStream personalizado.
- `musica_combate`: Música temática para la pelea.
- `textura_fondo_combate`: Textura de fondo para la arena.
- `texto_inicio_combate`: Mensaje inicial personalizado.
- `texto_victoria_combate`: Mensaje de victoria personalizado.
- `texto_recompensas_combate`: Texto multilínea de recompensas.
- `exp_recompensa_combate`: Puntos de experiencia.

Cualquier valor asignado en el nodo principal se sincroniza automáticamente con el componente de encuentro y la arena.

### Señales del Editor (Pestaña "Nodo / Señales")

- `combate_iniciado()`: Se emite al comenzar la batalla.
- `combate_terminado(resultado: CombatArena.ResultadoCombate)`: Se emite al resolver el combate con el enum (`VICTORIA`, `DERROTA`, `HUIDA`).
- `victoria()`: Se emite si todos los enemigos caen.
- `derrota()`: Se emite si todos los aliados caen.
- `huida()`: Se emite si el jugador escapa.

---

## 3. Guía de Uso Práctico

### Caso A: Agregar combate a un objeto o enemigo del mundo (Ej. Jarrón `Pot`)

1. En la escena de la entidad (ej. [`scenes/world/Entities/Pot.tscn`](../scenes/world/Entities/Pot.tscn)), agrega un nodo hijo de tipo `EncuentroCombate`.
2. En el Inspector del nodo hijo, arrastra las escenas de los enemigos deseados a `enemigos` y ajusta el texto de recompensa.
3. En el script de la entidad (ej. [`scripts/world/pot.gd`](../scripts/world/pot.gd)):

```gdscript
var encuentro: EncuentroCombate = get_node_or_null("EncuentroCombate")
if encuentro and encuentro.activo:
    var resultado = await encuentro.iniciar_combate(jugador, nodo_visual)
    match resultado:
        CombatArena.ResultadoCombate.VICTORIA:
            destruir_entidad()
        CombatArena.ResultadoCombate.DERROTA:
            hacer_reaparecer_jugador()
        CombatArena.ResultadoCombate.HUIDA:
            aturdir_o_esperar()
```

### Caso B: Crear una zona de emboscada en el mapa (Sin código)

1. Añade un nodo `Area3D` al mapa con su respectivo `CollisionShape3D`.
2. Añade un nodo `EncuentroCombate` como hijo del `Area3D`.
3. En el Inspector:
   - Marca `Auto Iniciar En Area = true`.
   - Marca `Auto Eliminar Padre En Victoria = true` (para que la emboscada no se repita).
   - Arrastra los enemigos a `enemigos`.
4. ¡Listo! Al caminar sobre el área se disparará la transición, el combate y el retorno al mundo.

---

## 4. Creación de Combatientes (`Battler`)

Cada participante en combate es una escena basada en [`scripts/combat/battler.gd`](../scripts/combat/battler.gd).

### Estructura de la escena:
```
Battler (Node3D, script: battler.gd)
├── Visual (AnimatedSprite3D, Sprite3D o MeshInstance3D)
└── Sombra (Decal o MeshInstance3D opcional)
```

### Propiedades clave en `battler.gd`:
- `nombre`: Nombre legible para la UI ("Jarrón Embrujado", "Jugador", etc.).
- `bando`: `ALIADO` o `ENEMIGO`.
- `controlado_por_jugador`: `true` para abrir el menú de comandos en su turno; `false` para ser controlado por IA.
- `copiar_sprite_del_jugador`: Si es `true`, adopta la textura del personaje activo en el supramundo.
- `stats`: Recurso `BattlerStats` con `max_hp`, `ataque`, `defensa` y `velocidad`.
- `acciones`: Array de recursos `BattlerAction` disponibles.

> [!NOTE]
> Para asegurar que los sprites 2.5D descansen exactamente sobre la plataforma ($Y = 0.0$) sin quedar enterrados, `Battler` calcula automáticamente la altura de la textura en `_ajustar_sprite_al_suelo()`.

---

## 5. Creación de Nuevas Acciones / Ataques (`BattlerAction`)

Las acciones de combate heredan de [`scripts/combat/battler_action.gd`](../scripts/combat/battler_action.gd) (`class_name BattlerAction extends Resource`).

### Ejemplo: Acción de Ataque con Timing (Paper Mario)
```gdscript
class_name AccionGolpe
extends BattlerAction

@export var danio_base: int = 3
@export var danio_perfecto: int = 5

func ejecutar(origen: Battler, objetivos: Array[Battler], arena: CombatArena) -> void:
    var objetivo: Battler = objetivos[0]
    
    # 1. Animación de aproximación
    await origen.animar_salto_hacia(objetivo.posicion_base + Vector3.LEFT * 1.0)
    
    # 2. Comando de acción interactivo (presionar interact / Z justo a tiempo)
    var exito: bool = await arena.comando.iniciar_timing(1.0, 0.25)
    
    # 3. Aplicar daño
    var danio: int = danio_perfecto if exito else danio_base
    if exito:
        arena.mostrar_texto(origen, "¡Genial!", Color.GOLD)
    
    objetivo.recibir_danio(danio)
    arena.sacudir_camara(0.2 if exito else 0.1)
    
    # 4. Retorno a posición base
    await origen.animar_regreso()
```

---

## 6. Controles y Mapa de Entrada

El combate respeta estrictamente las directivas de entrada del proyecto ([`AGENTS.md`](../AGENTS.md) y [`docs/INPUT_MAP.md`](INPUT_MAP.md)):

| Acción | Mapeo Teclado | Mapeo Gamepad | Uso en Combate |
|---|---|---|---|
| `ui_up` / `move_up` | Flecha Arriba / W | D-pad Arriba / Stick Izq Arriba | Subir en el menú de acciones / cambiar objetivo |
| `ui_down` / `move_down` | Flecha Abajo / S | D-pad Abajo / Stick Izq Abajo | Bajar en el menú de acciones / cambiar objetivo |
| `ui_left` / `move_left` | Flecha Izquierda / A | D-pad Izquierda / Stick Izq Izquierda | Seleccionar objetivo anterior |
| `ui_right` / `move_right` | Flecha Derecha / D | D-pad Derecha / Stick Izq Derecha | Seleccionar objetivo siguiente |
| `ui_accept` / `interact` | **Z**, **E**, Enter, Espacio | Botón Sur (A en Xbox / Cruz en PS) | Confirmar opción, confirmar objetivo, QTE / Timing |
| `ui_cancel` | Escape, Retroceso | Botón Este (B en Xbox / Círculo en PS) | Cancelar selección de objetivo |

> [!TIP]
> **Navegación Limpia con Joystick:**
> Los botones de combate usan `focus_mode = FOCUS_NONE` y el control por stick implementa filtrado desacoplado por eje vertical y horizontal con zona muerta y debounce (`280ms` retardo inicial / `180ms` repetición). Esto garantiza transiciones paso a paso exactas entre "Golpear" y "Huir" sin saltos dobles ni skipping indeseado.

---

## 7. Pruebas Autónomas (Standalone)

Para probar la arena de forma independiente sin necesidad de recorrer el supramundo:
1. Abre [`scenes/combat/CombatArena.tscn`](../scenes/combat/CombatArena.tscn) en el editor.
2. Presiona **F6** (Ejecutar Escena Actual).
3. Gracias a `auto_iniciar_si_esta_vacio = true`, la arena instanciará automáticamente un combate entre el jugador y el jarrón para pruebas rápidas de interfaz y mecánicas.

---

## 8. Guía Práctica: Cómo Modificar Assets sin Tocar Código

Todo el sistema está diseñado para que artistas y diseñadores puedan intercambiar o actualizar recursos directamente desde el editor visual de Godot:

### A. Cambiar el Sprite o Modelo de un Combatiente
1. Abre la escena del combatiente (ej. [`scenes/combat/battlers/PlayerBattler.tscn`](../scenes/combat/battlers/PlayerBattler.tscn) o [`PotBattler.tscn`](../scenes/combat/battlers/PotBattler.tscn)).
2. **Si es 2D/2.5D**:
   - Selecciona el nodo hijo `Visual` (`AnimatedSprite3D`).
   - En el Inspector, reemplaza el recurso `SpriteFrames` por el nuevo spritesheet con las animaciones.
   - En el nodo raíz `Battler`, desmarca `Copiar Sprite Del Jugador` (`false`).
   - Escribe los nombres exactos de las animaciones en el grupo **Animaciones** (`anim_reposo`, `anim_caminar`, `anim_ataque`, `anim_herido`, `anim_esquive`).
   - *Nota:* Si alguna animación no existe o se deja en blanco, el sistema activará automáticamente un efecto procedural de respaldo (squash & stretch, parpadeo o saltito) sin arrojar errores.
3. **Si es un Modelo 3D**:
   - Reemplaza el modelo hijo dentro de `Visual` por el nuevo archivo `.tscn`, `.glb` o `.dae`.
   - Ajusta `Altura` y `Radio` en el Inspector para centrar los cursores y marcadores.

### B. Cambiar el Fondo y Suelo de la Arena
- **Por combate individual (dinámico):**
  - En cualquier entidad con `EncuentroCombate`, arrastra la imagen de fondo deseada a `Textura Fondo` en el Inspector. La arena la cargará automáticamente al comenzar.
- **De forma global en la arena:**
  - Abre [`scenes/combat/CombatArena.tscn`](../scenes/combat/CombatArena.tscn).
  - Selecciona `Escenario/FondoSprite` y cambia su `Texture`.
  - Selecciona `Escenario/PlataformaSuelo` y edita su `Material -> Albedo Texture` para cambiar la hierba, piedra o nieve.

### C. Cambiar Música y Efectos de Sonido (SFX)
- **Música:** Arrastra cualquier archivo `.mp3`, `.ogg` o `.wav` a la propiedad `Musica Combate` (disponible tanto en `EncuentroCombate` como en `CombatArena`).
- **Sonidos de impacto y victoria:** En el Inspector de `CombatArena`, asigna nuevos audios a `Sonido Victoria`, `Sonido Derrota`, `Sonido Huida` o `Sonido Cursor`.
- **Sonidos de ataques y habilidades:** En los recursos de las acciones (ej. `Resource_player_golpe` o `Resource_pot_embestida`), cambia las propiedades `Sonido Golpe`, `Sonido Exito` o `Sonido Carga`.

### D. Sincronizar el Timing del Ataque con una Nueva Animación
Cuando un animador cree un nuevo sprite de golpe:
1. En el recurso `BattlerAction` (ej. `AccionGolpe`), ajusta la propiedad `Tiempo Impacto` (en segundos) para que coincida exactamente con el frame de impacto del nuevo sprite.
2. Ajusta `Ventana Antes` y `Ventana Despues` para aumentar o reducir la dificultad del comando de acción (QTE).
