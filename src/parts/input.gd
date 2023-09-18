extends Part

func _ready():
	is_input = true
	var _e = $Tag.connect("text_changed", self, "text_changed")


func text_changed(_t):
	emit_signal("data_changed")


func set_value(v: int, reverse = false, _port := 0):
	if v == value or reverse:
		return
	value = v
	emit_signal("bus_changed", self, v, reverse)
	for n in output_pins.size() - 1:
		var level = bool(v % 2)
		v /= 2
		set_output(level, n + 1, reverse)


func set_data(d: Dictionary):
	if has_node("Tag") and d.has("tag"):
		data = d
		$Tag.text = d.tag


func get_data():
	return { "tag": $Tag.text }
