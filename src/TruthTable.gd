extends AcceptDialog

signal test_pressed(data)

var data

func _ready():
	insert_test_button()
	$Header1.hide()
	$Header2.hide()
	$Cell1.hide()
	$Cell2.hide()
	get_close_button().hide()
	#if get_parent().name == "root":
	#	open("etdff")


func open(part: Part):
	for node in $Grid.get_children():
		node.hide()
		node.queue_free()
	set_size(Vector2.ZERO) # Makes it resize starting from a small size
	data = Data.parts[part.id]
	data["locked"] = part.locked
	data["id"] = part.id
	$Grid.columns = data.inputs.size() + data.outputs.size()
	window_title = data.title + " Truth Table"
	for txt in data.inputs:
		$Grid.add_child(get_header_label(txt, false))
	for txt in data.outputs:
		$Grid.add_child(get_header_label(txt, true))
	var idx = 1
	for row in data.tt:
		for v in row:
			$Grid.add_child(get_item_label(String(v), idx > data.inputs.size()))
			idx += 1
		idx = 1
	set_position(Vector2(100, 200))
	show()


func get_header_label(txt, is_output: bool):
	var l = $Header2.duplicate() if is_output else $Header1.duplicate()
	l.text = txt
	l.show()
	return l


func get_item_label(txt, is_output: bool):
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
	return l


func _on_TruthTable_mouse_exited():
	# Hide if dragged outside of screen
	if !get_viewport_rect().encloses(Rect2(rect_position, rect_size)):
		hide()


func insert_test_button():
	var hbox = get_child(2)
	var tb = Button.new()
	tb.text = "Test"
	tb.focus_mode = Control.FOCUS_NONE
	hbox.get_child(1).text = "Close"
	hbox.add_child_below_node(hbox.get_child(0), tb)
	hbox.add_child_below_node(tb, hbox.get_child(0).duplicate())
	hbox.get_child(4).queue_free()
	hbox.get_child(0).queue_free()
	tb.connect("pressed", self, "run_test")

enum { RUNNING, PASSED, FAILED }

func run_test():
	emit_signal("test_pressed", data)


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
	idx += data.tt[0].size() * row
	if v:
		$Grid.get_child(idx).modulate = Color.green
	else:
		$Grid.get_child(idx).modulate = Color.red


func unhighlight_all():
	for node in $Grid.get_children():
		node.modulate = Color.white
