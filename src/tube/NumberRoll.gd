extends Viewport

class_name NumberRoll

signal notice(id)

var num_bits = 4
var num_elements = 0
var maxv
var num_to_show = 32
var vsize = 0.0
var value = 0
var vb: VBoxContainer

enum { BIN, DEC, HEX }
enum { OK, OVERFLOW, CARRY, BORROW }

func _ready():
	vb = $PB/PL/VBox
	set_values(BIN)


func add_labels():
	var num = $PB/PL/VBox/Num
	num.bg_color = Color.transparent
	num.text_color = Color.white
	maxv = int(pow(2, num_bits))
	if maxv < num_to_show:
		num_elements = num_to_show
	else:
		num_elements = maxv
	var existing_count = vb.get_child_count()
	# Remove surplus labels
	if existing_count > num_elements:
		for idx in range(num_elements, existing_count):
			vb.get_child(idx).queue_free()
	# Add new labels
	for _n in range(existing_count, num_elements):
		var new_num = num.duplicate()
		vb.add_child(new_num)
	yield(get_tree(), "idle_frame")
	vb.rect_size.y = 0 # Make it shrink to fit
	$PB/PL.motion_mirroring = vb.rect_size
	# Size the viewport to expose the number of labels that we want to show
	size.x = vb.rect_size.x
	size.y = num.rect_size.y * num_to_show
	# Get the size of the entire column of labels
	vsize = vb.rect_size.y
	$PB/PL/ColorRect.rect_size = vb.rect_size
	goto_num(0, OK)


func set_values(base):
	add_labels()
	# Set the numbers from max at idx 0 to 0 for the last label
	# var num_bits = log(num_elements) / log(2)
	for idx in num_elements:
		var n = (num_elements - idx - 1) % maxv
		var el = vb.get_child(idx)
		match base:
			BIN:
				el.int2bin(n, num_bits)
			DEC:
				el.int2hex(n)
			HEX:
				el.int2dec(n)


func goto_num(n, status):
	# Reset the previous label colors
	var el = vb.get_child(get_idx(value))
	el.bg_color = Color.transparent
	el.text_color = Color.white
	# Scroll the box
	$PB/PL.motion_offset.y = size.y / 2 - vsize * (1.0 - float(n) / num_elements)
	value = n
	el = vb.get_child(get_idx(n))
	match status:
		OVERFLOW:
			el.bg_color = Color.red
			el.text_color = Color.white
		CARRY, BORROW:
			el.bg_color = Color.blue
			el.text_color = Color.white
		_:
			el.text_color = Color.yellow
	emit_signal("notice", status)


func get_idx(n):
	return num_elements - n % maxv - 1


func get_num():
	return num_elements + (int(($PB/PL.motion_offset.y - size.y / 2) / vsize * num_elements) % num_elements)


func inc():
	var result = OK
	var n = (value + 1) % maxv
	if n == maxv / 2:
		result = OVERFLOW
	if n == 0:
		result = CARRY
	goto_num(n, result)
	return result


func dec():
	var result = OK
	if value == maxv / 2:
		result = OVERFLOW
	if value == 0:
		result = BORROW
	var n = wrapi(value - 1, 0, maxv)
	goto_num(n, result)
	return result
