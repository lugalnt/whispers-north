@tool
extends EditorPlugin

var _gizmo_plugin: CameraSwitchGizmoPlugin = null

func _enter_tree() -> void:
	_gizmo_plugin = preload("res://addons/camera_switch_gizmo/camera_switch_gizmo_plugin.gd").new()
	add_node_3d_gizmo_plugin(_gizmo_plugin)
	print("[CameraSwitchGizmo] Plugin activado: Puntos rojos habilitados en CameraSwitch.")

func _exit_tree() -> void:
	if _gizmo_plugin:
		remove_node_3d_gizmo_plugin(_gizmo_plugin)
		_gizmo_plugin = null
