extends Part

class_name BUS

signal bus_changed(node, slot, value)

enum { HEX, DEC, BIN }

var mode = HEX
var bits = 0
var bit_lengths = [4, 8, 16]
var format = ""
var output_levels = {}
var value := 0

func _ready():
	if name == "INBUS":
		set("slot/0/left_enabled", false)
		add_slots()
	if name == "OUTBUS":
		add_slots()
		set("slot/0/right_enabled", false)
	set_format()
	set_value()


func add_slots():
	if name != "INBUS" and name != "OUTBUS":
		return
	var n = get_child_count()
	if n > 16:
		return
	var c = Label.new()
	c.rect_min_size.y = 24
	c.valign = Label.VALIGN_CENTER
	var left = name == "INBUS"
	if not left:
		c.align = Label.ALIGN_RIGHT
	var num = 4 if bits < 2 else 8
	for _i in num:
		c.text = String(n - 3)
		output_levels[n - 3] = false
		add_child(c.duplicate())
		set_slot(n, left, 0, Color.white, not left, 0, Color.white)
		n += 1


func set_value():
	# Get the value
	value = 0
	for n in bit_lengths[bits]:
		value *= 2
		if input_levels.has(n):
			value += int(input_levels[n])
	update_display_value()
	emit_signal("bus_changed", self, 0, value)
	if type == "OUTBUS":
		for n in bit_lengths[bits]:
			var level = value % 2
			if output_levels[n] != level:
				output_levels[n] = level
				set_output(level, n + 3)


func set_output(level: bool, slot: int):
	var col = Color.red if level else Color.blue
	set("slot/%d/right_color" % slot, col)
	# Output the port number
	emit_signal("output_changed", self, 0, level)


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
	bits += 1
	bits %= bit_lengths.size()
	set_format()
	update_display_value()
	add_slots()


func _on_Mode_button_down():
	mode += 1
	mode %= 3
	$HBox/Bits.disabled = mode == DEC
	set_format()
	update_display_value()
