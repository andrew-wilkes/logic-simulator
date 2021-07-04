extends Part

class_name OutputBus

var num_pins = 8

func _ready():
	if name == "OUTBUS16":
		num_bytes = 4
		num_pins = 16


func set_value(v: int, reverse: bool, port := 0):
	if port != 0:
		return
	value = v
	update_display_value()
	emit_signal("bus_changed", self, v, false)
	for n in output_pins.size():
		if n > 0: # Skip bus pin
			var level = bool(v % 2)
			v /= 2
			if output_pins[n].level != level or output_pins[n].count == 0:
				output_pins[n].level = level
				set_output(level, n, reverse)


func setup():
	data = { "mode": HEX, "bits": num_bytes / 2 }
	set_format()
	update_display_value()
	var c = Label.new()
	c.valign = Label.VALIGN_CENTER
	c.align = Label.ALIGN_RIGHT
	c.size_flags_horizontal = SIZE_EXPAND_FILL
	c.rect_min_size.y = 24
	for idx in num_pins:
		c.text = "D%d" % idx
		add_child(c.duplicate())
	call_deferred("set_slots")


func set_slots():
	var slot = 1
	for idx in num_pins:
		set_slot(slot, false, 0, Color.white, true, 0, Color.white)
		slot += 1
	set_pins()
