extends Part

class_name DffComb

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		# Init outputs
		if output_levels.size() == 0:
			output_levels = { 0: false }
			set_output(false, 0)
		if input_levels[0]: # Set
			set_output(true, 0)
		else:
			if input_levels[3]: # Reset
				set_output(false, 0)
			else:
				# Detect rising edge of CK
				if input_levels[2] and not last_input_levels[2]:
					set_output(input_levels[1], 0)
				last_input_levels[2] = input_levels[2]


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
