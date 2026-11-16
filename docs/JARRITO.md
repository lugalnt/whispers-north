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

- `velocidad`, `aceleracion`, `velocidad_giro`: persecución directa con `move_and_slide`; incluye línea de vista configurable (`requiere_linea_de_vista`), pero no navegación alrededor de obstáculos.
- `radio_cuerpo`, `altura_cuerpo`, `radio_deteccion`, `altura_areas`: dimensiones iniciales aplicadas en `_ready`. Las formas de la escena muestran los valores predeterminados; los ajustes exportados se reflejan al ejecutar. Cada instancia recibe formas independientes.
- `distancia_perdida`: distancia plana desde Jarrito al protagonista para abandonar Alert/Walk. Mantenerla mayor que el radio de detección para evitar alternancias en el borde.
- Los candidatos deben pertenecer a `player`, estar visibles y procesando física. Si el mundo proporciona `get_active_player()`, se respeta su selección.
- La raíz usa capa física 3 (`collision_layer = 4`) y máscara 1; las áreas observan capa 1, donde está el jugador actual. Esto evita que los interactuables con máscara 1 detecten a Jarrito como jugador. Revisa las máscaras al integrarlo en otros mapas; no se modifica el Input Map ni la configuración global.
- Ajusta escala/orientación en `Visual/Modelo`, sin editar la jerarquía interna del GLB. La orientación de persecución usa `Visual` y asume frente -Z; un ajuste artístico puede hacerse en `Modelo`.
- El hijo `EncuentroCombate` se conecta al autoload `CoordinadorEncuentros`. `inicio_combate(protagonista)` notifica el inicio aceptado: no conectar otro ejecutor de arena a esta señal. Huida, cancelación, derrota o rechazo devuelven a Idle con `tiempo_recuperacion`; victoria conserva la instancia, pero sin nuevas detecciones. `combate_habilitado` permite desactivar las solicitudes. El battler actual es JarritoBattler, configurable en el hijo.
- Contratos, cancelación, protección compartida y pruebas: [COORDINACION_ENCUENTROS.md](COORDINACION_ENCUENTROS.md).

## Configuración de los mapas

World contiene un Jarrito y World_Town tres con `grupo_encuentro = trio_jarritos_pueblo`. Detección 9 m, abandono 18 m y velocidad 3.4. Sensor de encuentro: radio corporal 0.65 + tolerancia 0.02; altura 1.0. Alerta con `snd_mysterygo.wav` a -6 dB. Una única sesión agrupa el trío; huida/cancelación restaura sus miembros y victoria los desactiva en esa instancia de mapa. No se afirma persistencia de derrota tras recargar el mapa.

## Animación independiente del fuego

El AnimationPlayer importado se desactiva en la instancia y se consulta como fuente. No se modifican sus AnimationLibrary ni sus Animation.

Se crean copias de Animation en memoria y dos bibliotecas por instancia:

- `BodyAnimationPlayer`: Idle/Walk en bucle, Alert/Encounter sin bucle. Se eliminan de las copias todas las pistas de `CTRL_Jarro/Flame_Main` y descendientes.
- `FlameAnimationPlayer`: Flame en bucle. Solo conserva las pistas de esa rama; elimina las pistas estáticas que fijaban cuerpo y brazos.

Ambos reproductores resuelven sus rutas desde `Visual/Modelo`. No hay propiedades compartidas entre sus pistas, y cambiar el estado no reinicia Flame. Las copias conservan las claves originales; no se corrige el pequeño salto de escala presente en el bucle fuente de Flame.

Referencias de API: [AnimationPlayer](https://docs.godotengine.org/en/stable/classes/class_animationplayer.html), [Animation](https://docs.godotengine.org/en/stable/classes/class_animation.html).

No se modifica el GLB, su importación, materiales, texturas ni archivos de Blender. La animación procedural de Pot y el sistema Battler siguen independientes de los reproductores de Jarrito.
