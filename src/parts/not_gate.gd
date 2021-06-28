extends Part

class_name NotGate

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		level = !level
		set_output(level, 0)

func set_port_maps():
	in_port_map = [0]
	out_port_map = [0]
