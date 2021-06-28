extends Part

class_name DecoderComb

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		set_output(level, 0)

func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]

var num_outputs = [4, 8, 16]

func setup():
	bit_lengths = [2, 3, 4]
	set_port_maps()


func add_slots():
	var slot = get_child_count() - 2
	var temp = get_child(2)
	for n in [0, 4, 8][bits]:
		var node = temp.duplicate()
		node.get_child(0).text = ""
		node.get_child(1).text = "Y" + String(slot - 1)
		add_child(node)
		set_slot(slot, false, 0, Color.white, true, 0, Color.white)
		out_port_map.append(slot)
		out_port_mode.append(PIN_MODE.OUTPUT)
		slot += 1
	get_child(bits + 3).get_child(0).text = "A" + String(bits + 1)
	set_slot(bits + 2, true, 0, Color.white, true, 0, Color.white)
	in_port_map.append(bits + 2)
	in_port_mode.append(PIN_MODE.INPUT)
	data = { "bits": 0 }


func set_value(v: int, reverse: bool, _from_pin: bool, _port := 0):
	if _from_pin:
		v = get_value_from_inputs(reverse)
	if value == v:
		return
	match bits:
		0:
			v %= 4
		1:
			v %= 8
		2:
			v %= 16
	for n in num_outputs[bits]:
		var level = n == v
		output_levels[n] = level
		set_output(level, n)


func _on_Bits_button_down():
	if data.bits < 2:
		data.bits += 1
		add_slots()
		if data.bits == 2:
			$Bits.hide()
		else:
			$Timer.start()


func _on_Timer_timeout():
	$Bits.hide()


func dropped():
	$Timer.start()


func get_data():
	return data


func set_data(d):
	data = d
