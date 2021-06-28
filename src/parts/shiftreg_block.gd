extends Part

class_name ShiftRegBlock

func update_output(level: bool, port: int, _r: bool):
	if .update_output(level, port, _r):
		if input_levels[5]: # Reset
			output_enabled = true
			value = -1 # Make sure it propagates
			set_value(0, false, false)
		# Detect not rising edge of CK
		if not input_levels[4] or last_input_levels[4]:
			return
		last_input_levels[4] = input_levels[4]
		output_enabled = true
		if input_levels[3]: # LD
			value = -1 # Make sure it propagates
			set_value(vin, false, false)
		else:
			var v = value
			if input_levels[2]: # EN
				v /= 2 # Shift right
				if input_levels[1]: # SI
					v += msbs[data.bits]
			set_value(v, false, false)


func set_port_maps():
	in_port_map = [0, 1]
	out_port_map = [0]
			
