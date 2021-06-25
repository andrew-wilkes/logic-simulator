extends PopupPanel

enum { HEX, BIN }
var mode = HEX
var base_addr = 0
var mem_size = 1024
var current_addr = 0
var data: MemoryData

func _ready():
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
	var bformat = "%X "
	var items = PoolStringArray()
# warning-ignore:integer_division
	var num_rows = data.bytes.size() / 16
	if num_rows > 16:
		num_rows = 16
	for n in num_rows:
		var row = PoolStringArray()
		var display_addr = addr
		if data.width == 16:
			display_addr /= 2
		row.append("%04X: " % display_addr)
		match mode:
			BIN:
				row.append(Parts.int2bin(data.bytes[addr] + 16 * data.bytes[addr + 1], 16))
				addr += 2
			_:
				var asc = PoolStringArray()
				for b in 16:
					var d = data.bytes[addr] % 16
					row.append(bformat % d)
					if b % 2 == 1:
						var char_code = d * 16 + data.bytes[addr - 1]
						if char_code > 31 and char_code < 128:
							asc.append(char(char_code))
						else:
							asc.append(".")
					addr += 1
				row.append(asc.join(""))
		items.append(row.join(""))
	$M/VBox/View.text = items.join("\n")


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


func set_addr(p):
	var x = int(clamp(floor((p.x - 53) / 20), 0, 15))
	var y = int(clamp(floor(p.y / 22), 0, 15))
	current_addr = x + base_addr + y * 16
	$MemoryValuePanel.open(data.bytes[current_addr])


func _on_MemoryValuePanel_value_changed(v):
	data.bytes[current_addr] = v
	set_view()
