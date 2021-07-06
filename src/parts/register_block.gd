extends Part

class_name RegisterBlock

func setup():
	.setup()
	data = {
		"mode": HEX,
		"bits": 2,
	}


func update_output(_level: bool, _port: int, _r: bool):
	if input_pins[3].level: # Reset
		output_value(0)
	# Detect not rising edge of CK
	if not input_pins[2].level or input_pins[2].last_level:
		return
	input_pins[2].last_level = input_pins[2].level
	if input_pins[1].level: # LD
		output_value(vin)
		set_value(vin, false, false)


func set_value(v: int, _reverse: bool, _port := 0):
	vin = v


func output_value(v: int):
	value = v
	update_display_value()
	emit_signal("bus_changed", self, v, false)
