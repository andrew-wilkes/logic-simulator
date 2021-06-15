extends Part

func setup():
	set_port_maps()


func add_slots():
	var slot = get_child_count() - 1
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


func set_value(v: int, reverse: bool, _from_pin: bool):
	if _from_pin:
		v = get_value_from_inputs(reverse)
	if value == v:
		return
	value = v
	for n in bit_lengths[bits]:
		var level = n == v
		output_levels[n] = level
		set_output(level, n)


func _on_Bits_button_down():
	if bits < 2:
		bits += 1
		add_slots()
		depth = bits
		if bits == 2:
			$Bits.hide()
		else:
			$Timer.start()


func _on_Timer_timeout():
	$Bits.hide()


func dropped():
	$Timer.start()
