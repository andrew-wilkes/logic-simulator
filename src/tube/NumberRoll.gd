extends Viewport

var num_elements = 32
var num_to_show = 32
var vsize = 0.0
var value = 0

enum { BIN, DEC, HEX }
enum { OK, OVERFLOW, CARRY, BORROW }

func _ready():
	var num = $PB/PL/VBox/Num
	for n in num_elements:
		if n > 0:
			var new_num = num.duplicate()
			$PB/PL/VBox.add_child(new_num)
	yield(get_tree(), "idle_frame")
	$PB/PL.motion_mirroring = $PB/PL/VBox.rect_size
	size.x = $PB/PL/VBox.rect_size.x
	size.y = num.rect_size.y * num_to_show
	vsize = $PB/PL/VBox.rect_size.y
	set_values(BIN)
	goto_num(0, OK)


func set_values(base):
	var num_bits = log(num_elements) / log(2)
	for idx in num_elements:
		var n = num_elements - idx - 1
		var el = $PB/PL/VBox.get_child(idx)
		match base:
			BIN:
				el.int2bin(n, num_bits)
			DEC:
				el.int2hex(n)
			HEX:
				el.int2dec(n)


func goto_num(n, status):
	var el = $PB/PL/VBox.get_child(get_idx(value))
	el.bg_color = Color.black
	el.text_color = Color.white
	$PB/PL.motion_offset.y = vsize * n / num_elements + size.y / 2
	value = n
	el = $PB/PL/VBox.get_child(get_idx(n))
	match status:
		OVERFLOW:
			el.bg_color = Color.red
			el.text_color = Color.white
		CARRY, BORROW:
			el.bg_color = Color.blue
			el.text_color = Color.white
		_:
			el.text_color = Color.yellow


func get_idx(n):
	return num_elements - n - 1


func get_num():
	return int(($PB/PL.motion_offset.y - size.y / 2) / vsize * num_elements) % num_elements


func inc():
	var result = OK
	var n = (value + 1) % num_elements
	if n == num_elements / 2:
		result = OVERFLOW
	if n == 0:
		result = CARRY
	goto_num(n, result)
	return result


func dec():
	var result = OK
	if value == num_elements / 2:
		result = OVERFLOW
	if value == 0:
		result = BORROW
	var n = wrapi(value - 1, 0, num_elements - 1)
	goto_num(n, result)
	return result
