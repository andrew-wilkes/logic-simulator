extends Label

var bg_color setget set_bg_color, get_bg_color
var text_color setget set_text_color, get_text_color

func resize():
	$ColorRect.rect_size = rect_size

func set_bg_color(c):
	$ColorRect.color = c

func get_bg_color():
	return $ColorRect.color

func set_text_color(c):
	modulate = c

func get_text_color():
	return modulate

# Create groups of 4 bits
func int2bin(x, num_bits):
	var _b = ""
	for n in num_bits:
		if n == 4:
			_b = " " + _b
		_b = String(x % 2) + _b
		x /= 2
	text = _b
	resize()

func int2hex(x):
	text = "%02X" % x
	resize()

func int2dec(x):
	text = String(x)
	resize()
