extends Part

class_name CounterBlock

func setup():
	.setup()
	data = {
		"mode": HEX,
		"bits": 2,
	}
	preset_input(true, 1)
	preset_input(false, 2)
	preset_input(false, 4)
	label = $Label


func update_output(_level: bool, _port: int, _r: bool):
	if input_pins[4].level: # Reset
		output_value(0)
	# Detect not rising edge of CK
	if not input_pins[3].level or input_pins[3].last_level:
		return
	input_pins[3].last_level = input_pins[3].level
	if input_pins[2].level: # LD
		output_value(vin)
	else:
		output_value(wrapi(value + int(input_pins[1].level), 0, 0xffff))


func set_value(v: int, reverse: bool, port := 0):
	if v == vin or reverse:
		return
	if port == 0:
		vin = v


func output_value(v: int):
	value = v
	update_display_value()
	emit_signal("bus_changed", self, value, false)
