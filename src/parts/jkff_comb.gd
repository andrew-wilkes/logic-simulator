extends Part

class_name JkffComb

func update_output(_level: bool, _port: int, _r: bool):
	# Init outputs
	if untouched:
		untouched = false
		set_output(false, 0)
		set_output(true, 1)
	# Detect rising edge of CK
	if input_pins[1].level and not input_pins[1].last_level:
		input_pins[1].last_level = true
		if input_pins[0].level and input_pins[2].level: # Toggle
			set_output(not output_pins[0].level, 0)
			set_output(not output_pins[1].level, 1)
		else:
			if input_pins[0].level: # Set
				set_output(true, 0)
				set_output(false, 1)
			if input_pins[2].level: # Reset
				set_output(true, 1)
				set_output(false, 0)
