extends Part

class_name DlatchComb

func update_output(level: bool, _port: int, _r: bool):
	# Init outputs
	if output_pins[0].level == output_pins[1].level:
		set_output(false, 0)
		set_output(true, 1)
	if input_pins[0].level: # Enable
		set_output(input_pins[1].level, 0)
		set_output(not input_pins[1].level, 1)
	set_output(level, 0)
