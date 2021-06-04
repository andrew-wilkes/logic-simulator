extends AcceptDialog

signal test_pressed

func _ready():
	insert_test_button()
	$Header1.hide()
	$Header2.hide()
	$Cell1.hide()
	$Cell2.hide()
	get_close_button().hide()
	if get_parent().name == "root":
		open("etdff")


func open(id):
	for node in $Grid.get_children():
		node.hide()
		node.queue_free()
	set_size(Vector2.ZERO) # Makes it resize starting from a small size
	var data = Data.parts[id]
	$Grid.columns = data.inputs.size() + data.outputs.size()
	window_title = data.title + " Truth Table"
	for txt in data.inputs:
		$Grid.add_child(get_header_label(txt, false))
	for txt in data.outputs:
		$Grid.add_child(get_header_label(txt, true))
	var idx = 1
	for row in data.tt:
		for txt in row:
			$Grid.add_child(get_item_label(String(txt), idx > data.inputs.size()))
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
	hbox.get_child(1).text = "Close"
	hbox.add_child_below_node(hbox.get_child(0), tb)
	hbox.add_child_below_node(tb, hbox.get_child(0).duplicate())
	tb.connect("pressed", self, "run_test")


func run_test():
	emit_signal("test_pressed")
