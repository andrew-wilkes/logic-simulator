extends PopupPanel

enum { HEX, BIN }
var mode = HEX
var base_addr = 0
var mem_size = 1024
var current_addr = 0
var data: MemoryData

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
	var bformat = "%02X "
	var addresses = PoolStringArray()
	var bytes = PoolStringArray()
	var chars = PoolStringArray()
# warning-ignore:integer_division
	var num_rows = data.bytes.size() / 16
	if num_rows > 16:
		num_rows = 16
	for n in num_rows:
		var row = PoolStringArray()
		var display_addr = addr
		if data.width == 16:
			display_addr /= 2
		addresses.append("%04X: " % display_addr)
		match mode:
			BIN:
				for m in 2:
					row.append(Parts.int2bin(data.bytes[addr] + 16 * data.bytes[addr + 1], 16, ""))
					row.append(" ")
					addr += 2
			_:
				var asc = PoolStringArray()
				for b in 16:
					var d = data.bytes[addr] % 0x100
					row.append(bformat % d)
					if d > 31 and d < 127:
						asc.append(char(d))
					else:
						asc.append(".")
					addr += 1
				chars.append(asc.join(""))
		bytes.append(row.join(""))
	$M/VBox/View/Addr.text = addresses.join("\n")
	$M/VBox/View/Bytes.text = bytes.join("\n")
	$M/VBox/View/Chrs.text = chars.join("\n")


func _on_Up_pressed():
	if data.mem_size > 0x100:
		base_addr = wrapi(base_addr + 0x100, 0, data.mem_size)
		set_view()


func _on_Down_pressed():
	if data.mem_size > 0x100:
		base_addr = wrapi(base_addr - 0x100, 0, data.mem_size)
		set_view()


func _on_BH_pressed():
	mode = wrapi(mode + 1, 0, 2)
	set_view()


func _on_Erase_pressed():
	data.erase()
	set_view()


func _on_OK_pressed():
	hide()


func _on_Width_pressed():
	if data.width == 8:
		set_width(16)
	else:
		set_width(8)
	set_view()


func set_width(w: int):
	data.width = w
	$M/VBox/Top/WidthLabel.text = String(w)


func set_mem_size(id: int):
	base_addr = 0
	data.set_indexed_mem_size(id)
	$M/VBox/Top/SizeLabel.text = data.get_mem_size_str()
	set_view()


func _on_View_gui_input(event):
	if event is InputEventMouseButton:
		set_addr(event.position)
		$NumberInputPanel.open(mode == HEX)


func set_addr(p):
	var div = 30 if mode == HEX else 101
	var x = int(p.x) / div
# warning-ignore:integer_division
	var y = int(p.y) / 22
	current_addr = x + base_addr + y * 16
	if mode == BIN:
		div /= 2
		x = int(p.x) / div
	show_mask(Vector2(x, y), Vector2(div, 22))


func show_mask(pos, size):
	$M/VBox/View/Bytes/Mask.show()
	$M/VBox/View/Bytes/Mask.rect_position = (pos * size) - Vector2(5, 2)
	$M/VBox/View/Bytes/Mask.rect_size = size


func hide_mask():
	$M/VBox/View/Bytes/Mask.hide()


func _on_NumberInputPanel_popup_hide():
	hide_mask()
	var v = $NumberInputPanel.txt.text
	if v[0] != "0":
		return
	var x = 0
	if mode == BIN:
		for n in 4:
			x *= 2
			if v[2 + n] == "1":
				x += 1
	else:
		x = v.hex_to_int()
	data.bytes[current_addr] = x
	set_view()
