extends Battler
## Adaptación exclusiva del sprite de Jarrito; la llama forma parte del atlas.

var _en_derrota: bool = false


func reproducir(anim: StringName) -> bool:
	if _en_derrota and anim != &"defeat":
		return false
	# Reiniciar también si se solicita dos veces la misma animación terminada.
	var sprite := visual as AnimatedSprite3D
	if sprite and sprite.sprite_frames.has_animation(anim):
		sprite.stop()
	return super.reproducir(anim)


func quedarse_quieto() -> void:
	if _en_derrota or not esta_vivo():
		return
	super.quedarse_quieto()


func animar_herido() -> void:
	if _en_derrota or not esta_vivo():
		return
	_reproducir_sonido(sonido_herido)
	reproducir(anim_herido)
	await esperar_animacion()
	quedarse_quieto()


func animar_derrota() -> void:
	if _en_derrota:
		await esperar_animacion()
		return
	_en_derrota = true
	_reproducir_sonido(sonido_derrota)
	reproducir(&"defeat")
	await esperar_animacion()
	# Conservar el último cuadro hasta que la arena se libere.
