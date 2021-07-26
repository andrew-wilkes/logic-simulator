extends Part

class_name AluBlock

func setup():
	.setup()
	data = {
		"mode": HEX,
		"bits": 1,
	}


func update_output(_level: bool, _port: int, _r: bool):
	# Decide function
	var f = int(input_pins[4].level)
	f = 2 * f + int(input_pins[3].level)
	f = 2 * f + int(input_pins[2].level)
	a %= maxvs[data.bits]
	b %= maxvs[data.bits]
	var v = a
	var msb1 = v >= msbs[data.bits]
	match f:
		1:
			v = b
		2:
			v += 1
		3:
			v = b + 1
		4:
			v += b
		5:
			if b > 0:
				v -= b # maxvs[data.bits] - b # Invert b and add 1
		6:
			v &= b
		7:
			v |= b
	set_output(v >= maxvs[data.bits], 1) # Cout
	v %= maxvs[data.bits]
	var msb2 = v >= msbs[data.bits]
	set_output(v == 0, 2) # Zero
	var of = false
	match f:
		2,3,4:
			of = msb2 > msb1
		5:
			of = msb2 < msb1
	set_output(of, 3) # OF
	set_output(msb2, 4) # Sign
	output_value(v)


func set_value(v: int, _r: bool, port := 0):
		if port == 0:
			if v != a:
				a = v
				update_output(true, -1, false)
			return
		if port == 1:
			if v != b:
				b = v
				update_output(true, -1, false)
			return


func output_value(v: int):
	value = v
	update_display_value()
	emit_signal("bus_changed", self, value, false)


func _on_Bits_was_pressed(button):
	change_bit_depth(button)


func _on_Bits_button_timer_timeout(button):
	change_button(button)


func apply_data():
	change_bit_depth($HBox5/Bits, 0)
	change_button($HBox5/Bits)
