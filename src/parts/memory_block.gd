extends Part

class_name MemoryBlock

func setup():
	set_pins()
	data = {
		"memory": MemoryData.new()
	}
	data.memory.set_mem_size(256)
	set_mem_size_label_text()
	value = 0
	data.memory.erase()


func loaded_from_file():
	set_mem_size_label_text()


func set_value(v: int, _reverse: bool, port := 0):
	if port == 0: # Address
		v %= data.memory.mem_size
		value = v


func emit_bus_update():
	# Emit 16 bits or 8 bits of data
	var v = data.memory.words[value]
	emit_signal("bus_changed", self, v, false)


func _on_Button_pressed():
	$MM.open(data.memory)


func set_mem_size_label_text():
	$Size.text = data.memory.get_mem_size_str() + " x " + String(data.memory.width)
