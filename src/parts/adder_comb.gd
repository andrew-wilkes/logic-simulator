extends Part

class_name AdderComb

func update_output(_level: bool, _port: int, _r: bool):
	# Init outputs
	if output_pins[0].level == output_pins[1].level:
		set_output(false, 0)
		set_output(true, 1)
	var sum: int = int(input_pins[0].level) + int(input_pins[1].level) + int(input_pins[2].level)
	set_output(bool(sum % 2), 0) # Sum
# warning-ignore:integer_division
	set_output(bool(sum / 2), 1) # Cout
