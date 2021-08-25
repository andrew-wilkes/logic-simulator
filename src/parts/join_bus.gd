extends Part

class_name JoinBus

func setup():
	.setup()
	data = {
		"mode": HEX,
		"bits": 2,
	}
	label = $Label
	apply_data()


func apply_data():
	update_display_value()


func set_value(v: int, reverse: bool, _port := 0):
	value = v
	update_display_value()
	emit_signal("bus_changed", self, v, reverse)


func _on_EmitButton_button_timer_timeout(b):
	change_button(b)


func _on_EmitButton_was_pressed(b):
	handle_button_press(b)
