extends Part

func _ready():
	var off = [36,28, 14,14, 0,28, -14,14, -14,-14, 0,-28, 14,14, 22,29]
	var i = 0
	var pos = Vector2(0, 0)
	var n = 6.0 / 16
	for s in $LED.get_children():
		pos = pos + Vector2(off[i], off[i+1]) * 1.3
		s.position = pos
		if s.name != "s7":
			s.scale = Vector2(n, n)
		i += 2

var output_levels = {}
var value := 0

func setup():
	set_port_maps()

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

func set_value(v: int = -1):
	if v < 0:
		# Get the value from inputs (port 1, 2 ...
		v = 0
		for n in range(4, 0, -1):
			v *= 2
			if input_levels.has(n):
				v += int(input_levels[n])
	if value == v:
		return
	value = v
	var idx = 0
	for led in $LED.get_children():
		led.visible = map[idx].has(v)
		idx += 1
