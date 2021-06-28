extends Part

class_name SingleOutput

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		set_output(level, port, reverse)


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
