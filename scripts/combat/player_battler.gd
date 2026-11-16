extends Battler

## Usa siempre el personaje de 32x32 y añade el golpe sin mutar sus SpriteFrames.
const PERSONAJE_32 = preload("res://scenes/player/player_32.tscn")
const PUNCH_32 = preload("res://data/combat/player_punch_32.tres")

func copiar_sprite_de(_jugador_campo: Node) -> void:
	var personaje: Node = PERSONAJE_32.instantiate()
	super.copiar_sprite_de(personaje)
	personaje.free()
	var sprite := visual as AnimatedSprite3D
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = sprite.sprite_frames.duplicate()
	var ataque: SpriteFrames = PUNCH_32
	if frames.has_animation(anim_ataque):
		frames.remove_animation(anim_ataque)
	frames.add_animation(anim_ataque)
	frames.set_animation_loop(anim_ataque, false)
	frames.set_animation_speed(anim_ataque, ataque.get_animation_speed(anim_ataque))
	for i in ataque.get_frame_count(anim_ataque):
		frames.add_frame(anim_ataque, ataque.get_frame_texture(anim_ataque, i), ataque.get_frame_duration(anim_ataque, i))
	sprite.sprite_frames = frames

func reproducir(anim: StringName) -> bool:
	if anim == anim_ataque and visual is AnimatedSprite3D:
		(visual as AnimatedSprite3D).stop()
	return super.reproducir(anim)
