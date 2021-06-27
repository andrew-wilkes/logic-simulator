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


func set_value(addr: int, reverse: bool, _from_pin: bool, _port := 0):
	# If the value is unchanged ignore it
	if value == addr:
		return
	value = addr
	
	addr %= data.mem_size
	
	emit_signal("bus_changed", self, data.bytes[addr], reverse)


func _on_Button_pressed():
	$MM.open(data.memory)


func memory_data_changed():
	set_mem_size_label_text()
	emit_signal("data_changed")


func set_mem_size_label_text():
	$Size.text = data.memory.get_mem_size_str() + " x " + String(data.memory.width)
