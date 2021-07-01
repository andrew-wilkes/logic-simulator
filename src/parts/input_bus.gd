extends Part

class_name InputBus

export var num_pins = 8

func update_output(_level: bool, _port: int, rev: bool):
	value = get_value_from_inputs(rev)
	update_value(value)


func set_value(v: int, _reverse: bool, _port := 0):
	value = v
	update_value(v)


func update_value(v: int):
	$Bus.update_display_value(v)
	emit_signal("bus_changed", self, v, false)


func setup():
	var c = Control.new()
	c.rect_min_size.y = 24
	for idx in num_pins:
		add_child(c.duplicate())
	call_deferred("set_slots")


func set_slots():
	var slot = 2
	for idx in num_pins:
		set_slot(slot, true, 0, Color.white, false, 0, Color.white)
