extends CharacterBody3D

# Jarrón embrujado.
#
# Flujo del evento:
#   1. DORMIDO: espera quieto. Al VER al jugador (radio + línea de vista) da un saltito y lo persigue.
#   2. PERSIGUIENDO: se acerca todo lo posible (más lento que el jugador, así que se puede huir).
#   3. EN_CONTACTO: al estar pegado al jugador se muestra el textbox. Mientras dura:
#        - el jugador puede pulsar `interact` para EMPUJAR el jarrón hacia atrás (cancela el evento),
#        - o alejarse lo suficiente (distancia_escape) para cancelarlo.
#   4. Si el textbox termina y el evento no se canceló ("estar cerca mucho"):
#        - Si el jugador lleva a la rata encima: la rata grita, salta al jarrón y explotan los dos
#          (el jugador se salva y el cofre vuelve a su estado inicial).
#        - Si no: el jugador explota (igual que la rata en el cofre) y reaparece junto al arbusto
#          en la cámara 1. El jarrón vuelve a su posición inicial.
#
# Los controles se leen con la acción `interact` del Input Map (ver docs/INPUT_MAP.md).

enum Estado { DORMIDO, PERSIGUIENDO, EN_CONTACTO, ATURDIDO, REGRESANDO, EXPLOTANDO, COMBATIENDO }

@export_group("Combate RPG")
## Componente EncuentroCombate que orquesta la batalla. Si no se asigna, busca el hijo $EncuentroCombate.
@export var encuentro_combate: EncuentroCombate
## Si está activo, al tocar al jugador inicia un combate RPG estilo Paper Mario.
## Si se desactiva en el editor, reproduce el evento original cómico del textbox.
@export var modo_combate: bool = true
@export var escena_arena: PackedScene = preload("res://scenes/combat/CombatArena.tscn")
@export var escena_battler_jugador: PackedScene = preload("res://scenes/combat/battlers/PlayerBattler.tscn")
@export var escena_battler_pot: PackedScene = preload("res://scenes/combat/battlers/PotBattler.tscn")
## Jingle o fanfarria sonora de inicio de combate para este jarrón.
@export var jingle_combate: AudioStream
## Música temática para este combate de jarrón.
@export var musica_combate: AudioStream
## Textura de fondo personalizada para la arena cuando pelea este jarrón.
@export var textura_fondo_combate: Texture2D
## Mensaje al comenzar el combate contra este jarrón.
@export var texto_inicio_combate: String = ""
## Mensaje al ganar el combate contra este jarrón.
@export var texto_victoria_combate: String = ""
## Recompensas tras derrotar a este jarrón.
@export_multiline var texto_recompensas_combate: String = ""
## Experiencia otorgada por derrotar a este jarrón (-1 para usar la de la arena).
@export var exp_recompensa_combate: int = -1

@export_group("Combate Grupal")
## Si es true, este jarrón participa en un combate grupal con otros jarrones vinculados.
@export var combate_grupal: bool = false
## Jarrones que acompañan a este en combate. Si uno entra en batalla, todos entran juntos (ej. 1vs3).
@export var jarrones_vinculados: Array[NodePath] = []
## Identificador de grupo para vincular jarrones automáticamente (ej. &"trio_pots_town").
@export var grupo_jarrones: StringName = &""
## Si es true, cuando este jarrón avista al jugador también despierta y alerta a los jarrones vinculados.
@export var alertar_grupo: bool = true

# Modelos de fragmentos que salen volando al romperse el jarrón
const RUTAS_FRAGMENTOS: Array[String] = [
	"res://assets/models/Generic Pot/pot_brk_1.dae",
	"res://assets/models/Generic Pot/pot_brk_2.dae",
]

@export_group("Persecución")
# Velocidad máxima del jarrón (el jugador va a 5.0)
@export var velocidad: float = 3.4
@export var aceleracion: float = 12.0
# Distancia a la que el jarrón "ve" al jugador y empieza a perseguirlo
@export var radio_vision: float = 9.0
# Si el jugador se aleja más que esto, el jarrón se rinde y vuelve a su sitio
@export var radio_perdida: float = 18.0
# Si es true, árboles y otros obstáculos bloquean la vista del jarrón
@export var requiere_linea_de_vista: bool = true
@export var altura_ojos: float = 0.8
# Distancia (en el plano XZ, centro a centro) a la que cuenta como "estar cerca"
@export var distancia_contacto: float = 1.3
# Si el jugador se aleja más que esto durante el contacto, el evento se cancela
@export var distancia_escape: float = 3.2

@export_group("Empuje")
# Velocidad inicial con la que sale despedido el jarrón al empujarlo
@export var fuerza_empuje: float = 14.0
# Tiempo que tarda en frenarse tras el empujón
@export var duracion_empuje: float = 0.4
# Distancia máxima a la que el jugador puede empujarlo con `interact`
@export var distancia_empuje: float = 2.4
# Tiempo que queda aturdido tras un empujón antes de volver a perseguir
@export var duracion_aturdimiento: float = 1.6

@export_group("Evento de cercanía")
# Pausa entre que termina el textbox y ocurre la explosión
@export var pausa_tras_textbox: float = 0.3
@export var escena_textbox: PackedScene = preload("res://scenes/ui/TextBox.tscn")

@export_group("Respawn del jugador")
# Nodo junto al que reaparece el jugador (el arbusto "Bush"). Si está vacío se busca "Bush"
@export var punto_respawn: Node3D
@export var offset_respawn: Vector3 = Vector3(-1.8, 0.0, 0.0)
# Cámara que se activa al reaparecer (Camera1). Si está vacía se busca "Camera1"
@export var camara_respawn: Camera3D
# Tiempo con la pantalla "vacía" entre la explosión y la reaparición
@export var pausa_respawn: float = 1.0
@export var duracion_fade: float = 0.4

@export_group("Rata")
# Altura (sobre la base del jarrón) a la que aterriza la rata al saltar
@export var altura_impacto_rata: float = 0.8
@export var duracion_salto_rata: float = 0.55

@export_group("Botín / Item Drops")
## Si es true, el jarrón suelta ítems al romperse o destruirse
@export var soltar_item_al_romper: bool = true
## Ítem garantizado que siempre suelta al destruirse (arrastrar .tres desde data/items/)
@export var item_garantizado: InventoryItem = preload("res://data/items/fragmento_ceramica.tres")
@export_range(1, 10, 1) var cantidad_drop_garantizado: int = 1
## Pool de ítems (loot table) para drops aleatorios adicionales del mundo
@export var pool_items: ItemPool = preload("res://data/item_pools/pool_mundo_general.tres")
## Probabilidad de que se active la pool de drops (0.0 a 1.0)
@export_range(0.0, 1.0, 0.05) var probabilidad_pool: float = 0.5

@export_group("Sonidos")
@export var sonido_avistamiento: AudioStream = preload("res://assets/audio/sfx/snd_mysterygo.wav")
@export var sonido_empuje: AudioStream = preload("res://assets/audio/sfx/snd_doorclose.wav")
@export var sonido_grito: AudioStream = preload("res://assets/audio/sfx/scream.mp3")
@export var sonido_explosion: AudioStream = preload("res://assets/audio/sfx/snd_glassbreak.wav")

@onready var modelo: Node3D = $Modelo

var estado: Estado = Estado.DORMIDO

var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _posicion_inicial: Vector3
var _escala_modelo: Vector3
var _tiempo: float = 0.0
# Se incrementa cada vez que el evento de cercanía se cancela, para invalidar su corrutina
var _secuencia: int = 0
var _vel_empuje: Vector3 = Vector3.ZERO
var _tiempo_aturdido: float = 0.0
var _textbox: Node = null

func _ready() -> void:
	add_to_group("pot")
	if not grupo_jarrones.is_empty():
		add_to_group(grupo_jarrones)
	_posicion_inicial = global_position
	_escala_modelo = modelo.scale
	_obtener_encuentro()

func _obtener_encuentro() -> EncuentroCombate:
	if encuentro_combate != null:
		return encuentro_combate
	encuentro_combate = get_node_or_null("EncuentroCombate") as EncuentroCombate
	return encuentro_combate

func _exit_tree() -> void:
	if _textbox != null and is_instance_valid(_textbox):
		_textbox.queue_free()

# ---------------------------------------------------------------------------
# Entrada: empujar al jarrón
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if estado != Estado.PERSIGUIENDO and estado != Estado.EN_CONTACTO:
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return

	var jugador: CharacterBody3D = _obtener_jugador()
	if jugador == null:
		return
	# No se puede empujar mientras el jugador está ocupado (animación de interacción, etc.)
	if "is_interacting" in jugador and jugador.is_interacting:
		return
	if _distancia_xz(jugador) > distancia_empuje:
		return

	get_viewport().set_input_as_handled()
	_empujar(jugador)

# El jugador empuja al jarrón hacia atrás: se cancela el evento de cercanía y queda aturdido
func _empujar(jugador: CharacterBody3D) -> void:
	_cancelar_contacto()

	var direccion: Vector3 = global_position - jugador.global_position
	direccion.y = 0.0
	if direccion.length() < 0.01:
		direccion = Vector3.BACK
	_vel_empuje = direccion.normalized() * fuerza_empuje
	_tiempo_aturdido = duracion_aturdimiento
	estado = Estado.ATURDIDO

	_sonido_global(sonido_empuje)

	# Animación de interacción del jugador (solo si su modelo la tiene). Sin await para
	# que el empujón sea inmediato.
	if jugador.has_method("play_interact"):
		jugador.play_interact(global_position)

# ---------------------------------------------------------------------------
# Física y máquina de estados
# ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_tiempo += delta
	if not is_on_floor():
		velocity.y -= gravedad * delta

	var jugador: CharacterBody3D = _obtener_jugador()

	match estado:
		Estado.DORMIDO:
			_frenar(delta)
			if _puede_ver(jugador):
				_avistar()

		Estado.PERSIGUIENDO:
			if jugador == null or _distancia_xz(jugador) > radio_perdida:
				estado = Estado.REGRESANDO
			elif _distancia_xz(jugador) <= distancia_contacto:
				_frenar(delta)
				var enc: EncuentroCombate = _obtener_encuentro()
				if modo_combate and (enc == null or enc.activo):
					_iniciar_evento_combate(jugador)
				else:
					_iniciar_contacto()
			else:
				_mover_hacia(jugador.global_position, delta)

		Estado.EN_CONTACTO:
			if jugador == null:
				_cancelar_contacto()
				estado = Estado.REGRESANDO
			else:
				var distancia: float = _distancia_xz(jugador)
				if distancia > distancia_escape:
					# El jugador huyó: se cancela el evento y el jarrón sigue persiguiéndolo
					_cancelar_contacto()
					estado = Estado.PERSIGUIENDO
				elif distancia > distancia_contacto:
					_mover_hacia(jugador.global_position, delta)
				else:
					_frenar(delta)

		Estado.COMBATIENDO:
			velocity.x = 0.0
			velocity.z = 0.0

		Estado.ATURDIDO:
			_tiempo_aturdido -= delta
			velocity.x = _vel_empuje.x
			velocity.z = _vel_empuje.z
			_vel_empuje = _vel_empuje.move_toward(Vector3.ZERO, fuerza_empuje / maxf(duracion_empuje, 0.01) * delta)
			if _tiempo_aturdido <= 0.0:
				if jugador != null and _distancia_xz(jugador) <= radio_perdida:
					estado = Estado.PERSIGUIENDO
				else:
					estado = Estado.REGRESANDO

		Estado.REGRESANDO:
			if _puede_ver(jugador):
				estado = Estado.PERSIGUIENDO
			else:
				var falta: Vector2 = Vector2(_posicion_inicial.x - global_position.x, _posicion_inicial.z - global_position.z)
				if falta.length() < 0.15:
					_frenar(delta)
					estado = Estado.DORMIDO
				else:
					_mover_hacia(_posicion_inicial, delta, velocidad * 0.7)

		Estado.EXPLOTANDO:
			velocity.x = 0.0
			velocity.z = 0.0

	move_and_slide()
	_animar_modelo()

# El jarrón detecta al jugador: saltito de sorpresa y a perseguir
func _avistar() -> void:
	estado = Estado.PERSIGUIENDO
	velocity.y = 4.5
	_sonido_global(sonido_avistamiento)
	if alertar_grupo:
		for otro in _obtener_jarrones_vinculados():
			if is_instance_valid(otro) and otro != self and otro.estado == Estado.DORMIDO:
				otro.estado = Estado.PERSIGUIENDO
				otro.velocity.y = 4.5

# Mueve el jarrón en el plano XZ hacia un destino
func _mover_hacia(destino: Vector3, delta: float, vel_max: float = -1.0) -> void:
	var rapidez: float = velocidad if vel_max < 0.0 else vel_max
	var direccion: Vector3 = destino - global_position
	direccion.y = 0.0
	if direccion.length() > 0.01:
		direccion = direccion.normalized()
	var objetivo: Vector3 = direccion * rapidez
	velocity.x = move_toward(velocity.x, objetivo.x, aceleracion * delta)
	velocity.z = move_toward(velocity.z, objetivo.z, aceleracion * delta)

func _frenar(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, aceleracion * 2.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, aceleracion * 2.0 * delta)

# Devuelve el jugador activo (16x16 o 32x32) a través del mundo, grupos o jerarquía
func _obtener_jugador() -> CharacterBody3D:
	if is_inside_tree():
		var nodos = get_tree().get_nodes_in_group("player")
		for n in nodos:
			if is_instance_valid(n) and n is CharacterBody3D and n != self:
				return n as CharacterBody3D
		var mundo: Node = get_tree().current_scene
		if mundo != null and mundo.has_method("get_active_player"):
			return mundo.get_active_player()
		var root_w = get_tree().root
		if root_w:
			var p32 = root_w.find_child("Player32", true, false)
			if p32 is CharacterBody3D and p32 != self:
				return p32
			var p16 = root_w.find_child("Player", true, false)
			if p16 is CharacterBody3D and p16 != self:
				return p16

	# Búsqueda hacia arriba en la jerarquía (útil en escenas instanciadas y tests)
	var curr: Node = self
	while curr.get_parent() != null:
		curr = curr.get_parent()
		var p32 = curr.find_child("Player32", true, false)
		if p32 is CharacterBody3D and p32 != self:
			return p32
		var p16 = curr.find_child("Player", true, false)
		if p16 is CharacterBody3D and p16 != self:
			return p16

	return null

func _distancia_xz(jugador: CharacterBody3D) -> float:
	var delta_pos: Vector3 = jugador.global_position - global_position
	return Vector2(delta_pos.x, delta_pos.z).length()

# ¿Está el jugador dentro del radio de visión y sin obstáculos en medio?
func _puede_ver(jugador: CharacterBody3D) -> bool:
	if jugador == null or not jugador.is_inside_tree():
		return false
	if _distancia_xz(jugador) > radio_vision:
		return false
	if not requiere_linea_de_vista:
		return true

	var desde: Vector3 = global_position + Vector3.UP * altura_ojos
	var hasta: Vector3 = jugador.global_position + Vector3.UP * 0.8
	var excludes: Array[RID] = [get_rid(), jugador.get_rid()]
	if is_inside_tree():
		for otro in get_tree().get_nodes_in_group("pot"):
			if otro is CollisionObject3D and is_instance_valid(otro):
				excludes.append(otro.get_rid())
	var consulta: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(desde, hasta, collision_mask, excludes)
	return get_world_3d().direct_space_state.intersect_ray(consulta).is_empty()

# Saltitos mientras se mueve, temblor en contacto y bamboleo al ser empujado
func _animar_modelo() -> void:
	var horizontal: float = Vector2(velocity.x, velocity.z).length()
	var salto: float = 0.0
	var aplastado: float = 0.0
	var giro: float = 0.0

	match estado:
		Estado.PERSIGUIENDO, Estado.REGRESANDO, Estado.EN_CONTACTO:
			if horizontal > 0.3:
				salto = absf(sin(_tiempo * 9.0)) * 0.12 * clampf(horizontal / velocidad, 0.0, 1.0)
				aplastado = sin(_tiempo * 18.0) * 0.05
			if estado == Estado.EN_CONTACTO:
				giro = sin(_tiempo * 50.0) * 0.05
		Estado.ATURDIDO:
			giro = sin(_tiempo * 40.0) * 0.18 * clampf(_tiempo_aturdido / duracion_aturdimiento, 0.0, 1.0)

	modelo.position.y = salto
	modelo.rotation.z = giro
	modelo.scale = _escala_modelo * Vector3(1.0 + aplastado, 1.0 - aplastado, 1.0 + aplastado)

# ---------------------------------------------------------------------------
# Combate RPG (Estilo Paper Mario)
# ---------------------------------------------------------------------------

## Obtiene la lista de todos los jarrones vinculados a este grupo (incluyendo a self)
func _obtener_jarrones_vinculados() -> Array:
	var lista: Array = []
	if not combate_grupal:
		return [self]
	
	for path in jarrones_vinculados:
		if path != null and not path.is_empty():
			var nodo = get_node_or_null(path)
			if nodo != null and is_instance_valid(nodo) and nodo != self and not lista.has(nodo):
				lista.append(nodo)
	
	if not grupo_jarrones.is_empty() and is_inside_tree():
		for nodo in get_tree().get_nodes_in_group(grupo_jarrones):
			if nodo != null and is_instance_valid(nodo) and nodo != self and not lista.has(nodo):
				lista.append(nodo)
	
	if not lista.has(self):
		lista.push_front(self)
	return lista

func _iniciar_evento_combate(jugador: CharacterBody3D) -> void:
	if estado == Estado.COMBATIENDO:
		return
	estado = Estado.COMBATIENDO
	velocity = Vector3.ZERO
	_secuencia += 1

	var grupo: Array = _obtener_jarrones_vinculados()
	if not grupo.has(self):
		grupo.push_front(self)

	# Todos los jarrones del grupo entran en combate y ocultan su modelo
	for j in grupo:
		if is_instance_valid(j):
			j.estado = Estado.COMBATIENDO
			j.velocity = Vector3.ZERO
			j._secuencia += 1
			if j.modelo:
				j.modelo.hide()

	var enc: EncuentroCombate = _obtener_encuentro()
	var resultado: CombatArena.ResultadoCombate
	if enc != null:
		if jingle_combate != null:
			enc.jingle_inicio = jingle_combate
		if musica_combate != null:
			enc.musica_combate = musica_combate
		if textura_fondo_combate != null:
			enc.textura_fondo = textura_fondo_combate
		
		# 1 battler de jarrón por cada miembro del grupo
		var lista_enemigos: Array[PackedScene] = []
		for _j in grupo:
			lista_enemigos.append(escena_battler_pot)
		enc.enemigos = lista_enemigos
		
		if not texto_inicio_combate.is_empty():
			enc.texto_inicio_combate = texto_inicio_combate
		elif grupo.size() > 1:
			enc.texto_inicio_combate = "¡Emboscada de %d Jarrones Embrujados!" % grupo.size()
		if not texto_victoria_combate.is_empty():
			enc.texto_victoria = texto_victoria_combate
		if not texto_recompensas_combate.is_empty():
			enc.texto_recompensas = texto_recompensas_combate
		elif grupo.size() > 1:
			enc.texto_recompensas = "¡Victoria sobre los %d jarrones!\n\n+%d EXP\nObtuviste botín de jarrones." % [grupo.size(), 20 * grupo.size()]
		if exp_recompensa_combate >= 0:
			enc.exp_recompensa = exp_recompensa_combate
		elif grupo.size() > 1:
			enc.exp_recompensa = 20 * grupo.size()

		resultado = await enc.iniciar_combate(jugador, null)
	else:
		# Fallback autónomo si no existiera el componente EncuentroCombate
		var encuentro_temp: EncuentroCombate = EncuentroCombate.new()
		encuentro_temp.escena_arena = escena_arena
		encuentro_temp.aliados = [escena_battler_jugador]
		var lista_enemigos_temp: Array[PackedScene] = []
		for _j in grupo:
			lista_enemigos_temp.append(escena_battler_pot)
		encuentro_temp.enemigos = lista_enemigos_temp
		if jingle_combate != null:
			encuentro_temp.jingle_inicio = jingle_combate
		if musica_combate != null:
			encuentro_temp.musica_combate = musica_combate
		if textura_fondo_combate != null:
			encuentro_temp.textura_fondo = textura_fondo_combate
		if not texto_inicio_combate.is_empty():
			encuentro_temp.texto_inicio_combate = texto_inicio_combate
		elif grupo.size() > 1:
			encuentro_temp.texto_inicio_combate = "¡Emboscada de %d Jarrones Embrujados!" % grupo.size()
		if not texto_victoria_combate.is_empty():
			encuentro_temp.texto_victoria = texto_victoria_combate
		if not texto_recompensas_combate.is_empty():
			encuentro_temp.texto_recompensas = texto_recompensas_combate
		elif grupo.size() > 1:
			encuentro_temp.texto_recompensas = "¡Victoria sobre los %d jarrones!\n\n+%d EXP\nObtuviste botín de jarrones." % [grupo.size(), 20 * grupo.size()]
		if exp_recompensa_combate >= 0:
			encuentro_temp.exp_recompensa = exp_recompensa_combate
		elif grupo.size() > 1:
			encuentro_temp.exp_recompensa = 20 * grupo.size()
		add_child(encuentro_temp)
		resultado = await encuentro_temp.iniciar_combate(jugador, null)
		encuentro_temp.queue_free()

	# Procesar el resultado según las reglas pedidas:
	match resultado:
		CombatArena.ResultadoCombate.VICTORIA:
			# Ganar: todos los jarrones del grupo se rompen con fragmentos/partículas y desaparecen
			_bloquear_jugador(jugador, false)
			for j in grupo:
				if is_instance_valid(j):
					j._destruir(j.global_position + Vector3(0.0, 0.6, 0.0))
		CombatArena.ResultadoCombate.DERROTA:
			# Perder: el jugador explota y todos los jarrones vuelven a su sitio
			for j in grupo:
				if is_instance_valid(j):
					if j.modelo:
						j.modelo.show()
					j._reiniciar_jarron()
			await _explotar_jugador(jugador)
		CombatArena.ResultadoCombate.HUIDA:
			# Huir: vuelves al mundo y todos los jarrones quedan aturdidos para poder escapar
			_bloquear_jugador(jugador, false)
			for j in grupo:
				if is_instance_valid(j):
					if j.modelo:
						j.modelo.show()
					var direccion: Vector3 = j.global_position - jugador.global_position
					direccion.y = 0.0
					if direccion.length() < 0.01:
						direccion = Vector3.BACK
					j._vel_empuje = direccion.normalized() * (fuerza_empuje * 0.8)
					j._tiempo_aturdido = duracion_aturdimiento * 2.0
					j.estado = Estado.ATURDIDO

# ---------------------------------------------------------------------------
# Evento de cercanía original (textbox)
# ---------------------------------------------------------------------------

func _iniciar_contacto() -> void:
	estado = Estado.EN_CONTACTO
	_secuencia += 1
	var mi_secuencia: int = _secuencia

	var caja: Node = _obtener_textbox()
	caja.reproducir()
	var completo: bool = await caja.terminado
	if not completo or mi_secuencia != _secuencia or estado != Estado.EN_CONTACTO:
		return

	await get_tree().create_timer(pausa_tras_textbox).timeout
	if mi_secuencia != _secuencia or estado != Estado.EN_CONTACTO:
		return

	await _resolver_contacto()

# Cancela el evento de cercanía en curso (empujón o huida del jugador)
func _cancelar_contacto() -> void:
	_secuencia += 1
	_ocultar_textbox()

func _obtener_textbox() -> Node:
	if _textbox == null or not is_instance_valid(_textbox):
		_textbox = escena_textbox.instantiate()
		get_tree().current_scene.add_child(_textbox)
	return _textbox

func _ocultar_textbox() -> void:
	if _textbox != null and is_instance_valid(_textbox):
		_textbox.ocultar()

# El jugador se quedó cerca demasiado tiempo: explota él o, si tiene a la rata encima, ella lo salva
func _resolver_contacto() -> void:
	estado = Estado.EXPLOTANDO
	velocity.x = 0.0
	velocity.z = 0.0
	_ocultar_textbox()

	var jugador: CharacterBody3D = _obtener_jugador()
	if jugador == null:
		estado = Estado.DORMIDO
		return

	var rata: Node3D = _buscar_rata(jugador)
	if rata != null:
		await _sacrificio_de_la_rata(jugador, rata)
	else:
		await _explotar_jugador(jugador)

# ---------------------------------------------------------------------------
# Final A: la rata se sacrifica y se lleva al jarrón consigo
# ---------------------------------------------------------------------------

func _sacrificio_de_la_rata(jugador: CharacterBody3D, rata: Node3D) -> void:
	var estaba_bloqueado: bool = _bloquear_jugador(jugador, true)

	# La rata se separa de la cabeza del jugador conservando su posición en el mundo
	var mundo: Node = get_tree().current_scene
	rata.reparent(mundo, true)

	# La rata grita y se agacha para tomar impulso
	_sonido_global(sonido_grito)
	var tween_agachar: Tween = create_tween()
	tween_agachar.tween_property(rata, "scale", Vector3(1.3, 0.6, 1.3), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween_agachar.finished
	if not is_instance_valid(rata):
		_bloquear_jugador(jugador, estaba_bloqueado)
		return
	rata.scale = Vector3.ONE

	# Salto parabólico hacia el jarrón (mismo método que el salto del cofre a la cabeza)
	var destino: Vector3 = global_position + Vector3(0.0, altura_impacto_rata, 0.0)
	var pos_inicial: Vector3 = rata.global_position
	var altura_pico: float = maxf(pos_inicial.y, destino.y) + 1.2
	var mitad: float = duracion_salto_rata / 2.0

	var tween_xz: Tween = create_tween().set_parallel(true)
	tween_xz.tween_property(rata, "global_position:x", destino.x, duracion_salto_rata).set_trans(Tween.TRANS_LINEAR)
	tween_xz.tween_property(rata, "global_position:z", destino.z, duracion_salto_rata).set_trans(Tween.TRANS_LINEAR)

	var tween_y: Tween = create_tween()
	tween_y.tween_property(rata, "global_position:y", altura_pico, mitad).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_y.tween_property(rata, "global_position:y", destino.y, mitad).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween_xz.finished

	# Los dos se hinchan a la vez (rata con destello blanco) y estallan
	var tween_pop: Tween = create_tween().set_parallel(true)
	tween_pop.tween_property(modelo, "scale", _escala_modelo * 1.35, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if is_instance_valid(rata):
		tween_pop.tween_property(rata, "scale", Vector3(1.7, 1.7, 1.7), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var sprite_rata: Sprite3D = _obtener_sprite_rata(rata)
		if sprite_rata:
			tween_pop.tween_property(sprite_rata, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.08)
	await tween_pop.finished

	var punto_explosion: Vector3 = global_position + Vector3(0.0, altura_impacto_rata, 0.0)
	if is_instance_valid(rata):
		rata.queue_free()
	_reiniciar_cofres()

	_bloquear_jugador(jugador, estaba_bloqueado)

	# El jarrón desaparece para siempre
	_destruir(punto_explosion)

# ---------------------------------------------------------------------------
# Final B: el jugador explota y reaparece junto al arbusto
# ---------------------------------------------------------------------------

func _explotar_jugador(jugador: CharacterBody3D) -> void:
	_bloquear_jugador(jugador, true)
	jugador.velocity = Vector3.ZERO

	var sprite: SpriteBase3D = jugador.get_node_or_null("Sprite2_5D") as SpriteBase3D
	var escala_original: Vector3 = sprite.scale if sprite else Vector3.ONE

	# Grito y espera hasta el punto culminante (igual que la rata en el cofre)
	_sonido_global(sonido_grito)
	await get_tree().create_timer(0.6).timeout
	if not is_instance_valid(jugador):
		return

	# Efecto de hinchado/globo y destello blanco antes de estallar
	var pos_explosion: Vector3 = jugador.global_position + Vector3(0.0, 0.3, 0.0)
	if sprite:
		var tween_pop: Tween = create_tween().set_parallel(true)
		tween_pop.tween_property(sprite, "scale", escala_original * 1.7, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_pop.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.08)
		await tween_pop.finished

	# Explosión de cristal y el jugador desaparece
	_sonido_global(sonido_explosion)
	_crear_explosion_cristal(pos_explosion)
	if sprite:
		sprite.hide()

	await get_tree().create_timer(pausa_respawn).timeout
	if not is_instance_valid(jugador):
		return

	# Reaparición junto al arbusto, en la cámara 1
	var destino: Vector3 = _posicion_de_respawn(jugador)
	jugador.global_position = destino
	jugador.velocity = Vector3.ZERO
	jugador.reset_physics_interpolation()
	_activar_camara_respawn()

	# El jarrón vuelve a su sitio, lejos de la vista del jugador
	_reiniciar_jarron()

	if sprite:
		sprite.scale = escala_original
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
		sprite.show()
		var tween_in: Tween = create_tween()
		tween_in.tween_property(sprite, "modulate:a", 1.0, duracion_fade)
		await tween_in.finished

	if is_instance_valid(jugador):
		_bloquear_jugador(jugador, false)

func _posicion_de_respawn(jugador: CharacterBody3D) -> Vector3:
	var punto: Node3D = punto_respawn
	if punto == null:
		punto = get_tree().current_scene.get_node_or_null("Bush")
	if punto != null:
		return punto.global_position + offset_respawn
	push_warning("Pot: no hay punto_respawn ni nodo 'Bush'; el jugador reaparece donde estaba.")
	return jugador.global_position

func _activar_camara_respawn() -> void:
	var camara: Camera3D = camara_respawn
	if camara == null:
		camara = get_tree().current_scene.get_node_or_null("Camera1")
	if camara != null:
		camara.make_current()

# Deja al jarrón en su posición inicial, dormido y sin velocidad
func _reiniciar_jarron() -> void:
	global_position = _posicion_inicial
	velocity = Vector3.ZERO
	_vel_empuje = Vector3.ZERO
	modelo.scale = _escala_modelo
	estado = Estado.DORMIDO

# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

# Bloquea/desbloquea el movimiento del jugador (reutiliza is_interacting de player.gd).
# Devuelve el valor anterior para poder restaurarlo.
func _bloquear_jugador(jugador: CharacterBody3D, bloquear: bool) -> bool:
	if not is_instance_valid(jugador) or not ("is_interacting" in jugador):
		return false
	var anterior: bool = jugador.is_interacting
	jugador.is_interacting = bloquear
	return anterior

# Busca a la rata anclada a la cabeza del jugador (la que dejó el cofre)
func _buscar_rata(jugador: CharacterBody3D) -> Node3D:
	for hijo in jugador.get_children():
		if hijo is Node3D and (hijo.is_in_group("rat") or hijo.name.begins_with("Rat")):
			return hijo
	return null

# Avisa a los cofres de que su rata ya no existe para que se reinicien (bucle del cofre)
func _reiniciar_cofres() -> void:
	for cofre in get_tree().get_nodes_in_group("cofre"):
		if cofre.has_method("reiniciar_estado"):
			cofre.reiniciar_estado()

# Estalla el jarrón: sonido, partículas, fragmentos, suelta ítems y se elimina
func _destruir(posicion: Vector3) -> void:
	_sonido_global(sonido_explosion)
	_crear_explosion_cristal(posicion)
	_crear_fragmentos(posicion)
	_soltar_item_drop(posicion)
	queue_free()

## Suelta los objetos configurados en el mundo mediante ItemPickup3D
func _soltar_item_drop(posicion: Vector3) -> void:
	if not soltar_item_al_romper:
		return
	var tree := get_tree()
	var mundo: Node = tree.current_scene if (tree and tree.current_scene) else (tree.root if tree else null)
	if mundo == null:
		return
	
	# 1. Drop garantizado
	if item_garantizado != null and cantidad_drop_garantizado > 0:
		ItemPickup3D.spawn_en_posicion(mundo, posicion, item_garantizado, cantidad_drop_garantizado, true)
	
	# 2. Drop aleatorio desde ItemPool
	if pool_items != null and randf() <= probabilidad_pool:
		var drops: Array[Dictionary] = pool_items.generar_drops()
		for d in drops:
			var it: InventoryItem = d.get("item")
			var cant: int = d.get("cantidad", 1)
			if it != null and cant > 0:
				ItemPickup3D.spawn_en_posicion(mundo, posicion, it, cant, true)

# Fragmentos físicos (RigidBody3D) con los modelos pot_brk_*, que desaparecen tras un rato
func _crear_fragmentos(posicion: Vector3) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var mundo: Node = tree.current_scene if tree else null
	if mundo == null:
		return

	var escenas: Array[PackedScene] = []
	for ruta in RUTAS_FRAGMENTOS:
		if ResourceLoader.exists(ruta):
			var recurso: Resource = load(ruta)
			if recurso is PackedScene:
				escenas.append(recurso)
	if escenas.is_empty():
		return

	for i in range(12):
		var cuerpo: RigidBody3D = RigidBody3D.new()
		cuerpo.collision_layer = 2 # capa propia: no estorba al jugador
		cuerpo.collision_mask = 1
		cuerpo.mass = 0.3

		var forma: CollisionShape3D = CollisionShape3D.new()
		var esfera: SphereShape3D = SphereShape3D.new()
		esfera.radius = 0.16
		forma.shape = esfera
		cuerpo.add_child(forma)

		var visual: Node3D = escenas[i % escenas.size()].instantiate()
		visual.scale = Vector3.ONE * randf_range(1.2, 1.9)
		cuerpo.add_child(visual)

		mundo.add_child(cuerpo)
		cuerpo.global_position = posicion + Vector3(randf_range(-0.3, 0.3), randf_range(0.0, 0.5), randf_range(-0.3, 0.3))

		var impulso: Vector3 = Vector3(randf_range(-1.0, 1.0), randf_range(0.6, 1.4), randf_range(-1.0, 1.0)).normalized()
		cuerpo.linear_velocity = impulso * randf_range(3.0, 6.0)
		cuerpo.angular_velocity = Vector3(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))

		var tween: Tween = cuerpo.create_tween()
		tween.tween_interval(randf_range(2.0, 2.8))
		tween.tween_property(visual, "scale", Vector3.ONE * 0.001, 0.4)
		tween.tween_callback(cuerpo.queue_free)

# Emisor procedural de partículas para simular cristal o globo explotando (igual que chest.gd)
func _crear_explosion_cristal(posicion: Vector3) -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	var mundo: Node = tree.current_scene if tree else null
	if mundo == null:
		return

	var particulas: CPUParticles3D = CPUParticles3D.new()
	particulas.amount = 35
	particulas.lifetime = 0.6
	particulas.one_shot = true
	particulas.explosiveness = 1.0

	particulas.direction = Vector3(0, 1, 0)
	particulas.spread = 180.0
	particulas.gravity = Vector3(0, -9.8, 0)
	particulas.initial_velocity_min = 3.5
	particulas.initial_velocity_max = 7.5

	# Malla de fragmentos de cristal brillantes
	var malla: QuadMesh = QuadMesh.new()
	malla.size = Vector2(0.12, 0.12)

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.95, 1.0, 0.9)
	material.emission_enabled = true
	material.emission = Color(0.7, 0.9, 1.0)
	material.emission_energy_multiplier = 3.0
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	malla.material = material

	particulas.mesh = malla

	mundo.add_child(particulas)
	particulas.global_position = posicion
	particulas.emitting = true
	get_tree().create_timer(particulas.lifetime + 0.2).timeout.connect(particulas.queue_free)

# Nodo Sprite3D dentro de la estructura de la rata
func _obtener_sprite_rata(nodo_rata: Node) -> Sprite3D:
	if nodo_rata is Sprite3D:
		return nodo_rata as Sprite3D
	var sprite: Node = nodo_rata.find_child("Sprite3D", true, false)
	if sprite is Sprite3D:
		return sprite as Sprite3D
	return null

# Reproduce un SFX global (no depende de que este nodo siga vivo)
func _sonido_global(stream: AudioStream) -> void:
	if stream == null or not is_inside_tree():
		return
	var tree := get_tree()
	var mundo: Node = tree.current_scene if tree else null
	if mundo == null:
		return
	var reproductor: AudioStreamPlayer = AudioStreamPlayer.new()
	reproductor.stream = stream
	mundo.add_child(reproductor)
	reproductor.finished.connect(reproductor.queue_free)
	reproductor.play()
