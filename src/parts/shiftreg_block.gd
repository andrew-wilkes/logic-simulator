extends Part

class_name ShiftRegBlock

func setup():
	.setup()
	data = {
		"mode": BITS,
		"bits": 1,
	}
	preset_input(false, 1)
	preset_input(false, 2)
	preset_input(false, 3)
	preset_input(false, 5)
	label = $Label


func update_output(_level: bool, _port: int, _r: bool):
	if input_pins[5].level: # Reset
		output_value(0)
	# Detect not rising edge of CK
	if not input_pins[4].level or input_pins[4].last_level:
		return
	input_pins[4].last_level = input_pins[4].level
	if input_pins[3].level: # LD
		output_value(vin)
	else:
		var v = value
		if input_pins[2].level: # EN
			v /= 2 # Shift right
			if input_pins[1].level: # SI
				v += msbs[data.bits]
		output_value(v)


func set_value(v: int, reverse: bool, port := 0):
	if v == vin or reverse:
		return
	if port == 0:
		vin = v


func output_value(v: int):
	value = v
	update_display_value()
	emit_signal("bus_changed", self, v, false)


func _on_Bits_was_pressed(_b):
	handle_button_press(_b)
	emit_signal("data_changed")


func _on_Bits_button_timer_timeout(_b):
	change_button(_b)


func apply_data():
	change_bit_depth($HBox/Bits, 0)
	change_button($HBox/Bits)
