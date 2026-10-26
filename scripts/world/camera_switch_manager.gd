@tool
class_name CameraSwitchManager
extends Node3D

## Administrador y generador de switches de cámara en el mundo.
## Permite generar, alinear y organizar rápidamente los CameraSwitch entre cámaras numeradas.

@export_group("Generación Rápida")
## Par de cámaras a conectar (X = Cámara A, Y = Cámara B). Ej: Vector2i(1, 2)
@export var nuevo_switch_par: Vector2i = Vector2i(1, 2)

## Activa esta casilla para crear instantáneamente un CameraSwitch entre el par seleccionado.
@export var crear_switch_ahora: bool = false:
	set(val):
		if val and Engine.is_editor_hint():
			crear_switch(nuevo_switch_par.x, nuevo_switch_par.y)
		crear_switch_ahora = false

## Lista de pares para generar en lote. Ej: [Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4)]
@export var lista_pares_lote: Array[Vector2i] = []

## Activa esta casilla para generar todos los switches de la lista de lote de una sola vez.
@export var generar_lote_completo: bool = false:
	set(val):
		if val and Engine.is_editor_hint():
			generar_lote()
		generar_lote_completo = false

@export_group("Configuración en Juego")
## Cámara con la que iniciará el mapa al cargar. Si es 1, activará Camera1.
@export var camara_inicial_num: int = 1

const PREFAB_SWITCH = preload("res://scenes/world/Entities/CameraSwitch.tscn")

func _ready() -> void:
	if not Engine.is_editor_hint():
		call_deferred("_activar_camara_inicial")

func _activar_camara_inicial() -> void:
	if camara_inicial_num <= 0:
		return
	var cam_name = "Camera%d" % camara_inicial_num
	var root = get_tree().current_scene if get_tree() else owner
	if root == null:
		return
	
	var cam: Camera3D = root.get_node_or_null("Cameras/" + cam_name)
	if cam == null:
		cam = root.get_node_or_null(cam_name)
	if cam == null:
		cam = root.find_child(cam_name, true, false) as Camera3D
	
	if cam:
		cam.make_current()

## Crea y configura un switch entre cam_a y cam_b colocado a mitad de camino y orientado
func crear_switch(a_num: int, b_num: int) -> Area3D:
	var switch_nombre = "Switch_%d_%d" % [a_num, b_num]
	if has_node(switch_nombre):
		push_warning("[CameraSwitchManager] Ya existe un switch llamado %s" % switch_nombre)
		return get_node(switch_nombre) as Area3D
	
	var switch_inst = PREFAB_SWITCH.instantiate()
	switch_inst.name = switch_nombre
	switch_inst.camara_a_num = a_num
	switch_inst.camara_b_num = b_num
	add_child(switch_inst)
	
	# Establecer propietario para que se guarde en la escena en el editor de Godot
	var escena_root = get_tree().edited_scene_root if (Engine.is_editor_hint() and get_tree()) else owner
	if escena_root:
		switch_inst.owner = escena_root
	
	# Auto-centrar y alinear entre las cámaras
	switch_inst._auto_centrar_entre_camaras()
	switch_inst._auto_alinear_con_camaras()
	switch_inst._actualizar_etiqueta_editor()
	switch_inst._actualizar_volumen_editor()
	
	print("[CameraSwitchManager] Switch creado exitosamente: %s" % switch_nombre)
	return switch_inst

## Genera todos los switches definidos en 'lista_pares_lote'
func generar_lote() -> void:
	if lista_pares_lote.is_empty():
		push_warning("[CameraSwitchManager] La lista de lote está vacía. Añade pares Vector2i(A, B).")
		return
	
	for par in lista_pares_lote:
		crear_switch(par.x, par.y)
