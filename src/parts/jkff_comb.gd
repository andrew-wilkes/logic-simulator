extends Part

class_name JkffComb

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		# Init outputs
		if output_levels.size() == 0:
			output_levels = { 0: false, 1: true }
			set_output(false, 0)
			set_output(true, 1)
		# Detect not rising edge of CK
		if not input_levels[1] or last_input_levels[1]:
			return
		last_input_levels[1] = input_levels[1]
		if input_levels[0] and input_levels[2]: # Toggle
			set_output(not output_levels[0], 0)
			set_output(not output_levels[1], 1)
		else:
			if input_levels[0]: # Set
				set_output(true, 0)
				set_output(false, 1)
			if input_levels[2]: # Reset
				set_output(true, 1)
				set_output(false, 0)


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
