@tool
class_name CameraSwitchGizmoPlugin
extends EditorNode3DGizmoPlugin

## Gizmo plugin que añade los puntos rojos (manejadores) a CameraSwitch en el Viewport 3D,
## permitiendo redimensionar el ancho, alto y profundidad del trigger arrastrando interactivamente.

const CameraSwitchScript = preload("res://scripts/world/camera_switch.gd")

func _init() -> void:
	create_handle_material("handles")

func _has_gizmo(for_node_3d: Node3D) -> bool:
	return for_node_3d is CameraSwitchScript

func _get_gizmo_name() -> String:
	return "CameraSwitchGizmo"

func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	var node = gizmo.get_node_3d()
	if node == null:
		return
	
	var size: Vector3 = node.tamano_trigger
	var h: Vector3 = size * 0.5
	
	# Puntos rojos de control (Handles):
	# 0: +X (Derecha)
	# 1: -X (Izquierda)
	# 2: +Y (Arriba)
	# 3: +Z (Frente)
	# 4: -Z (Atrás)
	var handles = PackedVector3Array([
		Vector3(h.x, h.y, 0),    # 0: +X
		Vector3(-h.x, h.y, 0),   # 1: -X
		Vector3(0, size.y, 0),   # 2: +Y
		Vector3(0, h.y, h.z),    # 3: +Z
		Vector3(0, h.y, -h.z)    # 4: -Z
	])
	var ids = PackedInt32Array([0, 1, 2, 3, 4])
	gizmo.add_handles(handles, get_material("handles", gizmo), ids)

func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	match handle_id:
		0, 1: return "Ancho (X)"
		2: return "Alto (Y)"
		3, 4: return "Profundidad (Z)"
	return "Dimensión"

func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	var node = gizmo.get_node_3d()
	if node:
		return node.tamano_trigger
	return Vector3.ZERO

func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
	var node = gizmo.get_node_3d()
	if node == null:
		return
	
	var ray_from = camera.project_ray_origin(screen_pos)
	var ray_dir = camera.project_ray_normal(screen_pos)
	var gt = node.global_transform
	var center_global = gt * Vector3(0, node.tamano_trigger.y * 0.5, 0)
	var cam_dir = -camera.global_transform.basis.z.normalized()
	var plane = Plane(cam_dir, center_global)
	var hit = plane.intersects_ray(ray_from, ray_dir)
	if hit == null:
		return
	if absf(gt.basis.determinant()) < 0.0001:
		return
	
	var local_hit = gt.affine_inverse() * hit
	match handle_id:
		0, 1:
			node.tamano_trigger.x = clampf(abs(local_hit.x) * 2.0, 0.5, 100.0)
		2:
			node.tamano_trigger.y = clampf(local_hit.y, 0.5, 50.0)
		3, 4:
			node.tamano_trigger.z = clampf(abs(local_hit.z) * 2.0, 0.2, 50.0)
	
	node.update_gizmos()

func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
	var node = gizmo.get_node_3d()
	if node == null:
		return
	if cancel:
		node.tamano_trigger = restore
		node.update_gizmos()
		return
	
	if Engine.has_singleton("EditorInterface"):
		var ei = Engine.get_singleton("EditorInterface")
		var ur = ei.get_editor_undo_redo()
		if ur:
			ur.create_action("Ajustar tamaño de CameraSwitch")
			ur.add_do_property(node, "tamano_trigger", node.tamano_trigger)
			ur.add_undo_property(node, "tamano_trigger", restore)
			ur.add_do_method(node, "update_gizmos")
			ur.add_undo_method(node, "update_gizmos")
			ur.commit_action()
