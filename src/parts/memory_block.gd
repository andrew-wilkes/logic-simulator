extends Part

class_name MemoryBlock

func erase():
	for idx in data.bytes.size():
		data.bytes[idx] = 0
	memory_data_changed()


func setup():
	data = {
		"memory": MemoryData.new()
	}
	data.memory.set_mem_size(256)
	set_mem_size_label_text()
	value = 0


func loaded_from_file():
	set_mem_size_label_text()


func update_output(level: bool, port: int, _reverse: bool):
		input_pins[port].level = level


func set_value(v: int, _reverse: bool, port := 0):
	if port == 0: # Address
		v %= data.memory.mem_size
		# If the value is unchanged ignore it
		if value == v:
			return
		value = v
	else: # Data
		if input_pins[3].level: # /W
			return
		if data.memory.width == 8:
			v %= 0x100
		if data.memory.bytes[value] == v:
			return
		data.memory.bytes[value] = v


func emit_bus_update():
	emit_signal("bus_changed", self, data.memory.bytes[value], false)


func _on_Button_pressed():
	$MM.open(data.memory)


func memory_data_changed():
	set_mem_size_label_text()
	emit_signal("data_changed")
	emit_bus_update()


func set_mem_size_label_text():
	$Size.text = data.memory.get_mem_size_str() + " x " + String(data.memory.width)
