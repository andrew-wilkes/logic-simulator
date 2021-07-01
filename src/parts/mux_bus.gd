extends Part

class_name MuxBus

func update_output(_level: bool, _port: int, _r: bool):
	selected_port = int(input_pins[4].level) + 2 * int(input_pins[5].level)


func set_value(v: int, _reverse: bool, port := 0):
	if port != selected_port or value == v:
		return
	value = v
	emit_signal("bus_changed", self, v, false)
