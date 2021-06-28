extends Part

class_name XorGate

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		level = (not input_levels[0] and input_levels[1]) or (input_levels[0] and not input_levels[1])
		set_output(level, 0)


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
