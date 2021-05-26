extends GraphNode

class_name BUS

signal bus_changed(node, slot, value)

enum { HEX, DEC, BIN }

var type = ""
var group = ""
var _value := 0
var mode = HEX
var bits = 0
var bit_lengths = [4, 8, 16]
var format = ""

func _ready():
	set_format()
	set_value(_value)


func set_value(value: int):
	_value = value
	update_display_value()
	emit_signal("bus_changed", self, 0, value)


func update_display_value():
	match mode:
		HEX:
			$Label.text = format % _value
		DEC:
			$Label.text = String(_value)
		BIN:
			$Label.text = int2bin(_value)


func int2bin(x: int):
	var b = ""
	for n in bit_lengths[bits]:
		b = String(x % 2) + b
		x /= 2
	return b


func set_format():
	if mode == HEX:
		format = "0x%0" + String(bit_lengths[bits] / 4) + "X"


func _on_Bits_button_down():
	bits += 1
	bits %= bit_lengths.size()
	set_format()
	update_display_value()


func _on_Mode_button_down():
	mode += 1
	mode %= 3
	$HBox/Bits.disabled = mode == DEC
	set_format()
	update_display_value()
