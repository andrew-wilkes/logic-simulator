extends Node
# This will be added to a part where Bus functionality is required

class_name BUS

enum { HEX, DEC, BIN, BITS, MODE }

var format = ""
var button: Button
var button_mode = BITS
var has_mode_button = false

func setup_bus(part: Part):
	part.data = { "bits": part.bits, "mode": HEX } # bits is a part export var
	"""
	if type == Parts.TYPES.INBUS:
		set("slot/0/left_enabled", false)
	if type == Parts.TYPES.OUTBUS:
		set("slot/0/right_enabled", false)
	"""
	set_port_maps()
	add_slots(4)
	set_format()
	set_value(0, false, false)
	_e = part.connect("bus_changed", self, "update_bus")


# This function is overwritten in busses
func set_value(_v: int, _reverse: bool, _from_pin: bool, _port := 0):
	if from_pin:
		v = get_value_from_inputs(reverse)
	# If the value is unchanged ignore it
	# This also guards against a feedback loop
	if value == v:
		return
	value = v
	
	if type in [Parts.TYPES.REG, Parts.TYPES.COUNTER, Parts.TYPES.SHIFTREG]:
		if output_enabled:
			output_enabled = false
		else: # Just capture the new input value
			vin = v
			return
	update_display_value()
	if type == Parts.TYPES.LOOPBACK:
		reverse = not reverse
	emit_signal("bus_changed", self, value, reverse)


func add_slots(part: Part, num: int):
	var slot = part.get_child_count() - 2 # num slots
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
			add_button(part, l, left)
		else:
			part.add_child(l)
		g.set_slot(slot, left, 0, Color.white, not left, 0, Color.white)
		if left:
			part.in_port_map.append(slot)
			part.in_port_mode.append(PIN_MODE.BI)
		else:
			part.out_port_map.append(slot)
			part.out_port_mode.append(PIN_MODE.BI)
		slot += 1


func add_button(part: Part, l: Label, left: bool):
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
	part.add_child(h)
	has_mode_button = true


func update_display_value():
	match data.mode:
		HEX:
			$Label.text = format % value
		DEC:
			$Label.text = String(value)
		BIN:
			$Label.text = Parts.int2bin(value, bit_lengths[data.bits])


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


func get_data():
	return data


func set_data(d):
	data = d
	if data.empty():
		return
	if type == Parts.TYPES.ROM or type == Parts.TYPES.RAM:
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
