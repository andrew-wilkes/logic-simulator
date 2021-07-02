extends Part

var last_value = 0

func set_value(v: int, reverse = false, port := 0):
	if port > 0:
		return # Let the pin update set the value
	if value == v:
		return
	value = v
	set_display_value()
	if reverse:
		emit_signal("bus_changed", self, value, reverse)
	else:
		for n in output_pins.size():
			var level = bool(v % 2)
			v /= 2
			if output_pins[n].level != level:
				output_pins[n].level = level
				set_output(level, n, reverse)


func get_value():
	if value < 0:
		value = 0
	last_value = value
	return value


func get_pin_name():
	return get_node("Pin").text


func set_pin_name(txt):
	if txt is String:
		get_node("Pin").text = txt


func update_output(_level, _port, _reverse):
	pass
	#value = get_value_from_inputs(false)
	#set_display_value()


func set_display_value():
	get_child(0).text = "0x%02X" % value
