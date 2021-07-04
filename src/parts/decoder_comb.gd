extends Part

class_name DecoderComb

func update_output(_level: bool, _port: int, _r: bool):
	set_value(get_value_from_inputs(false), false)


func set_value(v: int, _reverse: bool, port := 0):
	if port != 0:
		return
	value = v
	match input_pins.size():
		3:
			v %= 4
		4:
			v %= 8
		5:
			v %= 16
	for n in output_pins.size():
		var level = n == v
		output_pins[n].level = level
		set_output(level, n)


func get_data():
	return data


func set_data(d):
	data = d


var num_to_add = 4

func _on_Bits_was_pressed(b):
	add_slots(num_to_add)
	num_to_add += 4
	if num_to_add < 9:
		b.start_timer()
	else:
		b.hide()


func _on_Bits_button_timer_timeout(b):
	b.hide()


func add_slots(_n):
	var yn = 4 if _n == 4 else 8
	var input_pin = Pin.new()
	if _n == 4:
		input_pin.slot = 3
	else:
		input_pin.slot = 4
	input_pins.append(input_pin)
	get_child(input_pin.slot + 1).get_child(0).text = "A" + String(input_pin.slot)
	set_slot(input_pin.slot, true, 0, Color.white, true, 0, Color.white)
	var c = get_child(5).duplicate()
	c.get_child(0).text = ""
	for n in _n:
		c.get_child(1).text = "Y" + String(yn)
		add_child(c.duplicate())
		yn += 1
		set_slot(yn, false, 0, Color.white, true, 0, Color.white)
		var output_pin = Pin.new()
		output_pin.slot = yn
		output_pins.append(output_pin)


func setup():
	set_pins()
	get_child(1).get_child(1).call_deferred("start_timer")
