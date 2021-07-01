extends Part

var last_value = 0

func set_value(v: int, reverse = false, from_pin = false, _port := 0):
	if from_pin:
		v = get_value_from_inputs(reverse)
	if value == v:
		return
	value = v
	get_child(0).text = "0x%02X" % value
	if reverse:
		emit_signal("bus_changed", self, value, reverse)
	else:
		for n in output_pins.size():
			var level = bool(v % 2)
			v /= 2
			if output_pins[n].level != level:
				output_pins[n].level = level
				set_output(level, n, reverse)


func get_value():
	if value < 0:
		value = 0
	last_value = value
	return value


func get_pin_name():
	return get_node("Pin").text


func set_pin_name(txt):
	if txt is String:
		get_node("Pin").text = txt
