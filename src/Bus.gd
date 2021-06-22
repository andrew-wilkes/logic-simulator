extends Part

class_name BUS

enum { HEX, DEC, BIN, BITS, MODE }

var format = ""
var button: Button
var button_mode = BITS
var has_mode_button = false

func setup():
	data = { "bits": bits, "mode": HEX } # bits is a part export var
	if type == Parts.TYPES.INBUS:
		set("slot/0/left_enabled", false)
	if type == Parts.TYPES.OUTBUS:
		set("slot/0/right_enabled", false)
	set_port_maps()
	add_slots(4)
	set_format()
	set_value(0, false, false)


func add_slots(num: int):
	var slot = get_child_count() - 2 # num slots
	if type != Parts.TYPES.INBUS and type != Parts.TYPES.OUTBUS:
		if slot < 3:
			add_button(Label.new(), false)
			button_to_mode()
		return
	if slot > 16:
		return
	var c = Label.new()
	c.size_flags_horizontal = SIZE_EXPAND_FILL
	c.rect_min_size.y = 24
	c.valign = Label.VALIGN_CENTER
	var left = type == Parts.TYPES.INBUS
	if not left:
		c.align = Label.ALIGN_RIGHT
	for _i in num:
		var l = c.duplicate()
		var idx = slot - 1
		l.text = String(idx)
		output_levels[idx] = false
		if idx == 0:
			add_button(l, left)
		else:
			add_child(l)
		set_slot(slot, left, 0, Color.white, not left, 0, Color.white)
		if left:
			in_port_map.append(slot)
			in_port_mode.append(PIN_MODE.BI)
		else:
			out_port_map.append(slot)
			out_port_mode.append(PIN_MODE.BI)
		slot += 1


func add_button(l: Label, left: bool):
	var h = HBoxContainer.new()
	button = Button.new()
	button.text = "Bits"
	var _e = button.connect("pressed", self, "_on_button_down")
	if left:
		h.add_child(l)
		h.add_child(button)
	else:
		h.add_child(button)
		h.add_child(l)
	add_child(h)
	has_mode_button = true


func set_value(v: int, reverse: bool, from_pin: bool, port := 0):
	if type == Parts.TYPES.ALU:
		if port == 0:
			if v != a:
				a = v
				update_output(true, -1, false)
			return
		if port == 1:
			if v != b:
				b = v
				update_output(true, -1, false)
			return
	if from_pin:
		v = get_value_from_inputs(reverse)
	# If the value is unchanged ignore it
	# This also guards against a feedback loop
	if value == v:
		return
	value = v
	if type in [Parts.TYPES.REG, Parts.TYPES.COUNTER, Parts.TYPES.SHIFTREG, Parts.TYPES.MEM]:
		if output_enabled:
			output_enabled = false
		else: # Just capture the new input value
			vin = v
			return
	update_display_value()
	if type == Parts.TYPES.LOOPBACK:
		reverse = not reverse
	emit_signal("bus_changed", self, value, reverse)
	if type == Parts.TYPES.OUTBUS and !reverse or type == Parts.TYPES.INBUS and reverse:
		for n in bit_lengths[bits]:
			var level = bool(v % 2)
			v /= 2
			if output_levels[n] != level:
				output_levels[n] = level
				set_output(level, n, reverse)


func update_display_value():
	match data.mode:
		HEX:
			$Label.text = format % value
		DEC:
			$Label.text = String(value)
		BIN:
			$Label.text = int2bin(value)


func int2bin(x: int):
	var b = ""
	for n in bit_lengths[data.bits]:
		if n > 0 and n % 4 == 0:
			b = " " + b
		b = String(x % 2) + b
		x /= 2
	return "0b" + b


func set_format():
	if data.mode == HEX:
		format = "0x%0" + String(bit_lengths[data.bits] / 4) + "X"


func _on_button_down():
	if button_mode == BITS:
		if data.bits < 2:
			data.bits += 1
			set_format()
			update_display_value()
			var num = 4 if data.bits < 2 else 8
			add_slots(num)
			if data.bits == 2:
				button_to_mode()
			else:
				$Timer.start()
	else:
		data.mode += 1
		data.mode %= 3
		set_format()
		update_display_value()
	emit_signal("data_changed")


func dropped():
	if type in [Parts.TYPES.INBUS, Parts.TYPES.OUTBUS]:
		$Timer.start()


func _on_Timer_timeout():
	button_to_mode()


func button_to_mode():
	button_mode = MODE
	button.text = "Mode"


func get_data():
	return data


func set_data(d):
	data = d
	if data.empty():
		return
	if has_mode_button:
		button_to_mode()
	set_format()
	update_display_value()
	if type == Parts.TYPES.INBUS or type == Parts.TYPES.OUTBUS:
		if data.bits == 1:
			add_slots(4)
		if data.bits == 2:
			add_slots(12)


func _on_Bits_was_pressed(b):
	if data.has("bits"):
		data.bits = wrapi(data.bits + 1, 0, 3)
		b.text = String(bit_lengths[data.bits])
		value = 0
		set_format()
		update_display_value()
