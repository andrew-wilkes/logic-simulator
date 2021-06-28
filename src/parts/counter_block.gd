extends Part

class_name CounterBlock

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		if input_levels[4]: # Reset
			output_enabled = true
			value = -1 # Make sure it propagates
			set_value(0, false, false)
		# Detect not rising edge of CK
		if not input_levels[3] or last_input_levels[3]:
			return
		last_input_levels[3] = input_levels[3]
		output_enabled = true
		if input_levels[2]: # LD
			value = -1 # Make sure it propagates
			set_value(vin, false, false)
		else:
			set_value(wrapi(value + int(input_levels[1]), 0, 0xffff), false, false)


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
			
