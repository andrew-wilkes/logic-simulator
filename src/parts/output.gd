extends Part

func _ready():
	var _e = $Tag.connect("text_changed", self, "text_changed")


func text_changed(_t):
	emit_signal("data_changed")


func update_output(_level: bool, _port: int, _r: bool):
	value = get_value_from_inputs(false, 0)
	show_value()


func show_value():
	$H/Value.text = "0x%02X" % value


func set_data(d: Dictionary):
	if has_node("Tag") and d.has("tag"):
		data = d
		$Tag.text = d.tag


func get_data():
	return { "tag": $Tag.text }


func set_value(v: int, reverse = false, _port := 0):
	if v == value or reverse:
		return
	value = v
	show_value()
	emit_signal("bus_changed", self, v, reverse)
	for n in output_pins.size() - 1:
		var level = bool(v % 2)
		v /= 2
		set_output(level, n + 1, reverse)
