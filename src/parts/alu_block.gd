extends Part

class_name AluBlock

func update_output(_level: bool, port: int, _r: bool):
	var bits = 8
	if port < 0: # a or b changed. Ensure that dummy pin is not ignored.
		_r = input_pins.erase(port)
	# Decide function
	var f = int(input_pins[4].level)
	f = 2 * f + int(input_pins[3].level)
	f = 2 * f + int(input_pins[2].level)
	a %= maxvs[bits]
	b %= maxvs[bits]
	var v = a
	var msb1 = v >= msbs[bits]
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
				v = v + maxvs[bits] - b # Invert b and add 1
		6:
			v &= b
		7:
			v |= b
	var msb2 = v >= msbs[bits]
	set_output(v >= maxvs[bits], 1) # Cout
	set_output(v == 0, 2) # Zero
	set_output(msb1 != msb2, 3) # OF
	set_output(msb2, 4) # Sign
	set_value(v % maxvs[bits], false, -1)


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


func _on_Bits_was_pressed(button):
	change_bit_depth(button)


func _on_Bits_button_timer_timeout(button):
	change_button(button)
