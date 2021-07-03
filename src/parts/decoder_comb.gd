extends Part

class_name DecoderComb

func update_output(_level: bool, _port: int, _r: bool):
	set_value(get_value_from_inputs(false), false)


func set_value(v: int, _reverse: bool, port := 0):
	if value == v or port > 0:
		return
	value = v
	match input_pins.size():
		3:
			v %= 4
		4:
			v %= 8
		5:
			v %= 16
	for n in output_pins.size():
		var level = n == v
		output_pins[n].level = level
		set_output(level, n)


func get_data():
	return data


func set_data(d):
	data = d
