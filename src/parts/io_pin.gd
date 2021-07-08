extends Part

var last_value = 0

func _ready():
	is_input = name == "INPUTPIN"
	data = { "tag": "" }


func set_pin_name(txt):
	$Tag.text = txt
	data.tag = txt


func set_value(v: int, _reverse: bool, _port := 0):
	last_value = value
	value = v
	emit_signal("bus_changed", self, v, false)


func set_data(d: Dictionary):
	data = d
	$Tag.text = d.tag


func get_data():
	return { "tag": $Tag.text }
