extends Part

class_name RegisterBlock

func update_output(_level: bool, _port: int, _r: bool):
	if input_pins[3].level: # Reset
		output_enabled = true
		set_value(0, false, false)
	# Detect not rising edge of CK
	if not input_pins[2].level or input_pins[2].last_level:
		return
	input_pins[2].last_level = input_pins[2].level
	if input_pins[1].level: # LD
		value = -1 # Make sure it propagates
		output_enabled = true
		set_value(vin, false, false)


func set_value(v: int, _reverse: bool, _port := 0):
	value = v
	if output_enabled:
		output_enabled = false
		update_display_value()
		emit_signal("bus_changed", self, v, false)
