extends Part

func set_value(v: int, _r: bool, _p := 0):
	value = v
	show_value()


func update_output(_level: bool, _port: int, _r: bool):
	value = get_value_from_inputs(false)
	show_value()


func show_value():
	get_child(0).text = "0x%02X" % value
