extends BUS

func setup():
	set_port_maps()
	data = { "memory": [0] }


func set_value(addr: int, reverse: bool, _from_pin: bool, _port := 0):
	# If the value is unchanged ignore it
	if value == addr:
		return
	value = addr
	
	addr %= data.memory.size()
	
	emit_signal("bus_changed", self, data.memory[addr], reverse)
