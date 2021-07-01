extends Part

class_name MultiplexerComb

func update_output(_level: bool, _port: int, _r: bool):
	if input_pins[2].level: # Select
		set_output(input_pins[1].level, 0) # B
	else:
		set_output(input_pins[0].level, 0) # A
