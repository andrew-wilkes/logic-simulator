extends Part

class_name InputBus

export var num_pins = 8

func update_output(_level: bool, _port: int, rev: bool):
	value = get_value_from_inputs(rev)
	update_display_value()
	emit_signal("bus_changed", self, value, false)


func setup():
	data = { "mode": HEX, "bits": num_bytes / 2 }
	label = $H/Label
	update_display_value()
	var c = Label.new()
	c.valign = Label.VALIGN_CENTER
	c.rect_min_size.y = 24
	for idx in num_pins:
		if idx > 0:
			c.text = "D%d" % idx
			add_child(c.duplicate())
	call_deferred("set_slots")


func set_slots():
	var slot = 1
	for idx in num_pins:
		set_slot(slot, true, 0, Color.white, false, 0, Color.white)
		slot += 1
	set_pins()
