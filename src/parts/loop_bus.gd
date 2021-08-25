# Only used to connect to joinbus, display or itself
extends Part

class_name LoopBus

func set_value(v: int, reverse: bool, port := 0):
	if v != value: # Prevent stack overflow
		value = v
		update_display_value()
		# Reverse and flip port
		emit_signal("bus_changed", self, v, not reverse, int(not bool(port)))


func setup():
	.setup()
	data = {
		"mode": HEX,
		"bits": 2,
	}
	format = "0x%02X"
	label = $Label
