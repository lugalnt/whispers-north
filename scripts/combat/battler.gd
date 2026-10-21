class_name Battler
extends Node3D

## Combatiente dentro de la arena (jugador, aliado o enemigo).
##
## Basado en `Battler` de godot-open-rpg: guarda stats, acciones y estado de vida, y expone
## una API de animación sencilla que usan las acciones (`reproducir`, `quedarse_quieto`,
## `animar_herido`, `animar_derrota`, `destello`...).
##
## Estructura esperada de la escena:
##   Battler (Node3D, este script)
##   └── Visual (Node3D | AnimatedSprite3D | Sprite3D | modelo 3D)
##
## ASSETS PLACEHOLDER: por ahora el jugador reutiliza los SpriteFrames del personaje del mundo
## (walk_* / interact_*) y el jarrón usa su modelo 3D con animación procedural (squash, saltos).
## Para poner los assets definitivos:
##   - Sprites: sustituye el nodo `Visual` por un AnimatedSprite3D con SpriteFrames propios de
##     combate y rellena los nombres en el grupo "Animaciones" del Inspector.
##   - Si una animación está vacía o no existe, se usa un efecto procedural de respaldo.

signal hp_cambiado(hp: int, max_hp: int)
signal derrotado

enum Bando { ALIADO, ENEMIGO }

@export var nombre: String = "Battler"
@export var stats: BattlerStats
## Acciones disponibles en su turno. El jugador las ve en el menú; la IA elige una.
@export var acciones: Array[BattlerAction] = []
## true = el jugador elige sus acciones con el menú. false = IA.
@export var controlado_por_jugador: bool = false
## PLACEHOLDER: copia los SpriteFrames del personaje activo del mundo (16x16 o 32x32).
## Desactívalo cuando el battler tenga sus propios SpriteFrames de combate.
@export var copiar_sprite_del_jugador: bool = false
## Radio "físico" en el plano X: se usa para saber dónde pararse al atacar cuerpo a cuerpo
@export var radio: float = 0.6
## Altura aproximada (cursor de objetivo, números de daño). Si el Visual es un sprite se
## calcula sola a partir del tamaño del frame.
@export var altura: float = 1.4
## Hacia dónde mira el sprite sin voltear (las animaciones "side" del jugador miran a la derecha)
@export var sprite_mira_a_la_derecha: bool = true

@export_group("Animaciones (placeholder)")
## Nombres de animación dentro del AnimatedSprite3D del Visual. Vacío = efecto procedural.
## Reposo: si `reposo_estatico` está activo se muestra solo su primer frame (el jugador aún no
## tiene animación idle, así que se usa el primer frame de caminar).
@export var anim_reposo: StringName = &""
@export var reposo_estatico: bool = true
@export var anim_caminar: StringName = &""
@export var anim_ataque: StringName = &""
@export var anim_herido: StringName = &""
@export var anim_esquive: StringName = &""

@export_group("Efectos")
## Amplitud del "respirar" procedural en reposo (0 = desactivado)
@export var respiracion: float = 0.03
@export var color_particulas_derrota: Color = Color(0.9, 0.95, 1.0)
@export var sonido_herido: AudioStream
@export var sonido_derrota: AudioStream

@onready var visual: Node3D = $Visual

var bando: Bando = Bando.ALIADO
var hp: int = 1
## Posición a la que vuelve tras cada acción (la pone la arena al colocarlo)
var posicion_base: Vector3

var _escala_visual: Vector3 = Vector3.ONE
var _pos_visual: Vector3 = Vector3.ZERO
var _tiempo: float = 0.0
var _respirando: bool = true

func inicializar_stats() -> void:
	if stats == null:
		stats = BattlerStats.new()
	hp = stats.max_hp

func _ready() -> void:
	if visual == null:
		visual = get_node_or_null("Visual")
	inicializar_stats()
	if visual:
		_escala_visual = visual.scale
		_pos_visual = visual.position
	_tiempo = randf() * TAU
	if copiar_sprite_del_jugador and (visual is AnimatedSprite3D) and (visual as AnimatedSprite3D).sprite_frames == null:
		var p_scene = load("res://scenes/player/player.tscn")
		if p_scene:
			var dummy = p_scene.instantiate()
			copiar_sprite_de(dummy)
			dummy.queue_free()
	_ajustar_sprite_al_suelo()
	quedarse_quieto()

func _process(delta: float) -> void:
	_tiempo += delta
	if _respirando and respiracion > 0.0 and esta_vivo():
		var s: float = sin(_tiempo * 3.0) * respiracion
		visual.scale = _escala_visual * Vector3(1.0 + s, 1.0 - s, 1.0 + s)

# ---------------------------------------------------------------------------
# Vida
# ---------------------------------------------------------------------------

func esta_vivo() -> bool:
	return hp > 0

## Aplica daño y devuelve el daño real aplicado
func recibir_danio(cantidad: int) -> int:
	var aplicado: int = mini(maxi(cantidad, 0), hp)
	hp -= aplicado
	hp_cambiado.emit(hp, stats.max_hp)
	if hp <= 0:
		derrotado.emit()
	return aplicado

func curar(cantidad: int) -> int:
	var anterior: int = hp
	hp = mini(hp + maxi(cantidad, 0), stats.max_hp)
	hp_cambiado.emit(hp, stats.max_hp)
	return hp - anterior

# ---------------------------------------------------------------------------
# Posicionamiento
# ---------------------------------------------------------------------------

## Punto donde debe pararse `atacante` para golpear cuerpo a cuerpo a este battler
func posicion_frente(atacante: Battler) -> Vector3:
	var lado: float = signf(atacante.posicion_base.x - posicion_base.x)
	if lado == 0.0:
		lado = -1.0
	return global_position + Vector3(lado * (radio + atacante.radio), 0.0, 0.0)

func punto_cabeza() -> Vector3:
	var pos: Vector3 = global_position if is_inside_tree() else position
	return pos + Vector3.UP * altura

## Voltea el sprite para mirar hacia una posición X del mundo
func mirar_hacia(x_objetivo: float) -> void:
	var sprite: SpriteBase3D = visual as SpriteBase3D
	if sprite == null:
		return
	var mi_x: float = global_position.x if is_inside_tree() else position.x
	var hacia_derecha: bool = x_objetivo >= mi_x
	sprite.flip_h = hacia_derecha != sprite_mira_a_la_derecha

## Vuelve a mirar hacia el bando contrario (aliados → derecha, enemigos → izquierda)
func mirar_al_frente() -> void:
	var mi_x: float = global_position.x if is_inside_tree() else position.x
	mirar_hacia(mi_x + (1.0 if bando == Bando.ALIADO else -1.0))

# ---------------------------------------------------------------------------
# Animación (API usada por las acciones)
# ---------------------------------------------------------------------------

## Reproduce una animación del AnimatedSprite3D si existe. Devuelve true si se reprodujo.
func reproducir(anim: StringName) -> bool:
	_respirando = false
	visual.scale = _escala_visual
	var sprite: AnimatedSprite3D = visual as AnimatedSprite3D
	if sprite == null or anim == &"" or sprite.sprite_frames == null:
		return false
	if not sprite.sprite_frames.has_animation(anim):
		return false
	sprite.play(anim)
	return true

## Espera a que termine la animación actual (solo si no es en bucle)
func esperar_animacion() -> void:
	var sprite: AnimatedSprite3D = visual as AnimatedSprite3D
	if sprite == null or not sprite.is_playing() or sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.get_animation_loop(sprite.animation):
		return
	await sprite.animation_finished

## Pose de reposo (y reactiva la respiración procedural)
func quedarse_quieto() -> void:
	var sprite: AnimatedSprite3D = visual as AnimatedSprite3D
	if sprite != null and anim_reposo != &"" and sprite.sprite_frames != null \
			and sprite.sprite_frames.has_animation(anim_reposo):
		sprite.play(anim_reposo)
		if reposo_estatico:
			sprite.stop()
	visual.scale = _escala_visual
	visual.position = _pos_visual
	_respirando = true

## Mueve al battler hasta `destino` (tween). Usa anim_caminar si existe.
func caminar_hasta(destino: Vector3, duracion: float) -> void:
	mirar_hacia(destino.x)
	var hay_anim: bool = reproducir(anim_caminar)
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", destino, duracion).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if not hay_anim:
		# Respaldo procedural: saltitos mientras avanza (como el jarrón en el mundo)
		var saltos: int = maxi(1, int(duracion / 0.18))
		var t_salto: float = duracion / float(saltos)
		var tween_saltos: Tween = create_tween()
		for i in range(saltos):
			tween_saltos.tween_property(visual, "position:y", _pos_visual.y + 0.18, t_salto * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween_saltos.tween_property(visual, "position:y", _pos_visual.y, t_salto * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	visual.position = _pos_visual

## Vuelve a la posición base y se queda en reposo mirando al frente
func volver_a_base(duracion: float = 0.4) -> void:
	await caminar_hasta(posicion_base, duracion)
	mirar_al_frente()
	quedarse_quieto()

## Aplastar/estirar el Visual (anticipación, impacto, aterrizaje...)
func aplastar(factor: Vector3, duracion: float) -> void:
	_respirando = false
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", _escala_visual * factor, duracion * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", _escala_visual, duracion * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished

## Destello de color (sprites: modulate; modelos 3D: material_overlay temporal)
func destello(color: Color, duracion: float = 0.18) -> void:
	var tween: Tween = create_tween().set_parallel(true)
	for sprite in _sprites():
		sprite.modulate = color
		tween.tween_property(sprite, "modulate", Color.WHITE, duracion)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color, 0.75)
	var geometrias: Array[GeometryInstance3D] = _geometrias()
	for geo in geometrias:
		geo.material_overlay = material
	if not geometrias.is_empty():
		tween.tween_property(material, "albedo_color:a", 0.0, duracion)
	await tween.finished
	for geo in geometrias:
		if is_instance_valid(geo) and geo.material_overlay == material:
			geo.material_overlay = null

## Escala original del Visual (para que las acciones animen squash/stretch relativo)
func escala_base() -> Vector3:
	return _escala_visual

## Esquive: usa anim_esquive si existe y además da un salto procedural
## TODO: con assets definitivos puede bastar con la animación (desactivar el salto).
func animar_esquive() -> void:
	reproducir(anim_esquive)
	var tween: Tween = create_tween()
	tween.tween_property(visual, "position:y", _pos_visual.y + 1.3, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "position:y", _pos_visual.y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	await aplastar(Vector3(1.2, 0.8, 1.2), 0.12)
	if esta_vivo():
		quedarse_quieto()

## Reacción al recibir un golpe. Usa anim_herido si existe; si no, temblor + destello rojo.
func animar_herido() -> void:
	_reproducir_sonido(sonido_herido)
	var hay_anim: bool = reproducir(anim_herido)
	destello(Color(1.0, 0.35, 0.35))
	var tween: Tween = create_tween()
	for i in range(4):
		var lado: float = 0.12 if i % 2 == 0 else -0.12
		tween.tween_property(visual, "position:x", _pos_visual.x + lado, 0.04)
	tween.tween_property(visual, "position:x", _pos_visual.x, 0.04)
	await tween.finished
	if hay_anim:
		await esperar_animacion()
	if esta_vivo():
		quedarse_quieto()

## Muerte del battler: destello blanco, se hincha, estalla en partículas y desaparece.
## TODO: sustituir por animación/efecto definitivo por tipo de criatura.
func animar_derrota() -> void:
	_respirando = false
	await destello(Color(3.0, 3.0, 3.0), 0.12)
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", _escala_visual * 1.4, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	_reproducir_sonido(sonido_derrota)
	_explosion_particulas(punto_cabeza() - Vector3.UP * altura * 0.4)
	visual.hide()

# ---------------------------------------------------------------------------
# Visual
# ---------------------------------------------------------------------------

## PLACEHOLDER: usa los SpriteFrames del personaje del mundo para el battler del jugador
func copiar_sprite_de(jugador_campo: Node) -> void:
	if jugador_campo == null:
		return
	var origen: AnimatedSprite3D = jugador_campo.get_node_or_null("Sprite2_5D") as AnimatedSprite3D
	var destino: AnimatedSprite3D = visual as AnimatedSprite3D
	if origen == null or destino == null:
		return
	destino.sprite_frames = origen.sprite_frames
	destino.pixel_size = origen.pixel_size
	_ajustar_sprite_al_suelo()
	quedarse_quieto()

## Coloca el sprite para que sus pies toquen el suelo (y=0) y calcula la altura
func _ajustar_sprite_al_suelo() -> void:
	var sprite: AnimatedSprite3D = visual as AnimatedSprite3D
	if sprite == null or sprite.sprite_frames == null:
		return
	var anim: StringName = anim_reposo if sprite.sprite_frames.has_animation(anim_reposo) else sprite.animation
	if not sprite.sprite_frames.has_animation(anim) or sprite.sprite_frames.get_frame_count(anim) == 0:
		return
	var textura: Texture2D = sprite.sprite_frames.get_frame_texture(anim, 0)
	if textura == null:
		return
	var alto: float = textura.get_height() * sprite.pixel_size
	sprite.centered = true
	_pos_visual = Vector3(_pos_visual.x, alto * 0.5, _pos_visual.z)
	visual.position = _pos_visual
	altura = alto

func _sprites() -> Array[SpriteBase3D]:
	var lista: Array[SpriteBase3D] = []
	if visual is SpriteBase3D:
		lista.append(visual)
	for hijo in visual.find_children("*", "SpriteBase3D", true, false):
		lista.append(hijo)
	return lista

func _geometrias() -> Array[GeometryInstance3D]:
	var lista: Array[GeometryInstance3D] = []
	for hijo in visual.find_children("*", "MeshInstance3D", true, false):
		lista.append(hijo)
	return lista

func _reproducir_sonido(stream: AudioStream) -> void:
	if stream == null:
		return
	var reproductor: AudioStreamPlayer = AudioStreamPlayer.new()
	reproductor.stream = stream
	add_child(reproductor)
	reproductor.finished.connect(reproductor.queue_free)
	reproductor.play()

## Ráfaga de partículas (mismo estilo que la explosión de cristal del jarrón en el mundo)
func _explosion_particulas(posicion: Vector3) -> void:
	var particulas: CPUParticles3D = CPUParticles3D.new()
	particulas.amount = 40
	particulas.lifetime = 0.7
	particulas.one_shot = true
	particulas.explosiveness = 1.0
	particulas.direction = Vector3.UP
	particulas.spread = 180.0
	particulas.gravity = Vector3(0, -9.8, 0)
	particulas.initial_velocity_min = 3.0
	particulas.initial_velocity_max = 7.0

	var malla: QuadMesh = QuadMesh.new()
	malla.size = Vector2(0.14, 0.14)
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = color_particulas_derrota
	material.emission_enabled = true
	material.emission = color_particulas_derrota
	material.emission_energy_multiplier = 2.5
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	malla.material = material
	particulas.mesh = malla

	get_parent().add_child(particulas)
	particulas.global_position = posicion
	particulas.emitting = true
	get_tree().create_timer(particulas.lifetime + 0.3).timeout.connect(particulas.queue_free)
