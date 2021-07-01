extends Part

var last_value = 0

func set_value(v: int, _reverse = false, _port := 0):
	value = v


func get_value():
	if value < 0:
		value = 0
	last_value = value
	return value


func set_data(d):
	set_pin_name(d.pin_name)


func get_data():
	return { "pin_name": get_pin_name() }


func get_pin_name():
	return get_node("Pin").text


func set_pin_name(txt):
	if txt is String:
		get_node("Pin").text = txt
