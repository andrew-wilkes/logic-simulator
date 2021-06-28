extends Part

class_name RegisterBlock

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		if input_levels[3]: # Reset
			output_enabled = true
			set_value(0, false, false)
		# Detect not rising edge of CK
		if not input_levels[2] or last_input_levels[2]:
			return
		last_input_levels[2] = input_levels[2]
		if input_levels[1]: # LD
			value = -1 # Make sure it propagates
			output_enabled = true
			set_value(vin, false, false)


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
			
