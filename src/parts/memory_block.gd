extends Part

class_name MemoryBlock

func erase():
	data.memory.erase()
	memory_data_changed()


func setup():
	set_pins()
	data = {
		"memory": MemoryData.new()
	}
	data.memory.set_mem_size(256)
	set_mem_size_label_text()
	value = 0


func loaded_from_file():
	set_mem_size_label_text()


func set_value(v: int, _reverse: bool, port := 0):
	if port == 0: # Address
		v %= data.memory.mem_size
		value = v


func emit_bus_update():
	# Emit 16 bits or 8 bits of data
	emit_signal("bus_changed", self, data.memory.words[value], false)


func _on_Button_pressed():
	$MM.open(data.memory)


func memory_data_changed():
	set_mem_size_label_text()
	emit_signal("data_changed")
	emit_bus_update()


func set_mem_size_label_text():
	$Size.text = data.memory.get_mem_size_str() + " x " + String(data.memory.width)
