extends Part

var last_value = 0

func get_pin_name():
	return get_node("Pin").text


func set_pin_name(txt):
	if txt is String:
		get_node("Pin").text = txt