extends Part

func set_value(v: int, reverse = false, from_pin = false):
	if type == Parts.OUTPUTPIN:
		value = v
		return
	if from_pin:
		bits = int(type == Parts.OUTPUT8)
		v = get_value_from_inputs(reverse)
	if value == v:
		return
	value = v
	get_child(0).text = "0x%02X" % value
	emit_signal("bus_changed", self, value, reverse)
