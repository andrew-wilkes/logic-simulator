extends LineEdit

signal value_changed(value)

export var num_bits = 8

var value = 0
var count_up = true
var max_value = 255
var format = "0x%02X"

func _ready():
	max_value = 255 if num_bits == 8 else 15


func _on_Up_pressed():
	count_up = true
	change_value()
	$RepeatTimer.start(0.5)


func _on_Down_pressed():
	count_up = false
	change_value()
	$RepeatTimer.start(0.5)


func _on_Timer_timeout():
	if $HB/VB/Up.pressed or $HB/VB/Down.pressed:
		change_value()
		$RepeatTimer.start(0.1)


func change_value():
	if count_up:
		if value < max_value:
			value += 1
	elif value > 0:
		value -= 1
	set_value(value)
	emit_signal("value_changed", value)


func _on_text_entered(new_text):
	if new_text.is_valid_integer():
		value = int(new_text)
	if new_text.is_valid_hex_number(true):
		value = new_text.hex_to_int()
	set_value(int(clamp(value, 0, max_value)))
	caret_position = 8
	emit_signal("value_changed", value)


func set_value(v):
	value = v
	text = format % [value]


func _on_VSlider_value_changed(v):
	set_value(v * max_value / 100)
	emit_signal("value_changed", value)
