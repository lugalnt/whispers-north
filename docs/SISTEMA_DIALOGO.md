# Sistema de Diálogo Dinámico (Dialogue Manager + InteraccionDialogo)

Sistema modular y optimizado para la interacción conversacional en *Whispers of the North*, integrado con el addon **Dialogue Manager** de Nathan Hoad y estilizado con la estética nórdica del juego.

---

## 1. Arquitectura General

```
     ┌────────────────────────┐         ┌─────────────────────────┐
     │      GameState         │         │     DialogueManager     │
     │  (Salud, Rata, Items)  │         │   (Autoload / Parser)   │
     └───────────┬────────────┘         └────────────┬────────────┘
                 │                                   │
                 ▼                                   ▼
      ┌─────────────────────────────────────────────────────────┐
      │          InteraccionDialogo (Area3D)                    │
      │  (scripts/dialogue/interaccion_dialogo.gd)              │
      │                                                         │
      │  - Detección 3D / Proximidad del jugador                │
      │  - Prompt flotante ("[E] Hablar") con bobbing suave     │
      │  - Bloqueo/desbloqueo automático de Eric                │
      │  - Orientación cinemática bidireccional                 │
      │  - Doble modalidad: .dialogue O líneas rápidas          │
      └───────────────────────────┬─────────────────────────────┘
                                  │
                                  ▼
                   ┌──────────────────────────────┐
                   │    NordicDialogueBalloon     │
                   │ (scenes/dialogue/            │
                   │   NordicDialogueBalloon.tscn)│
                   │                              │
                   │ - Cuadro nórdico traslúcido  │
                   │ - Nombre dorado y retrato    │
                   │ - Efecto máquina de escribir │
                   │ - Respuestas interactivas    │
                   └──────────────────────────────┘
```

---

## 2. Componentes

### 2.1 `InteraccionDialogo` (`scripts/dialogue/interaccion_dialogo.gd`)
Nodo `Area3D` reutilizable diseñado para soltarse como hijo de cualquier entidad (NPCs, carteles, estatuas, puertas, etc.) o como disparador de zona en el mundo:
- **Estado y Activación**:
  - `activo`: Permite habilitar o deshabilitar la interacción al instante.
  - `auto_iniciar_al_entrar`: Dispara el diálogo tan pronto como el jugador cruza el área (ideal para eventos narrativos o zonas de aviso).
  - `deshabilitar_tras_interactuar`: Se desactiva automáticamente tras la primera conversación.
  - `maximo_interacciones`: Límite de charlas (-1 para infinito).
- **Doble Modalidad de Diálogo**:
  - **Modalidad A (Archivos `.dialogue`)**: Asignar un recurso compilado en `recurso_dialogo` y especificar `titulo_o_cue` (ej: `"start"`, `"tienda"`). Permite ramificaciones complejas, opciones de respuesta y chequeo de variables.
  - **Modalidad B (Inspector Rápido)**: Para carteles o charlas simples de 1 o 2 líneas, basta con escribir en `lineas_rapidas` y opcionalmente `nombre_hablante`. El sistema compila y genera el recurso al vuelo automáticamente sin crear archivos adicionales.
- **Cinemática e Inmersión**:
  - `bloquear_jugador`: Pausa a Eric (`player.is_interacting = true`), detiene su inercia y previene que se abra el menú de pausa durante la conversación.
  - `orientar_jugador_al_hablar`: Eric se gira automáticamente hacia el objeto o NPC que le habla.
  - `orientar_npc_al_jugador`: El NPC (modelo 3D o sprite 2.5D con billboard) se gira para mirar a Eric mientras conversan y recupera su pose original al despedirse.
- **Indicador Flotante (Prompt 3D)**:
  - Crea automáticamente una etiqueta 3D con suave balanceo senoidal (`[E] Hablar`, `[E] Examinar`, etc.) y fundido suave al entrar o salir del radio de detección.
  - Solo el interactuable más cercano al jugador responde al input, previniendo disparos dobles accidentales.
- **Integración Global**:
  - Proporciona `GameState`, `self` y la entidad padre (`get_parent()`) dentro del contexto de ejecución del diálogo, permitiendo consultar banderas (`if GameState.tiene_rata:`), curar vida (`do GameState.curar_hp(5)`), otorgar ítems o iniciar combates directamente desde el diálogo.

### 2.2 `NordicDialogueBalloon` (`scenes/dialogue/NordicDialogueBalloon.tscn`)
Globo de diálogo personalizado para *Whispers of the North*:
- Cuadro oscuro semitransparente con borde azul hielo y esquinas redondeadas (idéntico al menú de pausa).
- Nombre del hablante destacado en oro nórdico (`#ffd700`).
- Soporte dinámico de retrato (`retrato_hablante` o etiquetas `#portrait=res://...`): se oculta y auto-expande el texto si el personaje no tiene imagen.
- Efecto máquina de escribir (*typewriter*) con sonido sutil de tecleo configurable (`sfx_tecleo_defecto` o sonido de voz del hablante).
- Avanza con la tecla **`E`**, **`Enter`**, **`Espacio`** o botón **`A`** del mando (`interact` y `ui_accept`), y salta el tecleo con `ui_cancel` o clic repetido.
- Menú de opciones de respuesta integrado con foco automático para mando y teclado.

### 2.3 `PlaceholderNPC` (`scripts/world/placeholder_npc.gd` / `scenes/world/Entities/placeholder_npc.tscn`)
Controlador de comportamiento visual y presencia para personajes 2.5D en el mundo:
- **Seguimiento con la Mirada (`mirar_al_jugador`)**: Cuando el jugador entra dentro de su `radio_vision` (por defecto 4.5m), el NPC detecta el ángulo hacia Eric relativo a la cámara activa y selecciona el primer frame (`frame = 0`) de su animación de interacción correspondiente (`interact_down`, `interact_down_side`, `interact_side`, `interact_up_side`, `interact_up`), simulando que está observando atentamente a Eric mientras se desplaza a su alrededor.
- **Pose de Reposo**: Cuando el jugador sale del radio, el NPC regresa suavemente a la pose y dirección de reposo original configurada en el editor.
- **Aislamiento Total de Interacción**: Los NPCs pertenecen al grupo `"npc"`, asegurando que `InteraccionDialogo` jamás los confunda con el jugador, erradicando por completo el cruce de líneas entre personajes cercanos.


---

## 3. Guía Paso a Paso para Crear NPCs u Objetos con Diálogo

### Opción A: Añadir Diálogo Rápido a un Objeto o NPC (en 30 segundos)
1. Abre la escena de tu NPC u objeto (ej. un jarrón, casa, cartel o personaje).
2. Haz clic derecho en el nodo raíz → **Instanciar Escena Hijo** (`Ctrl+Shift+A`).
3. Selecciona `res://scenes/dialogue/InteraccionDialogo.tscn`.
4. En el panel **Inspector**:
   - `Nombre Hablante`: Ej. `"Cartel de la Aldea"` o `"Anciana Freya"`.
   - `Líneas Rápidas`: Añade una o varias líneas (ej: `"Hacia el norte: Montaña de Fuego."`, `"Ten cuidado con los caminos nevados."`).
   - `Texto Indicador`: `"[E] Leer"` o `"[E] Hablar"`.
5. ¡Listo! Al acercarte con Eric y pulsar `E` o el botón `A` del mando, hablará inmediatamente.

### Opción B: Crear un Diálogo Ramificado con Opciones y Recompensas (`.dialogue`)
1. En la carpeta `res://data/dialogues/`, crea un archivo de texto con extensión `.dialogue` (ej. `mision_bosque.dialogue`).
2. Escribe la conversación usando la sintaxis de Dialogue Manager:
   ```dialogue
   ~ start
   Freya: ¡Saludos, Eric! Hacía tiempo que no te veía por aquí.
   - ¿Qué novedades hay en el pueblo?
       Freya: Las noches son cada vez más frías...
       - Tomaré precauciones.
           Freya: Cuídate mucho.
   - ¿Tienes algo para comer?
       if GameState.hp_actual < 10:
           Freya: ¡Estás herido! Toma un trozo de queso.
           do GameState.inventario.agregar(ItemDatabase.obtener_item("queso_nordico"))
       else:
           Freya: Te veo lleno de energía hoy.
   - Nos vemos luego.
       Freya: Adiós, joven explorador.
   => END
   ```
3. En el nodo `InteraccionDialogo`, arrastra tu archivo `.dialogue` al campo **Recurso Diálogo** y deja **Título O Cue** en `"start"`.

---

## 4. Métodos y Funciones Útiles para Scripts

```gdscript
# Iniciar el diálogo manualmente por código (cinemática o evento)
interaccion.iniciar_dialogo(jugador)

# Desactivar temporal o permanentemente el diálogo
interaccion.desactivar()

# Reactivar
interaccion.activar()

# Cambiar la rama de diálogo tras completar una misión
interaccion.cambiar_cue("mision_cumplida")

# Cambiar las líneas rápidas dinámicamente
interaccion.cambiar_lineas_rapidas(["Ahora que derrotaste al jefe, la aldea está a salvo."], "Aldeano Agradecido")
```

---

## 5. Diálogos en Objetos Interactuables (Cofres, Puertas, etc.)

Cuando colocas un `InteraccionDialogo` como hijo de un cofre u objeto con su propia lógica de apertura/interacción:

- **Grupo en el Inspector (`Objeto Interactuable`)**:
  - `es_objeto_interactuable`: Activa el soporte (si es `false`, auto-detecta si el padre es un cofre o tiene `abrir()` / `interactuar()`).
  - `activar_objeto_al_terminar` (por defecto `true`): Al terminar de leer el diálogo, llama automáticamente a `padre.abrir(jugador)` o `padre.interactuar(jugador)`. El cofre se abrirá fluidamente justo al cerrar el globo de texto.
  - `ignorar_si_padre_abierto` (por defecto `true`): Si el cofre ya fue abierto (`esta_abierto == true`), el diálogo no se repite ni consume el input, permitiendo que la interacción del cofre (como hacer explotar la rata en Fase 2) funcione sin interferencias.
  - `pasar_input_al_padre` (por defecto `false`): Si se activa, no consume el input con `set_input_as_handled()`, permitiendo que el padre reciba el evento inmediatamente.
  - `desactivar_tras_abrir_objeto` (por defecto `true`): Desactiva este componente de diálogo una vez que el objeto padre se ha abierto.
  - `metodo_personalizado_padre`: Permite definir un método específico a invocar si el objeto no usa `abrir` o `interactuar`.

---

## 6. Eventos y Recompensas al Terminar Diálogos (NPCs de Prueba)

El componente [PlaceholderNPC](file:///c:/Users/luisa/OneDrive/Desktop/whispers of the north/scripts/world/placeholder_npc.gd) se conecta a la señal `dialogo_terminado` de `InteraccionDialogo` y permite disparar eventos especiales configurables desde el Inspector:

### 💥 NPC Explosivo (`Npc_Exp`)
- **Configuración**: `explotar_al_terminar_dialogo = true`.
- **Efecto visual**: Genera un [AnimatedSprite3D](file:///c:/Users/luisa/OneDrive/Desktop/whispers of the north/scripts/world/placeholder_npc.gd) en billboard con el spritesheet temático [realistic_explosion.png](file:///c:/Users/luisa/OneDrive/Desktop/whispers of the north/assets/sprites/vfx/realistic_explosion.png) (17 fotogramas completos de 71x100 a 18 FPS con fondo 100% transparente sin bordes azules).
- **Audio**: Reproduce el efecto de sonido `snd_badexplosion.wav` de Deltarune en el bus `SFX`.
- **Desvanecimiento**: Oculta el sprite original del NPC, desactiva sus colisiones y destruye la entidad con `queue_free()` al finalizar la animación de explosión.

### ⚔️ NPC Útil / Recompensa de Stats (`Npc_Util`)
- **Configuración**: `aumentar_ataque_al_terminar = true`, `aumento_ataque = 1`, `mostrar_mensaje_recompensa = true`, `mensaje_recompensa = "Te sientes un poquito más fuerte"`.
- **Efecto**: Aumenta en `+1` la estadística permanente de ataque en [GameState](file:///c:/Users/luisa/OneDrive/Desktop/whispers of the north/scripts/core/game_state.gd) (`GameState.aumentar_ataque()`), notificando a todas las interfaces conectadas.
- **Notificación en Pantalla**: Muestra un elegante banner con borde dorado y estilo nórdico que indica `"Te sientes un poquito más fuerte"` junto al detalle `"+1 Ataque"`, con animación de entrada y salida suave durante los ~2.5 segundos que suena la fanfarria.
- **Texto Flotante 3D**: Despliega un [Label3D](file:///c:/Users/luisa/OneDrive/Desktop/whispers of the north/scripts/world/placeholder_npc.gd) flotante con `"+1 ATQ"` sobre el jugador en el mundo que sube y se desvanece suavemente.
- **Audio**: Reproduce la fanfarria de recompensa `snd_moss_fanfare.wav`.
- **Límite de usos**: Configurado con `maximo_interacciones = 5` en [InteraccionDialogo](file:///c:/Users/luisa/OneDrive/Desktop/whispers of the north/scripts/dialogue/interaccion_dialogo.gd), permitiendo obtener hasta `+5` de ataque total.

### ⏸️ Menú de Pausa Global para el Jugador
- El control de pausa (`P`, `Escape` o Gamepad `Start`) ahora está integrado directamente en [player.gd](file:///c:/Users/luisa/OneDrive/Desktop/whispers of the north/scripts/player/player.gd) vía `_asegurar_menu_pausa()`.
- Ya no depende de que la escena raíz sea específicamente `World.tscn`. Funciona automáticamente en `World_Town.tscn` y cualquier nueva escena o mazmorra.
- Al abrir la pestaña de **Estadísticas**, el nuevo ataque otorgado por `Npc_Util` se refleja en tiempo real.


