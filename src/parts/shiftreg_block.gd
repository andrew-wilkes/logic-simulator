extends Part

class_name ShiftRegBlock

func setup():
	.setup()
	data = {
		"mode": HEX,
		"bits": 2,
	}
	apply_data()


func apply_data():
	#set_format()
	update_display_value()

func update_output(_level: bool, _port: int, _r: bool):
	if input_pins[5].level: # Reset
		output_enabled = true
		value = -1 # Make sure it propagates
		set_value(0, false, false)
	# Detect not rising edge of CK
	if not input_pins[4].level or input_pins[4].last_level:
		return
	input_pins[4].last_level = input_pins[4].level
	output_enabled = true
	if input_pins[3].level: # LD
		value = -1 # Make sure it propagates
		set_value(vin, false, false)
	else:
		var v = value
		if input_pins[2].level: # EN
			v /= 2 # Shift right
			if input_pins[1].level: # SI
				v += msbs[data.bits]
		set_value(v, false, false)


func set_value(v: int, _reverse: bool, _port := 0):
	value = v
	if output_enabled:
		output_enabled = false
		update_display_value()
		emit_signal("bus_changed", self, v, false)


func _on_Bits_was_pressed(_b):
	change_bit_depth(_b)


func _on_Bits_button_timer_timeout(_b):
	change_button(_b)
