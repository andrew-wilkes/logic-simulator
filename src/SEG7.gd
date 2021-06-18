extends BUS

export(Color) var seg_color

func _ready():
	var off = [36,12, 14,14, 0,28, -14,14, -14,-14, 0,-28, 14,14, 22,29]
	var i = 0
	var pos = Vector2(0, 0)
	var n = 6.0 / 16
	for s in $LED.get_children():
		pos = pos + Vector2(off[i], off[i+1]) * 1.3
		s.position = pos
		if s.name != "s7":
			s.scale = Vector2(n, n)
		i += 2


func setup():
	set_port_maps()
	if not data.has("color"):
		data = { "color": seg_color, "mode": "hex" }
	#call_deferred("apply_data")


func apply_data():
	$HB/ColorPicker.color = data.color
	$HB/Mode.text = data.mode
	$LED.modulate = data.color


var map = [
	[0,2,3,5,6,7,8,9,10,12,14,15],
	[0,1,2,3,4,7,8,9,10,12,13],
	[0,1,3,4,5,6,7,8,9,10,11,12,13],
	[0,2,3,5,6,8,11,12,13,14],
	[0,2,6,8,10,11,13,14,15],
	[0,4,5,6,8,9,10,11,14,15],
	[2,3,4,5,6,8,9,10,11,13,14,15],
	[10,11,12,13,14,15]
]

func set_value(v: int, reverse: bool, _from_pin: bool):
	var idx = int(reverse)
	if _from_pin:
		v = get_value_from_inputs(reverse)
	if value == v:
		return
	value = v
	idx = 0
	for led in $LED.get_children():
		led.visible = map[idx].has(v % 16) # Use mod of v to stop overflow
		idx += 1
	# Emit divided down signal
# warning-ignore:integer_division
	emit_signal("bus_changed", self, value / 16, reverse)


func _on_ColorPicker_color_changed(color):
	data.color = color
	apply_data()


func _on_Mode_pressed():
	if data.mode == "hex":
		data.mode = "dec"
	else:
		data.mode = "hex"
	apply_data()


func get_data():
	return data


func set_data(d):
	data = d
	apply_data()
