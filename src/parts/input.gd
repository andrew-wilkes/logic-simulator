extends Part

func _ready():
	is_input = true
	var _e = $Tag.connect("text_changed", self, "text_changed")


func text_changed(_t):
	emit_signal("data_changed")


func set_value(v: int, reverse = false, _port := 0):
	value = v
	set_text(v)
	emit_signal("bus_changed", self, v, reverse)
	if not reverse or reverse and is_reversible_input:
		for n in output_pins.size() - 1:
			var level = bool(v % 2)
			v /= 2
			set_output(level, n + 1, reverse)


func set_text(v):
	get_child(0).text = "0x%02X" % v


var vs

func _on_VSlider_value_changed(v):
	vs = int(v)
	set_text(vs)
	$Timer.start()


func _on_Timer_timeout():
	set_value(vs)


func set_data(d: Dictionary):
	if has_node("Tag") and d.has("tag"):
		data = d
		$Tag.text = d.tag


func get_data():
	return { "tag": $Tag.text }
