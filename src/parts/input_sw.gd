extends Part

class_name InputSwitch

func _ready():
	is_input = true
	is_reversible_input = true


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


# Input pin and output pin used as outputs
func set_io(level: bool, in_port: int, out_port: int):
	set_output(level, out_port)
	set_output(level, in_port, true)
