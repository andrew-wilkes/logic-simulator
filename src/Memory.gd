extends BUS

const mem_sizes = {
	32: "32",
	64: "64",
	128: "128",
	256: "256",
	512: "512",
	1024: "1K",
	2048: "2K",
	4096: "4K",
	8192: "8K"
}

func set_mem_size(idx):
	data.bytes.resize(get_mem_size(idx))
	erase()


func erase():
	for idx in data.bytes.size():
		data.bytes[idx] = 0


func get_mem_size(idx):
	return mem_sizes.keys()[idx]


func get_mem_size_str():
	return mem_sizes[data.bytes.size()]


func setup():
	set_port_maps()
	data = {
		"memory": MemoryData.new()
	}


func set_value(addr: int, reverse: bool, _from_pin: bool, _port := 0):
	# If the value is unchanged ignore it
	if value == addr:
		return
	value = addr
	
	addr %= data.mem_size
	
	emit_signal("bus_changed", self, data.bytes[addr], reverse)


func _on_Button_pressed():
	if data.memory.bytes.size() < 1:
		data.memory.set_mem_size(256)
	$MM.open(data.memory)


func memory_data_changed():
	emit_signal("data_changed")
