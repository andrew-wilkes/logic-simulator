extends VBoxContainer

enum { NOACTION, NEW, OPEN, SAVE, SAVEAS, SETTINGS, QUIT, ABOUT, LICENCES }

signal test_completed(passed)

const USER_DATA = "user://user-data.dat"

var part_menu_scene = preload("res://PartMenu.tscn")

var selected_nodes = {}
var file_name = ""
var changed = false
var action = NOACTION
var fm
var hm
var part_group = 0
var part_data
var pm
var part_button
var part_placement_offsets = {}
var user: User

func _ready():
	Parts.hide()
	load_user_data()
	fm = $M/Topbar/V/H/File.get_popup()
	fm.add_item("New", NEW, KEY_MASK_CTRL | KEY_N)
	fm.add_item("Open", OPEN, KEY_MASK_CTRL | KEY_O)
	fm.add_separator()
	fm.add_item("Save", SAVE, KEY_MASK_CTRL | KEY_S)
	fm.add_item("Save As...", SAVEAS, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_S)
	fm.add_separator()
	fm.add_item("Quit", QUIT, KEY_MASK_CTRL | KEY_Q)
	fm.connect("id_pressed", self, "_on_FileMenu_id_pressed")
	pm = part_menu_scene.instance()
	$M/Topbar.add_child_below_node($M/Topbar/Left, pm)
	pm.connect("part_selected", self, "add_part")
	var i = InputEventKey.new()
	i.alt = true
	i.scancode = KEY_F
	$M/Topbar/V/H/File.shortcut = i # shortcut doesn't work
	hm = $M/Topbar/V/H/Help.get_popup()
	hm.add_item("About", ABOUT, KEY_MASK_CTRL | KEY_A)
	hm.add_separator()
	hm.add_item("Licences", LICENCES)
	hm.connect("id_pressed", self, "_on_HelpMenu_id_pressed")
	var h = InputEventKey.new()
	h.alt = true
	h.scancode = KEY_H
	$M/Topbar/V/H/Help.shortcut = h
	

var test_count = 0
var display_row = 1
var show_row = true
var passed_tests = true
var input_pins = {}
var output_pins = {}
var new_test = true

func start_tests(_data):
	part_data = _data
	input_pins = {}
	output_pins = {}
	# Find input pins
	for node in $Graph.get_children():
		if node is Part and node.type == Parts.TYPES.INPUTPIN:
			var pin = node.get_pin_name()
			if _data.inputs.has(pin):
				input_pins[pin] = node
	$c/TruthTable.highlight_inputs(input_pins.keys(), _data.inputs)
	if input_pins.size() != _data.inputs.size():
		alert("Missing input pins")
		yield($c/Alert, "popup_hide")
		$c/TruthTable.unhighlight_all()
		return
	# Find output pins
	for node in $Graph.get_children():
		if node is Part and node.type == Parts.TYPES.OUTPUTPIN:
			var pin = node.get_pin_name()
			if _data.outputs.has(pin):
				output_pins[pin] = node
	$c/TruthTable.highlight_outputs(output_pins.keys(), _data.inputs, _data.outputs)
	if output_pins.size() != _data.outputs.size():
		alert("Missing output pins")
		yield($c/Alert, "popup_hide")
		$c/TruthTable.unhighlight_all()
		return
	test_count = 0
	display_row = 1
	passed_tests = true
	new_test = true
	$TestTimer.start()


func _on_TestTimer_timeout():
	if not passed_tests:
		show_test_result(passed_tests, "Failed Tests")
		return
	if test_count == part_data.tt.size():
		show_test_result(true, "Passed Tests")
		if part_data.locked:
			part_button.modulate = Color.white
			if not User.data.unlocked.has(part_data.type):
				User.data.unlocked.append(part_data.type)
				save_user_data()
		return
	if new_test:
		show_row = $c/TruthTable/Grid.columns == part_data.tt[test_count].size()
		reset_race_detection()
		for idx in part_data.inputs.size():
			var x = part_data.tt[test_count][idx]
			if x is String:
				match x:
					"X":
						x = randi() % 2
					"+":
						x = 1
					"-":
						x = 0
			input_pins[part_data.inputs[idx]].set_output(bool(x), 0)
			if show_row:
				$c/TruthTable.highlight_value(display_row, idx, true)
		new_test = false
	else:
		# Check result
		var offset = part_data.inputs.size()
		for idx in part_data.outputs.size():
			var wanted = part_data.tt[test_count][idx + offset]
			var last_value = output_pins[part_data.outputs[idx]].last_value
			var got = output_pins[part_data.outputs[idx]].get_value()
			if wanted is String:
				match wanted:
					"X":
						wanted = got
					"L":
						wanted = last_value
			var result = wanted == got
			if show_row:
				$c/TruthTable.highlight_value(display_row, idx + offset, result)
			if not result:
				passed_tests = result
		new_test = true
		test_count += 1
		if show_row:
			display_row += 1
	$TestTimer.start()


func show_test_result(passed: bool, txt: String):
	emit_signal("test_completed", passed)
	alert(txt)
	yield($c/Alert, "popup_hide")
	$c/TruthTable.unhighlight_all()


# A bus output node value has changed
func update_bus(node, value, reverse = false):
	for con in $Graph.get_connection_list():
		if reverse:
			if con.to == node.name:
				$Graph.get_node(con.from).set_value(value, reverse, false)
		else:
			if con.from == node.name:
				$Graph.get_node(con.to).set_value(value, reverse, false)


# A part output level has changed
func update_levels(node, port, level, reverse = false):
	if node.group == 0:
		reset_race_detection()
	for con in $Graph.get_connection_list():
		if reverse:
			if con.to == node.name and con.to_port == port:
				$Graph.get_node(con.from).set_input(level, con.from_port, reverse)
		else:
			if con.from == node.name and con.from_port == port:
				$Graph.get_node(con.to).set_input(level, con.to_port)


func reset_race_detection():
	unselect_all()
	var nodes = $Graph.get_children()
	for node in nodes:
		if node is GraphNode:
			node.reset()


func delete_wire(node, port):
	alert("Unstable connection deleted.")
	for con in $Graph.get_connection_list():
		if con.to == node.name and con.to_port == port:
			$Graph.disconnect_node(con.from, con.from_port, con.to, con.to_port)


func add_part(part_name: String, _button):
	part_button = _button
	var part: Part = Parts.get_part(part_name)
	assert(part.type > 0)
	if tt_show_request(part):
		return
	if part.locked and part.has_tt and not User.data.unlocked.has(part.type):
		$c/TruthTable.open(part)
		alert("Create the circuit and succesfully test it to unlock the part.")
	else:
		add_part_to_graph(part, Vector2(get_viewport().get_mouse_position().x, get_part_placement_offset(part.type)))


func get_part_placement_offset(id):
	if part_placement_offsets.has(id):
		part_placement_offsets[id] = wrapi(part_placement_offsets[id] + $Graph.snap_distance, 0, 100)
	else:
		part_placement_offsets[id] = 0
	return part_placement_offsets[id]


func tt_show_request(part):
	var shown = false
	if part.has_tt and $M/Topbar/TTSelect.pressed:
		$M/Topbar/TTSelect.pressed = false
		$c/TruthTable.open(part)
		shown = true
	return shown


func add_part_to_graph(part: Part, pos: Vector2):
	$Graph.add_child(part, true) # Use a legible_unique_name to ensure that node name is saved and loaded ok
	part.offset = pos
	call_deferred("unselect_all")
	set_changed()
	connect_part(part)
	part.dropped()


func connect_part(part):
	var _e = part.connect("output_changed", self, "update_levels")
	_e = part.connect("unstable", self, "delete_wire")
	_e = part.connect("offset_changed", self, "set_changed")
	_e = part.connect("part_clicked", self, "tt_show_request")
	_e = part.connect("data_changed", self, "set_changed")
	if part is BUS:
		_e = part.connect("bus_changed", self, "update_bus")
	if part.type == Parts.TYPES.INPUT or part.type == Parts.TYPES.OUTPUT:
		_e = part.connect("part_variant_selected", self, "add_part_to_graph")


func remove_connections_to_node(node):
	for con in $Graph.get_connection_list():
		if con.to == node.name or con.from == node.name:
			$Graph.disconnect_node(con.from, con.from_port, con.to, con.to_port)


func _on_Graph_connection_request(from, from_slot, to, to_slot):
	# Don't connect between OUTBUS and INBUS or BUS to BUS
	if $Graph.get_node(to).type == Parts.TYPES.INBUS and $Graph.get_node(from).type == Parts.TYPES.OUTBUS:
		return
	# Don't connect to input that is already connected unless it's a BUS or INPUT
	var node = $Graph.get_node(to)
	if node.type != Parts.TYPES.BUS1 and node.group != Parts.TYPES.INPUT:
		for con in $Graph.get_connection_list():
			if con.to == to and con.to_port == to_slot:
				return
	$Graph.connect_node(from, from_slot, to, to_slot)
	set_changed()


func _on_Graph_disconnection_request(from, from_slot, to, to_slot):
	$Graph.disconnect_node(from, from_slot, to, to_slot)
	set_changed()


func _on_Graph_delete_nodes_request():
	for node in selected_nodes.keys():
		if selected_nodes[node]:
			remove_connections_to_node(node)
			node.queue_free()
			set_changed()
	selected_nodes = {}


func unselect_all():
	if Input.is_key_pressed(KEY_CONTROL) or Input.is_key_pressed(KEY_SHIFT):
		return
	selected_nodes = {}
	$Graph.set_selected(null)


func _on_Graph_node_selected(node):
	if node == null:
		breakpoint
	selected_nodes[node] = true


func _on_Graph_node_unselected(node):
	selected_nodes[node] = false


func _on_File_button_down():
	fm.show()


func _on_FileMenu_id_pressed(id):
	action = id
	match id:
		NEW: 
			confirm_loss()
		OPEN:
			confirm_loss()
		SAVE:
			do_action()
		SAVEAS:
			set_filename()
			action = SAVE
			do_action()
		QUIT:
			get_tree().quit()


func _on_HelpMenu_id_pressed(id):
	match id:
		ABOUT:
			$c/About.popup_centered()
		LICENCES:
			$c/Licences.popup_centered()


func confirm_loss():
	if changed:
		$c/Confirm.dialog_text = "Changes will be lost!"
		$c/Confirm.popup_centered()
	else:
		do_action()


func _on_Confirm_confirmed():
	do_action()


func do_action():
	match action:
		NEW:
			set_changed(false)
			set_filename()
			clear_graph()
		OPEN:
			$c/FileDialog.current_file = file_name
			$c/FileDialog.mode = FileDialog.MODE_OPEN_FILE
			$c/FileDialog.popup_centered()
		SAVE:
			if file_name == "":
				$c/FileDialog.current_file = file_name
				$c/FileDialog.mode = FileDialog.MODE_SAVE_FILE
				$c/FileDialog.popup_centered()
			else:
				save_data()


func clear_graph():
	$Graph.clear_connections()
	var nodes = $Graph.get_children()
	for node in nodes:
		if node is GraphNode:
			node.queue_free()


func _on_FileDialog_file_selected(path: String):
	if path.rstrip("/") == path.get_base_dir():
		alert("No filename was specified")
		return
	set_filename(path)
	if action == SAVE:
		save_data()
	else:
		load_data()


func set_filename(fn = ""):
	file_name = fn
	$M/Topbar/V/CurrentFile.text = fn.get_file()


func set_changed(status = true):
	changed = status
	$M/Topbar/V/CurrentFile.modulate = Color.orangered if status else Color.greenyellow


func save_user_data():
	var file = File.new()
	file.open(USER_DATA, File.WRITE)
	file.store_var(user, true)
	file.close()


func save_data():
	var circuit = Circuit.new()
	circuit.txt = "Test"
	circuit.connections = $Graph.get_connection_list()
	for node in $Graph.get_children():
		if node is GraphNode:
			var node_data = PartData.new()
			node_data.name = node.name
			node_data.type = Parts.get_type_name(node.type)
			node_data.offset = node.offset
			node_data.data = node.data
			circuit.nodes.append(node_data)
			#circuit["nodes"].append({ "type": Parts.get_type_name(node.type), "name": node.name, "x": node.offset.x, "y": node.offset.y, "depth": node.depth, "data": node.data })
	if ResourceSaver.save(file_name, circuit) == OK:
		set_changed(false)
	else:
		alert("Error saving circuit")
	action = NOACTION


func load_user_data():
	var file = File.new()
	if file.file_exists(USER_DATA):
		file.open(USER_DATA, File.READ)
		user = file.get_var(true)
		file.close()
	else:
		user = User.new()


func load_data():
	$c/Alert.dialog_text = "Error loading circuit"
	if ResourceLoader.exists(file_name):
		var circuit = ResourceLoader.load(file_name)
		if circuit is Circuit:
			init_graph(circuit)
			set_changed(false)
		else:
			alert()
	else:
		alert()
	action = NOACTION


func init_graph(circuit: Circuit):
	clear_graph()
	for node in circuit.nodes:
		var part: Part = Parts.get_part(node.type)
		part.offset = node.offset
		# A non-connected part seems to have a name containing @ marks
		# But when it is added to the scene, the @ marks are removed
		$Graph.add_child(part, true)
		part.data = node.data
		call_deferred("check_for_at_marks")
		connect_part(part)
		part.dropped()
		part.name = node.name
		if node.depth > 0:
			for n in node.depth:
				part.add_slots()
		for con in circuit.connections:
			var _e = $Graph.connect_node(con.from, con.from_port, con.to, con.to_port)


func alert(txt = ""):
	if txt != "":
		$c/Alert.dialog_text = txt
	$c/Alert.popup_centered()


func hide_alert():
	$c/Alert.hide()


func _on_Up_button_down():
	pm.select_menu(1)


func _on_Down_button_down():
	pm.select_menu(-1)


func _on_Main_tree_exiting():
	save_user_data()


# Timing
var time_before

func start_timing():
	time_before = OS.get_ticks_usec()

func end_timing():
	var time_taken = OS.get_ticks_usec() - time_before
	print("Took ", time_taken, " microseconds")


func check_for_at_marks():
	for node in $Graph.get_children():
		if node is Part:
			if "@" in node.name:
				alert("@ found in: " + node.name)
