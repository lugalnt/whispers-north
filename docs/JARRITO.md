# Jarrito en exploración — estado al 16 de noviembre de 2026

Escena reutilizable: `res://scenes/world/Entities/Jarrito.tscn`.
Controlador: `res://scripts/world/jarrito.gd`.

## Probar

Abre `res://scenes/world/Tests/JarritoTest.tscn` y ejecuta la escena (F6).
Se reutiliza `player_32.tscn` y su Input Map existente, incluido gamepad.

1. Al empezar, Jarrito está en Idle; el fuego debe moverse continuamente.
2. Acércate al enemigo: Alert se reproduce una vez, seguido de Walk con persecución física.
3. Al tocar al protagonista se solicita una reserva exclusiva e inicia la arena sin esperar Alert/Encounter. La cercanía dentro de DetectionArea solo activa detección/persecución.
4. Reinicia la escena para repetir. Para comprobar pérdida del objetivo, aléjate antes del encuentro más de `distancia_perdida`: regresa físicamente al origen (RETURN) y puede readquirir el objetivo.
5. Activa Depurar → Formas de colisión visibles para revisar volúmenes. Cambia los valores exportados en la raíz y vuelve a ejecutar.

## Configuración e integración

- `Detección y Persecución` (arriba del Inspector, con `@tool`):
  - `radio_deteccion`: slider de `0.5 m` a `20.0 m` (paso `0.25 m`, admite valores mayores) que actualiza **en tiempo real** el `DetectionArea` y dibuja en el visor 3D del editor un anillo **cian** de detección. Predeterminado: `4.5 m`.
  - `distancia_perdida`: slider de `1.0 m` a `35.0 m` (paso `0.5 m`) para abandonar Alert/Walk y volver al origen; dibuja en el editor el anillo exterior **naranja**. Predeterminado: `10.0 m` (siempre mantiene margen mínimo sobre `radio_deteccion`).
  - `mostrar_rango_editor`: activa/oculta los anillos guía 3D en el editor.
  - `velocidad`, `aceleracion`, `velocidad_giro`: persecución directa con `move_and_slide`; incluye línea de vista configurable (`requiere_linea_de_vista`), pero no navegación alrededor de obstáculos.
- `radio_cuerpo`, `altura_cuerpo`, `altura_areas`: dimensiones con actualización inmediata en editor (`resource_local_to_scene`) y formas únicas por instancia al ejecutar.
- Además, `JarritoTest.tscn` (F6) incluye un slider visual en pantalla para probar distintos radios de detección mientras juegas.
- Los candidatos deben pertenecer a `player`, estar visibles y procesando física. Si el mundo proporciona `get_active_player()`, se respeta su selección.
- La raíz usa capa física 3 (`collision_layer = 4`) y máscara 1; las áreas observan capa 1, donde está el jugador actual. Esto evita que los interactuables con máscara 1 detecten a Jarrito como jugador. Revisa las máscaras al integrarlo en otros mapas; no se modifica el Input Map ni la configuración global.
- Ajusta escala/orientación en `Visual/Modelo`, sin editar la jerarquía interna del GLB. La orientación de persecución usa `Visual` y asume frente -Z; un ajuste artístico puede hacerse en `Modelo`.
- El hijo `EncuentroCombate` se conecta al autoload `CoordinadorEncuentros`. `inicio_combate(protagonista)` notifica el inicio aceptado: no conectar otro ejecutor de arena a esta señal. Huida, cancelación, derrota o rechazo devuelven a Idle con `tiempo_recuperacion`; victoria conserva la instancia, pero sin nuevas detecciones. `combate_habilitado` permite desactivar las solicitudes. El battler actual es JarritoBattler, configurable en el hijo.
- Contratos, cancelación, protección compartida y pruebas: [COORDINACION_ENCUENTROS.md](COORDINACION_ENCUENTROS.md).

## Configuración de los mapas

World contiene un Jarrito (`4.5 m` detección / `10.0 m` abandono), World_Town tres con `grupo_encuentro = trio_jarritos_pueblo` (`4.5 m` / `10.0 m`) y World_ForestRuins seis (`4.0 - 4.5 m` / `9.0 - 10.0 m`), todos a velocidad `3.4`. Sensor de encuentro: radio corporal 0.65 + tolerancia 0.02; altura 1.0. Alerta con `snd_mysterygo.wav` a -6 dB. Una única sesión agrupa el trío; huida/cancelación restaura sus miembros y victoria los desactiva en esa instancia de mapa. No se afirma persistencia de derrota tras recargar el mapa.

## Animación independiente del fuego

El AnimationPlayer importado se desactiva en la instancia y se consulta como fuente. No se modifican sus AnimationLibrary ni sus Animation.

Se crean copias de Animation en memoria y dos bibliotecas por instancia:

- `BodyAnimationPlayer`: Idle/Walk en bucle, Alert/Encounter sin bucle. Se eliminan de las copias todas las pistas de `CTRL_Jarro/Flame_Main` y descendientes.
- `FlameAnimationPlayer`: Flame en bucle. Solo conserva las pistas de esa rama; elimina las pistas estáticas que fijaban cuerpo y brazos.

Ambos reproductores resuelven sus rutas desde `Visual/Modelo`. No hay propiedades compartidas entre sus pistas, y cambiar el estado no reinicia Flame. Las copias conservan las claves originales; no se corrige el pequeño salto de escala presente en el bucle fuente de Flame.

Referencias de API: [AnimationPlayer](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html), [Animation](https://docs.godotengine.org/en/stable/classes/class_animation.html).

No se modifica el GLB, su importación, materiales, texturas ni archivos de Blender. La animación procedural de Pot y el sistema Battler siguen independientes de los reproductores de Jarrito.
