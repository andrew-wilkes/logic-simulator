extends Control

signal pin_entered(idx, is_input_pin)
signal pin_exited(idx, is_input_pin)

var idx = 0
var is_input_pin = true

func _on_Rect_mouse_entered():
	emit_signal("pin_entered", idx, is_input_pin)


func _on_Rect_mouse_exited():
	emit_signal("pin_exited", idx, is_input_pin)
