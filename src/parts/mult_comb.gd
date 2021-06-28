extends Part

class_name MultiplexerComb

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		if input_levels[2]: # Select
			set_output(input_levels[1], 0) # B
		else:
			set_output(input_levels[0], 0) # A


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
