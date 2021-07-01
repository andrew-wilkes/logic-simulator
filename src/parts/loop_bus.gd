extends Part

class_name LoopBus

func set_value(v: int, reverse: bool, _port := 0):
	value = v
	emit_signal("bus_changed", self, v, not reverse)
