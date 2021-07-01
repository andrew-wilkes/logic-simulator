extends Part

class_name CounterBlock

func update_output(_level: bool, _port: int, _r: bool):
	if input_pins[4].level: # Reset
		output_enabled = true
		value = -1 # Make sure it propagates
		set_value(0, false, false)
	# Detect not rising edge of CK
	if not input_pins[3].level or input_pins[3].last_level:
		return
	input_pins[3].last_level = input_pins[3].level
	output_enabled = true
	if input_pins[2].level: # LD
		value = -1 # Make sure it propagates
		set_value(vin, false, false)
	else:
		set_value(wrapi(value + int(input_pins[1]), 0, 0xffff), false, false)


func set_value(v: int, _reverse: bool, _port := 0):
	value = v
	if output_enabled:
		output_enabled = false
		$Bus.update_display_value()
		emit_signal("bus_changed", self, v, false)
