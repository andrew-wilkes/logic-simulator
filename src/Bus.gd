extends Part

class_name BUS

enum { HEX, DEC, BIN, BITS, MODE }

var mode = HEX
var format = ""
var button: Button
var button_mode = BITS

func setup():
	if type == Parts.INBUS:
		set("slot/0/left_enabled", false)
	if type == Parts.OUTBUS:
		set("slot/0/right_enabled", false)
	set_port_maps()
	add_slots()
	set_format()
	set_value(0, false, false)


func add_slots():
	var slot = get_child_count() - 2 # num slots
	if type != Parts.INBUS and type != Parts.OUTBUS:
		if slot == 1:
			add_button(Label.new(), false)
		return
	if slot > 16:
		return
	var c = Label.new()
	c.size_flags_horizontal = SIZE_EXPAND_FILL
	c.rect_min_size.y = 24
	c.valign = Label.VALIGN_CENTER
	var left = type == Parts.INBUS
	if not left:
		c.align = Label.ALIGN_RIGHT
	var num = 4 if bits < 2 else 8
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


func set_value(v: int, reverse: bool, from_pin: bool):
	if from_pin:
		v = get_value_from_inputs(reverse)
	# If the value is unchanged ignore it
	# This also guards against a feedback loop
	if value == v:
		return
	value = v
	if type == Parts.REG:
		if output_enabled:
			output_enabled = false
		else: # Just capture the new input value
			vin = v
			return
	update_display_value()
	emit_signal("bus_changed", self, value, reverse)
	if type == Parts.OUTBUS and !reverse or type == Parts.INBUS and reverse:
		for n in bit_lengths[bits]:
			var level = bool(v % 2)
			v /= 2
			if output_levels[n] != level:
				output_levels[n] = level
				set_output(level, n, reverse)


func update_display_value():
	match mode:
		HEX:
			$Label.text = format % value
		DEC:
			$Label.text = String(value)
		BIN:
			$Label.text = int2bin(value)


func int2bin(x: int):
	var b = ""
	for n in bit_lengths[bits]:
		if n > 0 and n % 4 == 0:
			b = " " + b
		b = String(x % 2) + b
		x /= 2
	return "0b" + b


func set_format():
	if mode == HEX:
		format = "0x%0" + String(bit_lengths[bits] / 4) + "X"


func _on_Bits_button_down():
	if bits < 2:
		bits += 1
		set_format()
		update_display_value()
		add_slots()
		if bits == 2:
			$HBox/Bits.hide()
		else:
			$Timer.start()
		depth = bits


func _on_Mode_button_down():
	mode += 1
	mode %= 3
	$HBox/Bits.disabled = mode == DEC
	set_format()
	update_display_value()

func _on_button_down():
	if button_mode == BITS:
		if bits < 2:
			bits += 1
			set_format()
			update_display_value()
			add_slots()
			if bits == 2:
				button_to_mode()
			else:
				$Timer.start()
			depth = bits
	else:
		mode += 1
		mode %= 3
		set_format()
		update_display_value()


func dropped():
	if type in [Parts.REG]:
		return
	$Timer.start()


func _on_Timer_timeout():
	button_to_mode()


func button_to_mode():
	button_mode = MODE
	button.text = "Mode"
