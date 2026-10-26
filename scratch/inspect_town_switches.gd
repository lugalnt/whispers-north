@tool
extends SceneTree

func _initialize() -> void:
	print("--- INSPECCIONANDO Y HACIENDO UNICOS LOS SWITCHES DE WORLD_TOWN ---")
	var town_scene: PackedScene = load("res://scenes/world/World_Town.tscn")
	var town = town_scene.instantiate()
	var switches_parent = town.get_node_or_null("Switches")
	assert(switches_parent != null, "Nodo Switches debe existir")
	
	for child in switches_parent.get_children():
		if child is Area3D:
			var col = child.get_node_or_null("CollisionShape3D") as CollisionShape3D
			var tt = child.tamano_trigger if "tamano_trigger" in child else "N/A"
			print("Switch: ", child.name, " | scale: ", child.scale, " | tamano_trigger: ", tt)
			if col and col.shape:
				print("   -> Shape size: ", col.shape.size, " | local_to_scene: ", col.shape.resource_local_to_scene)
	quit(0)
