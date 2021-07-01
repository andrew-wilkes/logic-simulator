extends Part

class_name JoinBus

func set_value(v: int, _reverse: bool, _port := 0):
	value = v
	update_display_value()
	emit_signal("bus_changed", self, v, false)


func _on_Button_pressed():
	data.mode += 1
	data.mode %= 3
	update_display_value()
	emit_signal("data_changed")
