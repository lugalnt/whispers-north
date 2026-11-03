@icon("uid://rdhqkhh5bmca")
class_name ControlsRemap extends Resource

## A resource for modifying, saving and loading project's InputMap.
##
## Stores and applies input map changes. The action list can be configured via "addons/ControlsRemap/action_list" project setting. Physical key events are not supported.

const _SETTING_NAME = "addons/ControlsRemap/action_list"
const _DEFAULT_ACTION_LIST: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_accept", &"ui_cancel"]

## Prefix for this remap resource (useful for multiple control schemes in multiplayer games etc).
## [br][br][b]Note:[/b] Setting this property erases remaps stored in this resource. Set it only during initialization.
@export var prefix: String:
	set(p_prefix):
		prefix = p_prefix
		
		_action_list = ProjectSettings.get_setting(_SETTING_NAME, _DEFAULT_ACTION_LIST)
		if not prefix.is_empty():
			_action_list.assign(_action_list.map(func(action: StringName) -> StringName: return prefix + action))
		
		_keyboard_remap.clear()
		_joypad_remap.clear()
		_load_defaults()

@export_storage var _keyboard_remap: Dictionary[StringName, int]
@export_storage var _joypad_remap: Dictionary[StringName, int]

var _action_list: Array[StringName]

var _default_keyboard: Dictionary[StringName, int]
var _default_joypad: Dictionary[StringName, int]
var _default_events: Dictionary[StringName, Array] = {}

var _stashed_keyboard: Dictionary[StringName, int]
var _stashed_joypad: Dictionary[StringName, int]

func _init(p_prefix := "") -> void:
	prefix = p_prefix

## Creates a remap by fetching the actions from [InputMap]. Only non-default actions are stored.
func create_remap():
	_keyboard_remap.clear()
	_joypad_remap.clear()
	
	var keyboard_actions: Dictionary[StringName, int]
	var joypad_actions: Dictionary[StringName, int]
	
	for action in _action_list:
		_map_input(keyboard_actions, action, get_action_key(action))
		
		if keyboard_actions.get(action, -1) != _default_keyboard.get(action, -1):
			_keyboard_remap[action] = keyboard_actions[action]
		
		_map_input(joypad_actions, action, get_action_button(action))
		
		if joypad_actions.get(action, -1) != _default_joypad.get(action, -1):
			_joypad_remap[action] = joypad_actions[action]

## Applies the inputs from this ControlsRemap to the projects InputMap.
func apply_remap():
	restore_default_controls()
	for action in _action_list:
		_demap_input(_keyboard_remap, action, get_action_key(action))
		_demap_input(_joypad_remap, action, get_action_button(action))

## Restores all actions to the defaults defined in project's settings.
func restore_default_controls():
	for action in _action_list:
		restore_action_default(action)

## Restores a single action to its default state.
func restore_action_default(action: String):
	if _default_events.has(StringName(action)):
		for ev in InputMap.action_get_events(action):
			InputMap.action_erase_event(action, ev)
		for ev in _default_events[StringName(action)]:
			InputMap.action_add_event(action, ev.duplicate())
	else:
		_demap_input(_default_keyboard, action, get_action_key(action))
		_demap_input(_default_joypad, action, get_action_button(action))

## Creates an internal clone of the remap resource.
func clone_remap() -> void:
	_stashed_keyboard = _keyboard_remap.duplicate()
	_stashed_joypad = _joypad_remap.duplicate()

## Restores remap from the internal clone.
func restore_cloned_remap() -> void:
	_keyboard_remap = _stashed_keyboard.duplicate()
	_joypad_remap = _stashed_joypad.duplicate()

## Replaces the first [InputEventKey] in an action with the given one using action_erase_event/action_add_event.
func set_action_key(action: String, key: InputEventKey) -> bool:
	var nuevo := InputEventKey.new()
	nuevo.physical_keycode = key.physical_keycode if key.physical_keycode != 0 else key.keycode
	nuevo.keycode = key.keycode
	nuevo.device = -1
	
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	InputMap.action_add_event(action, nuevo)
	return true

## Returns the first [InputEventKey] assigned to the action.
func get_action_key(action: String) -> InputEventKey:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event
	return null

## Replaces joypad button or motion in an action with the given button using action_erase_event/action_add_event.
func set_action_button(action: String, button: InputEventJoypadButton) -> bool:
	var nuevo := InputEventJoypadButton.new()
	nuevo.button_index = button.button_index
	nuevo.device = -1
	
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			InputMap.action_erase_event(action, event)
	InputMap.action_add_event(action, nuevo)
	return true

## Replaces joypad button or motion in an action with the given motion using action_erase_event/action_add_event.
func set_action_motion(action: String, motion: InputEventJoypadMotion) -> bool:
	var nuevo := InputEventJoypadMotion.new()
	nuevo.axis = motion.axis
	nuevo.axis_value = 1.0 if motion.axis_value > 0.0 else -1.0
	nuevo.device = -1
	
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			InputMap.action_erase_event(action, event)
	InputMap.action_add_event(action, nuevo)
	return true

## Returns the first [InputEventJoypadButton] assigned to the action.
func get_action_button(action: String) -> InputEventJoypadButton:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton:
			return event
	return null

## Returns the first [InputEventJoypadMotion] assigned to the action.
func get_action_motion(action: String) -> InputEventJoypadMotion:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			return event
	return null

## Returns an array of action names that have assigned conflicting input events.
func find_duplicates() -> Array[StringName]:
	var dupes: Array[StringName] = []
	for i in range(_action_list.size()):
		var a1 = _action_list[i]
		for j in range(i + 1, _action_list.size()):
			var a2 = _action_list[j]
			if _hay_conflicto(a1, a2):
				if not a1 in dupes: dupes.append(a1)
				if not a2 in dupes: dupes.append(a2)
	return dupes

func _hay_conflicto(a1: StringName, a2: StringName) -> bool:
	var k1 := get_action_key(a1)
	var k2 := get_action_key(a2)
	if k1 and k2:
		var code1 = k1.physical_keycode if k1.physical_keycode != 0 else k1.keycode
		var code2 = k2.physical_keycode if k2.physical_keycode != 0 else k2.keycode
		if code1 != 0 and code1 == code2:
			return true

	var b1 := get_action_button(a1)
	var b2 := get_action_button(a2)
	if b1 and b2 and b1.button_index == b2.button_index:
		return true

	var m1 := get_action_motion(a1)
	var m2 := get_action_motion(a2)
	if m1 and m2 and m1.axis == m2.axis and sign(m1.axis_value) == sign(m2.axis_value):
		return true

	return false

func _load_defaults():
	_default_keyboard.clear()
	_default_joypad.clear()
	_default_events.clear()
	
	for action in _action_list:
		_default_events[action] = []
		for ev in InputMap.action_get_events(action):
			_default_events[action].append(ev.duplicate())
		_map_input(_default_keyboard, action, get_action_key(action))
		_map_input(_default_joypad, action, get_action_button(action))

func _map_input(map: Dictionary[StringName, int], action: StringName, input: InputEvent):
	var k := input as InputEventKey
	if k:
		map[action] = k.physical_keycode if k.physical_keycode != 0 else k.keycode
		return
	
	var j := input as InputEventJoypadButton
	if j:
		map[action] = j.button_index

func _demap_input(map: Dictionary[StringName, int], action: StringName, input: InputEvent):
	if not action in map:
		return
	
	var k := input as InputEventKey
	if k:
		if k.physical_keycode != 0:
			k.physical_keycode = map[action]
		else:
			k.keycode = map[action]
		return
	
	var j := input as InputEventJoypadButton
	if j:
		j.button_index = map[action]
