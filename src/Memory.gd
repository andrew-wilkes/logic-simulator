extends BUS

func erase():
	for idx in data.bytes.size():
		data.bytes[idx] = 0
	memory_data_changed()


func setup():
	set_port_maps()
	data = {
		"memory": MemoryData.new()
	}
	data.memory.set_mem_size(256)
	set_mem_size_label_text()


func loaded_from_file():
	set_mem_size_label_text()


func set_value(v: int, _reverse: bool, _from_pin: bool, port := 0):
	if port == 1: # Address
		v %= data.memory.mem_size
		# If the value is unchanged ignore it
		if value == v:
			return
		value = v
	else: # Data
		if data.memory.width == 8:
			v %= 0x100
		if data.memory.bytes[value] == v:
			return
		data.memory.bytes[value] = v
	emit_bus_update()


func emit_bus_update():
	var addr = value if value >= 0 else 0
	emit_signal("bus_changed", self, data.memory.bytes[addr], false)


func _on_Button_pressed():
	$MM.open(data.memory)


func memory_data_changed():
	set_mem_size_label_text()
	emit_signal("data_changed")
	emit_bus_update()


func set_mem_size_label_text():
	$Size.text = data.memory.get_mem_size_str() + " x " + String(data.memory.width)
