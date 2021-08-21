extends MemoryBlock

class_name RamBlock

func setup():
	.setup()
	data.memory.ram = true
	preset_input(false, 2)


func set_value(v: int, reverse: bool, port := 0):
	.set_value(v, reverse, port)
	if port == 1: # Data
		a = v # Store data bus input value in a
		if input_pins[3].level: # /W
			return
		if data.memory.width == 8:
			v %= 0x100
		data.memory.words[value] = v
	if not input_pins[2].level: # /OE
		emit_bus_update()


func update_output(level: bool, port: int, _r: bool):
	if port == 2 and level == false:
		emit_bus_update()


func apply_data():
	var _e = data.memory.erase()


func memory_data_changed():
	set_mem_size_label_text()
	if not input_pins[2].level: # /OE
		emit_bus_update()
