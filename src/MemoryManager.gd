extends PopupPanel

signal data_changed

enum { HEX, BIN }

var mode = HEX
var base_addr = 0
var mem_size = 1024
var current_addr = 0
var data: MemoryData
var addr_increment = 0x100

func _ready():
	hide_mask()
	var sizes = $M/VBox/Top/Size.get_popup()
	sizes.clear()
	data = MemoryData.new()
	for v in data.mem_sizes.values():
		sizes.add_item(v)
	sizes.connect("id_pressed", self, "_on_size_id_pressed")
	if get_parent().name == "root":
		set_mem_size(5)
		set_width(8)
		call_deferred("popup_centered")


func open(_data):
	data = _data
	$M/VBox/Top/WidthLabel.text = String(data.width)
	$M/VBox/Top/SizeLabel.text = data.get_mem_size_str()
	set_view()
	call_deferred("popup_centered")


func _on_size_id_pressed(id: int):
	set_mem_size(id)


func set_view():
	var addr = base_addr
	var hex_format = "%02X " if data.width == 8 else "%04X "
	var addresses = PoolStringArray()
	var bytes = PoolStringArray()
	var chars = PoolStringArray()
# warning-ignore:integer_division
	var num_rows = data.words.size() / 16
	if num_rows > 16:
		num_rows = 16
	for n in num_rows:
		var row = PoolStringArray()
		var display_addr = addr
		addresses.append("%04X: " % display_addr)
		if mode == BIN:
# warning-ignore:integer_division
			for m in 32 / data.width: # 2 words or 4 bytes
				row.append(int2bin(data.words[addr]))
				addr += 1
				row.append(" ")
		else:
			var asc = PoolStringArray()
			var count = 8 if data.width == 16 else 16
			for m in count: # 16 bytes or 8 words
				var _d = data.words[addr]
				asc.append(get_ascii(_d % 0x100))
				if data.width == 16:
					asc.append(get_ascii(_d / 0x100))
				row.append(hex_format % _d)
				addr += 1
			chars.append(asc.join(""))
		bytes.append(row.join("").strip_edges())
	$M/VBox/View/Addr.text = addresses.join("\n")
	$M/VBox/View/Bytes.text = bytes.join("\n")
	$M/VBox/View/Chrs.text = chars.join("\n")


func get_ascii(d):
	if d > 31 and d < 127:
		return char(d)
	else:
		return"."


func _on_Up_pressed():
	base_addr = wrapi(base_addr - addr_increment, 0, data.mem_size)
	set_view()


func _on_Down_pressed():
	base_addr = wrapi(base_addr + addr_increment, 0, data.mem_size)
	set_view()


func _on_BH_pressed():
	mode = wrapi(mode + 1, 0, 2)
	set_addr_increment()
	set_view()
	resize()


func _on_Erase_pressed():
	data.erase()
	set_view()


func _on_OK_pressed():
	hide()


func _on_Width_pressed():
	set_addr_increment()


func set_addr_increment():
	if data.width == 8:
		addr_increment = 0x80 if mode == HEX else 0x20
		set_width(16)
	else:
		data.trim()
		addr_increment = 0x100 if mode == HEX else 0x40
		# Make base addr start from increments of addr_increment
		base_addr = base_addr / addr_increment * addr_increment
		set_width(8)


func set_width(w: int):
	data.width = w
	$M/VBox/Top/WidthLabel.text = String(w)
	set_view()
	resize()
	emit_signal("data_changed")


func set_mem_size(id: int):
	base_addr = 0
	data.set_indexed_mem_size(id)
	$M/VBox/Top/SizeLabel.text = data.get_mem_size_str()
	set_view()
	emit_signal("data_changed")


func _on_View_gui_input(event):
	if event is InputEventMouseButton:
		set_addr(event.position)
		$NumberInputPanel.rect_position = rect_position + Vector2(0, rect_size.y + 20)
		$NumberInputPanel.open(mode == HEX, data.width)


func set_addr(p):
	# To get the constants: divide the bytes label width by the number of numbers per row
	var div: int
	if mode == HEX:
		div = 30 if data.width == 8 else 50
	else:
		div = 90 if data.width == 8 else 170
# warning-ignore:integer_division
	var x = int(p.x) / div
# warning-ignore:integer_division
	var y = int(p.y) / 22
	if data.width == 16:
		y /= 2
	var ystep = 16 if mode == HEX else 4
	show_mask(Vector2(x, y), Vector2(div, 22))
	current_addr = x + base_addr + y * ystep


func show_mask(pos, size):
	if data.width == 16:
		pos.y *= 2
	$M/VBox/View/Bytes/Mask.show()
	$M/VBox/View/Bytes/Mask.rect_position = (pos * size) - Vector2(5, 2)
	$M/VBox/View/Bytes/Mask.rect_size = size


func hide_mask():
	$M/VBox/View/Bytes/Mask.hide()


func _on_NumberInputPanel_popup_hide():
	hide_mask()
	var v = $NumberInputPanel.txt.text
	if v[0] != "0": # No entry was made
		return
	var x = 0
	if mode == BIN:
		for i in v.length():
			if i > 1: # Skip the prefix 0b
				x *= 2
				if v[i] == "1":
					x += 1
	else:
		x = v.hex_to_int() # Godot function
	data.words[current_addr] = x
	set_view()
	emit_signal("data_changed")


func int2bin(x: int) -> String:
	var b = ""
	for n in data.width:
		b = String(x % 2) + b
		x /= 2
	return b


func resize():
	yield(get_tree(), "idle_frame")
	rect_size = Vector2.ZERO
