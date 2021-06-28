extends Part

class_name DlatchComb

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		# Init outputs
		if output_levels.size() == 0:
			output_levels = { 0: false, 1: true }
			set_output(false, 0)
			set_output(true, 1)
		if input_levels[0]: # Enable
			set_output(input_levels[1], 0)
			set_output(not input_levels[1], 1)
		set_output(level, 0)


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
