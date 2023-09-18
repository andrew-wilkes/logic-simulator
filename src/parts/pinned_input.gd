extends Part

func set_value(v: int, reverse = false, port := 0):
	if port > 0:
		v = get_value_from_inputs(reverse)
	if value == v:
		return
	value = v
	get_child(0).text = "0x%02X" % value
	if reverse:
		emit_signal("bus_changed", self, value, reverse)
	else:
		for n in bit_lengths[data.bits]:
			var level = bool(v % 2)
			v /= 2
			if output_pins[n] != level:
				output_pins[n] = level
				set_output(level, n, reverse)


func get_value():
	if value < 0:
		value = 0
	last_value = value
	return value
