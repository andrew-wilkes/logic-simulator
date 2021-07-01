extends Part

class_name SrffComb

func update_output(_level: bool, _port: int, _r: bool):
	# Init outputs
	if output_pins[0].level == output_pins[1].level:
		set_output(false, 0)
		set_output(true, 1)
	if input_pins[0]: # Set
		set_output(not input_pins[1].level, 0)
		set_output(false, 1)
	else:
		if input_pins[1].level: # Reset
			set_output(false, 0)
			set_output(not input_pins[0].level, 1)
