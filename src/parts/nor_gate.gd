extends Part

class_name NorGate

func update_output(level: bool, _port: int, _r: bool):
	level = not (input_pins[0].level or input_pins[1].level)
	set_output(level, 0)
