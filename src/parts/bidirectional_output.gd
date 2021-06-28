extends Part

class_name BiOutput

func update_output(level: bool, _port: int,_reverse: bool):
	$Label.text = String(int(level))


func set_port_maps():
	in_port_map = [0]
	out_port_map = [0]
	out_port_mode = [PIN_MODE.INPUT]
