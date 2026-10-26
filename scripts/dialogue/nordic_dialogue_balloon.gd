class_name NordicDialogueBalloon
extends CanvasLayer

## Globo de diálogo temático nórdico para Whispers of the North, integrado con Dialogue Manager.
## Estilizado con la estética oscura, dorada y de hielo del menú de pausa y combates.

@export var next_action: StringName = &"ui_accept"
@export var skip_action: StringName = &"ui_cancel"
@export var sfx_tecleo_defecto: AudioStream = preload("res://assets/audio/sfx/snd_bell_bounce_short.wav")

@onready var balloon: Control = %Balloon
@onready var character_label: RichTextLabel = %CharacterLabel
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var progress_indicator: Control = %ProgressIndicator
@onready var portrait_rect: TextureRect = %PortraitRect
@onready var portrait_container: Control = %PortraitContainer
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

var dialogue_resource: DialogueResource
var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
var will_hide_balloon: bool = false
var mutation_cooldown: Timer = Timer.new()
var _sfx_voz_actual: AudioStream = null
var _contador_letras: int = 0

var dialogue_line: DialogueLine:
	set(value):
		dialogue_line = value
		if dialogue_line:
			apply_dialogue_line()
		else:
			is_waiting_for_input = false
			if balloon:
				balloon.hide()
			hide()
			if owner == null:
				queue_free()
	get:
		return dialogue_line

func _ready() -> void:
	layer = 100
	balloon.hide()
	if Engine.has_singleton("DialogueManager"):
		Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	if responses_menu and responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if dialogue_label:
		dialogue_label.spoke.connect(_on_dialogue_spoke)

func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line) and progress_indicator:
		progress_indicator.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0 and not dialogue_line.has_tag("voice")

func _unhandled_input(event: InputEvent) -> void:
	if not visible or balloon == null or not balloon.visible:
		return
	
	# Si está tipeando el texto, interactuar o cancelar salta la animación de tecleo
	if dialogue_label and dialogue_label.is_typing:
		if event.is_action_pressed(skip_action) or event.is_action_pressed("interact") or event.is_action_pressed(next_action):
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return
	
	# Si espera entrada y no hay menú de respuestas
	if is_waiting_for_input and dialogue_line and dialogue_line.responses.size() == 0:
		if event.is_action_pressed(next_action) or event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			next(dialogue_line.next_id)
			return

## Inicia el diálogo con el recurso y cue dados
func start(with_dialogue_resource: DialogueResource = null, cue: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	
	# Extraer configuraciones personalizadas pasadas en extra_game_states
	_extraer_estados_personalizados(extra_game_states)
	
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	
	dialogue_line = await dialogue_resource.get_next_dialogue_line(cue, temporary_game_states)
	show()

func _extraer_estados_personalizados(extra_states: Array) -> void:
	for state in extra_states:
		if state is Dictionary:
			if state.has("retrato") and state["retrato"] is Texture2D:
				_mostrar_retrato(state["retrato"])
			if state.has("sfx_voz") and state["sfx_voz"] is AudioStream:
				_sfx_voz_actual = state["sfx_voz"]

func _mostrar_retrato(tex: Texture2D) -> void:
	if portrait_container and portrait_rect:
		if tex != null:
			portrait_rect.texture = tex
			portrait_container.show()
		else:
			portrait_container.hide()

## Aplica la línea de diálogo actual en la interfaz
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	if progress_indicator:
		progress_indicator.hide()
	is_waiting_for_input = false
	_contador_letras = 0
	
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	# 1. Nombre del personaje
	if not dialogue_line.character.is_empty():
		character_label.text = "[b][color=#ffd700]" + tr(dialogue_line.character, "dialogue") + "[/color][/b]"
		character_label.show()
	else:
		character_label.hide()

	# 2. Retrato por etiqueta #portrait=res://... o predeterminado
	if dialogue_line.has_tag("portrait"):
		var p_path: String = dialogue_line.get_tag_value("portrait")
		if ResourceLoader.exists(p_path):
			_mostrar_retrato(load(p_path))
		else:
			_resolver_retrato_por_nombre(p_path)

	# 3. Sonido de voz específico por etiqueta #voice_sfx=...
	if dialogue_line.has_tag("voice_sfx"):
		var sfx_path = dialogue_line.get_tag_value("voice_sfx")
		if ResourceLoader.exists(sfx_path):
			_sfx_voz_actual = load(sfx_path)

	# 4. Texto del diálogo
	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	# 5. Opciones de respuesta
	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# 6. Esperar siguiente línea o respuestas
	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
		# Enfocar la primera opción para navegación con mando o teclado
		var first_resp = responses_menu.get_child(0)
		if first_resp is Control:
			first_resp.grab_focus()
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()

func _resolver_retrato_por_nombre(nom: String) -> void:
	match nom.to_lower():
		"eric", "hero", "jugador":
			_mostrar_retrato(load("res://assets/sprites/player/test_hero_portrait.png"))
		"rata", "rat", "dani":
			_mostrar_retrato(load("res://assets/sprites/items/placeholder.png"))

## Avanza a la siguiente línea del diálogo
func next(next_id: String) -> void:
	if not is_instance_valid(dialogue_resource):
		return
	is_waiting_for_input = false
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)

func _on_dialogue_spoke(_letter: String, _letter_index: int, _speed: float) -> void:
	_contador_letras += 1
	# Emitir sonido sutil cada 2 letras para dar efecto de parloteo RPG agradable
	if _contador_letras % 2 == 0:
		var stream_a_tocar = _sfx_voz_actual if _sfx_voz_actual else sfx_tecleo_defecto
		if stream_a_tocar and audio_stream_player:
			audio_stream_player.stream = stream_a_tocar
			audio_stream_player.pitch_scale = randf_range(0.95, 1.05)
			audio_stream_player.volume_db = -12.0
			audio_stream_player.play()

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()

func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)

func _on_balloon_gui_input(event: InputEvent) -> void:
	if dialogue_label and dialogue_label.is_typing:
		var mouse_clic: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var btn_saltar: bool = event.is_action_pressed(skip_action) or event.is_action_pressed("interact") or event.is_action_pressed(next_action)
		if mouse_clic or btn_saltar:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input or dialogue_line == null or dialogue_line.responses.size() > 0:
		return

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		next(dialogue_line.next_id)
	elif (event.is_action_pressed(next_action) or event.is_action_pressed("interact")):
		get_viewport().set_input_as_handled()
		next(dialogue_line.next_id)

func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)
