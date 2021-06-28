extends Part

class_name MuxBus

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		selected_port = int(input_levels[4]) + 2 * int(input_levels[5])


func set_value(_v: int, _reverse: bool, _from_pin: bool, port := 0):
	if port != selected_port:
		return


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
