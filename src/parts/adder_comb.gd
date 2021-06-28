extends Part

class_name AdderComb

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		# Init outputs
		if output_levels.size() == 0:
			output_levels = { 0: false, 1: false }
			set_output(false, 0)
			set_output(false, 1)
		var sum: int = int(input_levels[0]) + int(input_levels[1]) + int(input_levels[2])
		set_output(bool(sum % 2), 0) # Sum
# warning-ignore:integer_division
		set_output(bool(sum / 2), 1) # Cout


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
