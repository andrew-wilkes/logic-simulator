extends Part

class_name LoopBus

func set_value(v: int, reverse: bool, _port := 0):
	if v != value: # Prevent stack overflow
		value = v
		update_display_value()
		emit_signal("bus_changed", self, v, not reverse)


func setup():
	.setup()
	data = {
		"mode": HEX,
		"bits": 2,
	}
	format = "0x%02X"
