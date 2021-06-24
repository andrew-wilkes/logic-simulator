extends PopupPanel

enum { HEX, BIN }
var mode = HEX
var base_addr = 0
var mem_size = 1024
var data: PoolIntArray
var width = 8

func _ready():
	data.resize(1024)
	set_view()
	var sizes = $M/VBox/Top/Size.get_popup()
	sizes.add_item("32")
	sizes.add_item("64")
	sizes.add_item("128")
	sizes.add_item("256")
	sizes.add_item("512")
	sizes.add_item("1K")
	sizes.add_item("2K")
	sizes.add_item("4K")
	sizes.add_item("8K")
	sizes.connect("id_pressed", self, "_on_size_id_pressed")
	call_deferred("popup_centered")


func _on_size_id_pressed(id: int):
	set_mem_size([32,64,128,256,512,1024,2048,4096,8192][id])


func set_view():
	var addr = base_addr
	var bformat = "%X "
	var items = PoolStringArray()
	for n in 16:
		var row = PoolStringArray()
		var display_addr = addr
		if width == 16:
			display_addr /= 2
		row.append("%04X: " % display_addr)
		match mode:
			BIN:
				row.append(Parts.int2bin(data[addr] + 16 * data[addr + 1], 16))
				addr += 2
			_:
				var asc = PoolStringArray()
				for b in 16:
					row.append(bformat % data[addr])
					if data[addr] > 31:
						asc.append(char(data[addr]))
					else:
						asc.append(".")
					addr += 1
				row.append(asc.join(""))
		items.append(row.join(""))
	$M/VBox/View.text = items.join("\n")


func get_start():
	return


func setup():
	pass


func update_grid():
	pass


func _on_Up_pressed():
	base_addr = wrapi(base_addr + 0x100, 0, mem_size)
	set_view()


func _on_Down_pressed():
	base_addr = wrapi(base_addr - 0x100, 0, mem_size)
	set_view()


func _on_BH_pressed():
	mode = wrapi(mode + 1, 0, 3)
	set_view()


func _on_Erase_pressed():
	pass # Replace with function body.


func _on_OK_pressed():
	hide()


func _on_Width_pressed():
	if width == 8:
		set_width(16)
	else:
		set_width(8)


func set_width(w: int):
	width = w
	$M/VBox/Top/WidthLabel.text = String(w)
	set_view()


func set_mem_size(s):
	mem_size = s
	$M/VBox/Top/SizeLabel.text = String(s)
	
