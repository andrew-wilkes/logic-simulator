extends Part

class_name NandGate

func update_output(level: bool, _port: int, _r: bool):
	level = not (input_pins[0].level and input_pins[1].level)
	set_output(level, 0)
