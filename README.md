Nombre: Whispers of the North
Género: Aventura, Misterio, Exploración, Fantasía, RPG
Plataforma: PC.
Perspectiva: 2D / 2.5D
Historia: En un mundo moderno un joven se muda con su familia a un pueblo misterioso de
los países nórdicos donde los habitantes conviven con criaturas nunca antes vistas donde
siguen reglas y tradiciones muy extrañas.
Objetivo: Descubrir el origen de las criaturas y las tradiciones del pueblo.
Mecánica principal: Combate por turnos, Investigación, Puzzles, Bestiario, Elementos
¿Qué lo hace diferente?
Mientras que muchos juegos basados en la cultura y mitología nórdica tratan de vikingos,
dioses y guerras, este busca un enfoque más doméstico y de fantasía, como si fuera cuento de
hadas.


## 🏗️ Arquitectura del Proyecto — Árbol de Nodos (Godot)
(IASIADA INVESTIGADA CAMBIAR A COMO QUEDE MEJOR SI HAY PROBLEMA)

La estructura está diseñada para trabajo **asíncrono por módulos**: cada integrante puede trabajar en una rama separada sin conflictos.

```
whispers-north/
│
├── 📁 scenes/               ← Escenas .tscn (trabajo paralelo por área)
│   ├── world/               ← Mapas, zonas del pueblo, naturaleza
│   │   ├── VillageHub.tscn      [Mapa central / hub principal]
│   │   ├── ForestZone.tscn
│   │   └── ...
│   ├── ui/                  ← Interfaces de usuario
│   │   ├── MainMenu.tscn
│   │   ├── HUD.tscn             [Health, stamina, elementos activos]
│   │   ├── PauseMenu.tscn
│   │   ├── BestiaryUI.tscn
│   │   ├── InventoryUI.tscn
│   │   └── DialogueBox.tscn
│   ├── combat/              ← Sistema de combate por turnos
│   │   ├── CombatScene.tscn     [Escena raíz del combate]
│   │   ├── TurnManager.tscn     [Nodo gestor de turnos]
│   │   └── BattleUI.tscn
│   └── cutscenes/           ← Cinemáticas / secuencias narrativas
│
├── 📁 scripts/              ← Código GDScript (uno por responsable)
│   ├── core/                ← Sistemas globales (Autoloads)
│   │   ├── GameManager.gd       [Autoload: estado global del juego]
│   │   ├── EventBus.gd          [Autoload: señales globales desacopladas]
│   │   ├── SaveSystem.gd        [Autoload: guardado/carga]
│   │   └── AudioManager.gd      [Autoload: música y SFX]
│   ├── player/
│   │   ├── Player.gd            [Movimiento, interacción, stats]
│   │   └── PlayerInventory.gd
│   ├── enemies/
│   │   ├── BaseEnemy.gd         [Clase base heredable]
│   │   └── CreatureAI.gd
│   ├── combat/
│   │   ├── TurnManager.gd       [Lógica de turnos]
│   │   ├── ElementSystem.gd     [Afinidades elementales]
│   │   └── CombatCalculator.gd
│   ├── dialogue/
│   │   ├── DialogueManager.gd   [Carga y muestra diálogos desde JSON]
│   │   └── DialogueBox.gd
│   ├── puzzles/
│   │   ├── BasePuzzle.gd
│   │   └── PuzzleManager.gd
│   ├── bestiary/
│   │   ├── Bestiary.gd          [Registro y desbloqueo de criaturas]
│   │   └── BestiaryEntry.gd
│   └── inventory/
│       ├── Inventory.gd
│       └── Item.gd
│
├── 📁 assets/               ← Recursos binarios (versionados con LFS)
│   ├── sprites/
│   │   ├── player/
│   │   ├── enemies/
│   │   ├── environment/
│   │   └── ui/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   └── shaders/             ← Shaders GLSL personalizados
│
├── 📁 data/                 ← Datos en JSON/TRES (sin binarios)
│   ├── dialogues/           ← Guiones de diálogo en JSON
│   ├── bestiary/            ← Fichas de criaturas en JSON
│   ├── items/               ← Definiciones de ítems
│   └── quests/              ← Datos de misiones
│
├── 📁 docs/                 ← Documentación interna del equipo
│
├── project.godot            ← Config principal de Godot
├── .gitignore
├── .gitattributes           ← Reglas de Git LFS
└── README.md
```

### 🔌 Nodos Autoload (Singletons globales)

Registrar en **Proyecto → Configuración del Proyecto → Autoload**:

| Nombre | Script | Descripción |
|---|---|---|
| `GameManager` | `scripts/core/GameManager.gd` | Estado global, progreso |
| `EventBus` | `scripts/core/EventBus.gd` | Señales desacopladas entre nodos |
| `SaveSystem` | `scripts/core/SaveSystem.gd` | Guardar y cargar partidas |
| `AudioManager` | `scripts/core/AudioManager.gd` | Control de música y SFX |

### 🌿 Ramas de Git sugeridas por módulo

```
main           ← Código estable / integración
dev            ← Rama de integración del equipo
├── feat/combat        (Combate por turnos + Elementos)
├── feat/dialogue      (Sistema de diálogo + Bestiario)
├── feat/world         (Mapas + Exploración)
├── feat/ui            (HUD + Menús + Inventario)
└── feat/puzzles       (Puzzles + Mecánicas de investigación)
```

---

## ⚙️ Configuración Inicial del Repositorio

### 1. Clonar el repositorio

```bash
git clone https://github.com/lugalnt/whispers-north.git
cd whispers-north
```

### 2. Instalar Git LFS

Git LFS permite versionar archivos binarios pesados (sprites, audio, modelos) sin inflar el historial de git.

#### Windows
```bash
# Opción A — Winget
winget install GitHub.GitLFS

# Opción B — Descarga directa
# https://git-lfs.com/
```

#### macOS
```bash
brew install git-lfs
```

#### Linux (Debian/Ubuntu)
```bash
sudo apt install git-lfs
```

#### Activar LFS en el repositorio (solo una vez por máquina)
```bash
git lfs install
```

### 3. Verificar que LFS está trackeando los archivos

Tras clonar, ejecuta:
```bash
git lfs ls-files
```
Deberías ver los archivos de assets listados. Si no hay ninguno todavía, es normal — LFS se activa cuando subes el primer archivo binario.

### 4. Tipos de archivo trackeados por LFS

Ya están configurados en `.gitattributes`. Los tipos incluidos son:

```bash
# Imágenes
*.png  *.jpg  *.jpeg  *.psd  *.aseprite

# Audio
*.wav  *.ogg  *.mp3

# Modelos 3D
*.blend  *.fbx  *.glb  *.gltf

# Tipografías
*.ttf  *.otf

# Video
*.mp4  *.webm
```

Para añadir nuevos tipos en el futuro:
```bash
git lfs track "*.extension"
git add .gitattributes
git commit -m "chore: track *.extension with LFS"
```

### 5. Abrir el proyecto en Godot

1. Descarga **Godot 4.x** desde [godotengine.org](https://godotengine.org/download)
2. Abre el Project Manager
3. Haz clic en **"Importar"** y selecciona `project.godot` en la carpeta del repositorio

### 6. Flujo de trabajo en equipo

```bash
# Antes de empezar a trabajar
git checkout dev
git pull origin dev
git checkout -b feat/tu-modulo

# Al terminar tu trabajo
git add .
git commit -m "feat: descripción de lo que hiciste"
git push origin feat/tu-modulo
# → Abre un Pull Request hacia 'dev'
```

---

## 🐛 Convención de commits

```
feat:     nueva funcionalidad
fix:      corrección de bug
art:      assets de arte (sprites, audio, etc.)
docs:     documentación
chore:    configuración, limpieza
refactor: refactorización sin cambiar funcionalidad
```

**Ejemplo:**
```bash
git commit -m "feat(combat): añadir sistema de turnos básico"
git commit -m "art(sprites): agregar spritesheet del jugador idle"
```

---

## 📌 Recursos útiles

- [Documentación oficial de Godot 4](https://docs.godotengine.org/en/stable/)
- [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [Git LFS Documentation](https://git-lfs.com/)
- [Godot — Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html)
