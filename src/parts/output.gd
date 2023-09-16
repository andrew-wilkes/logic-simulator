extends Part

func _ready():
	var _e = $Tag.connect("text_changed", self, "text_changed")


func text_changed(_t):
	emit_signal("data_changed")


func update_output(_level: bool, _port: int, _r: bool):
	value = get_value_from_inputs(false)
	show_value()


func show_value():
	$H/V.text = "0x%02X" % value


func set_data(d: Dictionary):
	if has_node("Tag") and d.has("tag"):
		data = d
		$Tag.text = d.tag


func get_data():
	return { "tag": $Tag.text }
