extends Part

class_name OutputBus

export var num_pins = 8

func set_value(v: int, reverse: bool, _port := 0):
	value = v
	$Bus.update_display_value()
	emit_signal("bus_changed", self, v, false)
	for n in output_pins.size():
		var level = bool(v % 2)
		v /= 2
		if output_pins[n].level != level:
			output_pins[n].level = level
			set_output(level, n, reverse)


func setup():
	var c = Control.new()
	c.rect_min_size.y = 24
	for idx in num_pins:
		add_child(c.duplicate())
	call_deferred("set_slots")


func set_slots():
	var slot = 2
	for idx in num_pins:
		set_slot(slot, false, 0, Color.white, true, 0, Color.white)
