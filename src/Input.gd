tool
extends Part

func set_value(value: int, reverse = false, _from_pin = false):
	get_child(0).text = "0x%02X" % value
	emit_signal("bus_changed", self, value, reverse)
	var num_bits = 4 if type == Parts.INPUT4 else 8
	for n in num_bits:
		var level = bool(value % 2)
		value /= 2
		set_output(level, n + 1, reverse)
