extends Part

func set_value(value: int, reverse = false, _from_pin = false, _port := 0):
	set_text(value)
	emit_signal("bus_changed", self, value, reverse)
	var num_bits = 4 if type == Parts.TYPES.INPUT4 else 8
	for n in num_bits:
		var level = bool(value % 2)
		value /= 2
		set_output(level, n + 1, reverse)


func set_text(value):
	get_child(0).text = "0x%02X" % value


var vs

func _on_VSlider_value_changed(value):
	vs = int(value)
	set_text(vs)
	$Timer.start()


func _on_Timer_timeout():
	set_value(vs)
