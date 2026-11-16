class_name NordicVFX
extends RefCounted

const TEXTURAS = {
	&"impacto": preload("res://assets/sprites/vfx/nordic_v1/hit_spark.png"),
	&"paso": preload("res://assets/sprites/vfx/nordic_v1/step_dust.png"),
	&"agua": preload("res://assets/sprites/vfx/nordic_v1/water_splash.png"),
	&"recogida": preload("res://assets/sprites/vfx/nordic_v1/pickup_glint.png"),
}
const DURACIONES = {&"impacto": 0.18, &"paso": 0.32, &"agua": 0.30, &"recogida": 0.38}

## Efectos transitorios: no modifican daño, colisiones ni controles.
static func emitir(padre: Node, tipo: StringName, posicion: Vector3, ancho: float = 0.65) -> Sprite3D:
	if not is_instance_valid(padre) or not padre.is_inside_tree() or not TEXTURAS.has(tipo):
		return null
	var efecto := Sprite3D.new()
	efecto.name = "VFX_" + String(tipo)
	efecto.texture = TEXTURAS[tipo]
	efecto.pixel_size = ancho / float(efecto.texture.get_width())
	efecto.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	efecto.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	efecto.shaded = false
	padre.add_child(efecto)
	efecto.global_position = posicion
	efecto.add_to_group("vfx_nordicos")
	efecto.scale = Vector3.ONE * 0.65
	var duracion: float = DURACIONES[tipo]
	var tween := efecto.create_tween()
	tween.set_parallel(true)
	tween.tween_property(efecto, "scale", Vector3.ONE * 1.15, duracion).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(efecto, "modulate:a", 0.0, duracion * 0.7).set_delay(duracion * 0.3)
	if tipo != &"impacto":
		tween.tween_property(efecto, "global_position:y", posicion.y + 0.18, duracion)
	tween.chain().tween_callback(efecto.queue_free)
	return efecto
