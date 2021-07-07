extends MemoryBlock

class_name RomBlock

func setup():
	.setup()
	data.memory.fill() # Add test data


func set_value(v: int, reverse: bool, port := 0):
	.set_value(v, reverse, port)
	if not input_pins[1].level: # /OE
		emit_bus_update()


func update_output(level: bool, port: int, _r: bool):
	if port == 1 and level == false:
		emit_bus_update()
