extends Part

class_name NotGate

func update_output(level: bool, _port: int, _r: bool):
	level = !level
	set_output(level, 0)
