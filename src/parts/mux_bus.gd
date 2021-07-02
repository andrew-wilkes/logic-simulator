extends Part

class_name MuxBus

func update_output(_level: bool, _port: int, _r: bool):
	selected_port = int(input_pins[4].level) + 2 * int(input_pins[5].level)
	set_bus_pin_colors()


func set_value(v: int, _reverse: bool, port := 0):
	if port != selected_port:
		return
	value = v
	set_text()
	emit_signal("bus_changed", self, v, false)


func set_text():
	$Label.text = "0x%04X" % value


func setup():
	.setup()
	set_text()
	set_bus_pin_colors()


func set_bus_pin_colors():
	for idx in 4:
		var col = Color.yellow if idx != selected_port else Color.green
		set("slot/%d/left_color" % input_pins[idx].slot, col)
