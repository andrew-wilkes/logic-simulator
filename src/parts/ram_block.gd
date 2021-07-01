extends MemoryBlock

class_name RamBlock

func set_value(v: int, reverse: bool, port := 0):
	.set_value(v, reverse, port)
	if not input_pins[2].level: # /OE
		emit_bus_update()
