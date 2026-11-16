extends RefCounted
## Etiquetas de presentación; los bindings siguen definidos en el Input Map.
static var ultimo_mando := -1

static func registrar(evento: InputEvent) -> void:
	if evento is InputEventJoypadButton or (evento is InputEventJoypadMotion and absf(evento.axis_value) > 0.3):
		ultimo_mando = evento.device

static func familia(nombre: String) -> String:
	var n := nombre.to_lower()
	if "sony" in n or "playstation" in n or "dualshock" in n or "dualsense" in n or "ps4" in n or "ps5" in n: return "ps"
	if "nintendo" in n or "switch" in n or "joy-con" in n: return "switch"
	return "xbox"

static func familia_actual() -> String:
	var conectados := Input.get_connected_joypads()
	var id := ultimo_mando if conectados.has(ultimo_mando) else (conectados[0] if not conectados.is_empty() else -1)
	return familia(Input.get_joy_name(id)) if id >= 0 else "xbox"

static func boton(indice: int, tipo: String) -> String:
	var nombres := ["A", "B", "X", "Y", "View", "Xbox", "Menu", "LS", "RS", "LB", "RB", "↑", "↓", "←", "→"]
	if tipo == "ps": nombres = ["✕", "○", "□", "△", "Share", "PS", "Options", "L3", "R3", "L1", "R1", "↑", "↓", "←", "→"]
	elif tipo == "switch": nombres = ["B", "A", "Y", "X", "−", "Home", "+", "LS", "RS", "L", "R", "↑", "↓", "←", "→"]
	return nombres[indice] if indice >= 0 and indice < nombres.size() else "Botón %d" % (indice + 1)

static func accion(nombre: StringName, mando: bool) -> String:
	for evento in InputMap.action_get_events(nombre):
		if mando == (evento is InputEventJoypadButton or evento is InputEventJoypadMotion):
			return evento_texto(evento)
	return "Sin asignar"

static func evento_texto(evento: InputEvent) -> String:
	if evento is InputEventJoypadButton:
		return boton(evento.button_index, familia_actual())
	if evento is InputEventJoypadMotion:
		if evento.axis < 4:
			var flecha := ("←" if evento.axis_value < 0 else "→") if evento.axis % 2 == 0 else ("↑" if evento.axis_value < 0 else "↓")
			return ("Stick izq. " if evento.axis < 2 else "Stick der. ") + flecha
		var tipo := familia_actual()
		return ("L2" if evento.axis == 4 else "R2") if tipo == "ps" else (("ZL" if evento.axis == 4 else "ZR") if tipo == "switch" else ("LT" if evento.axis == 4 else "RT"))
	return evento.as_text().replace(" (Physical)", "").replace(" - Physical", "")
