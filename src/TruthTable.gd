extends WindowDialog

signal test_pressed(data)

var data
var _part: Part
var grid

func _ready():
	$Header1.hide()
	$Header2.hide()
	$Cell1.hide()
	$Cell2.hide()
	get_close_button().hide()
	grid = $M/VBox/Grid


func open(part: Part):
	_part = part
	for node in grid.get_children():
		node.hide()
		node.queue_free()
	data = Data.parts[part.type]
	data["locked"] = part.locked
	data["part"] = part
	grid.columns = data.inputs.size() + data.outputs.size()
	window_title = data.title + " Truth Table"
	for txt in data.inputs:
		grid.add_child(get_header_label(txt, false))
	for txt in data.outputs:
		grid.add_child(get_header_label(txt, true))
	var idx = 1
	for row in data.tt:
		if row.size() > grid.columns:
			continue # Skip row
		for v in row:
			add_item_label(String(v), idx > data.inputs.size())
			idx += 1
		idx = 1
	set_position(Vector2(100, 200))
	show()
	call_deferred("reset_size")


func reset_size():
	set_size($M.rect_size)


func get_header_label(txt, is_output: bool):
	var l = $Header2.duplicate() if is_output else $Header1.duplicate()
	l.text = txt
	l.show()
	return l


func add_item_label(txt, is_output: bool):
	match txt:
		"+":
			txt = "Rising edge"
		"-":
			txt = "Falling edge"
		"L":
			txt = "Last value"
	var l = $Cell2.duplicate() if is_output else $Cell1.duplicate()
	l.text = txt
	l.show()
	grid.add_child(l)


func _on_TruthTable_mouse_exited():
	# Hide if dragged outside of screen
	if !get_viewport_rect().encloses(Rect2(rect_position, rect_size)):
		hide()


func run_test():
	if is_instance_valid(_part):
		if _part.type == "RAM":
			_part.apply_data() # Erase the memory
		emit_signal("test_pressed", data)
	else:
		hide()


func highlight_inputs(input_pins, inputs):
	var offset = 0
	for ip in inputs:
		highlight_value(0, offset, input_pins.has(ip))
		offset += 1


func highlight_outputs(output_pins, inputs, outputs):
	var offset = inputs.size()
	for ip in outputs:
		highlight_value(0, offset, output_pins.has(ip))
		offset += 1


func highlight_value(row: int, idx: int, v: bool):
	idx += grid.columns * row
	if v:
		grid.get_child(idx).modulate = Color.green
	else:
		grid.get_child(idx).modulate = Color.red


func unhighlight_all():
	for node in grid.get_children():
		node.modulate = Color.white


func _on_Close_pressed():
	hide()


func _on_Info_pressed():
	$Info.window_title = data["title"]
	$Info.dialog_text = data["desc"]
	$Info.rect_position = rect_position
	$Info.popup()


func _on_Test_pressed():
	run_test()
