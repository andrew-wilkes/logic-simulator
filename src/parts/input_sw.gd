extends Part

class_name InputSwitch

func _ready():
	is_input = true
	is_reversible_input = true
	var _e = $Tag.connect("text_changed", self, "text_changed")


func setup():
	set_pins()
	var button = get_child(0)
	button.focus_mode = Control.FOCUS_NONE
	set_io(button.pressed, 0, 0)
	if button.toggle_mode:
		button.connect("toggled", self, "set_io", [0, 0])
	else:
		button.connect("button_down", self, "set_io", [true, 0, 0])
		button.connect("button_up", self, "set_io", [false, 0, 0])


func set_io(level: bool, _in_port: int, out_port: int):
	set_output(level, out_port)


func set_data(d: Dictionary):
	if has_node("Tag") and d.has("tag"):
		data = d
		$Tag.text = d.tag


func get_data():
	return { "tag": $Tag.text }


func text_changed(_t):
	emit_signal("data_changed")
