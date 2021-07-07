extends Part

var last_value = 0
var pin_name = ""

func _ready():
	is_input = name == "INPUTPIN"

func get_pin_name():
	return pin_name


func set_pin_name(txt):
	if txt is String:
		get_node("Pin").text = txt.capitalize()
		pin_name = txt


func set_value(v: int, _reverse: bool, _port := 0):
	last_value = value
	value = v
	emit_signal("bus_changed", self, v, false)
