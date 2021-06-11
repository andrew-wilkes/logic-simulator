extends VBoxContainer

enum { NOACTION, NEW, OPEN, SAVE, SAVEAS, SETTINGS, QUIT }

const USER_DATA = "user://score.json"

var part_menu_scene = preload("res://PartMenu.tscn")

var selected_nodes = {}
var file_name = ""
var changed = false
var action = NOACTION
var fm
var circuit = {}
var part_group = 0
var part_data
var pm
var part_button
var part_placement_offsets = {}

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
	$M/Topbar/V/H/File.shortcut = i

var test_count = 0
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
		if node is Part and node.type == Parts.INPUTPIN:
			var pin = node.get_pin_name()
			if _data.inputs.has(pin):
				input_pins[pin] = node
	$TruthTable.highlight_inputs(input_pins.keys(), _data.inputs)
	if input_pins.size() != _data.inputs.size():
		alert("Missing input pins")
		yield($Alert, "popup_hide")
		$TruthTable.unhighlight_all()
		return
	# Find output pins
	for node in $Graph.get_children():
		if node is Part and node.type == Parts.OUTPUTPIN:
			var pin = node.get_pin_name()
			if _data.outputs.has(pin):
				output_pins[pin] = node
	$TruthTable.highlight_outputs(output_pins.keys(), _data.inputs, _data.outputs)
	if output_pins.size() != _data.outputs.size():
		alert("Missing output pins")
		yield($Alert, "popup_hide")
		$TruthTable.unhighlight_all()
		return
	test_count = 0
	passed_tests = true
	new_test = true
	$TestTimer.start()


func _on_TestTimer_timeout():
	if show_test_result(not passed_tests, "Failed Tests"):
		return
	if show_test_result(test_count == part_data.tt.size(), "Passed Tests"):
		if part_data.locked:
			part_button.modulate = Color.white
			if not User.data.unlocked.has(part_data.id):
				User.data.unlocked.append(part_data.id)
				save_user_data()
		return
	if new_test:
		reset_race_detection()
		# Apply input values
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
			$TruthTable.highlight_value(test_count + 1, idx, true)
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
			$TruthTable.highlight_value(test_count + 1, idx + offset, result)
			if not result:
				passed_tests = result
		new_test = true
		test_count += 1
	$TestTimer.start()


func show_test_result(ok: bool, txt: String) -> bool:
	if ok:
		alert(txt)
		yield($Alert, "popup_hide")
		$TruthTable.unhighlight_all()
	else:
		ok = false
	return ok


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


func add_part(idx: int, pg: int, _button):
	part_button = _button
	part_group = pg
	var part: Part = Parts.get_part(idx, pg)
	if tt_show_request(part):
		return
	if part.locked and part.has_tt and not User.data.unlocked.has(part.id):
		$TruthTable.open(part)
		alert("Create the circuit and succesfully test it to unlock the part.")
	else:
		add_part_to_graph(part, Vector2(get_viewport().get_mouse_position().x, get_part_placement_offset(part.id)))


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
		$TruthTable.open(part)
		shown = true
	return shown


func add_part_to_graph(part: Part, pos: Vector2):
	$Graph.add_child(part, true) # Use a legible_unique_name to ensure that node name is saved and loaded ok
	part.offset = pos
	call_deferred("unselect_all")
	set_changed()
	connect_part(part)


func connect_part(part):
	var _e = part.connect("output_changed", self, "update_levels")
	_e = part.connect("unstable", self, "delete_wire")
	_e = part.connect("offset_changed", self, "set_changed")
	_e = part.connect("part_clicked", self, "tt_show_request")
	if part is BUS:
		_e = part.connect("bus_changed", self, "update_bus")
	if part.type == Parts.INPUT or part.type == Parts.OUTPUT:
		_e = part.connect("part_variant_selected", self, "add_part_to_graph")


func remove_connections_to_node(node):
	for con in $Graph.get_connection_list():
		if con.to == node.name or con.from == node.name:
			$Graph.disconnect_node(con.from, con.from_port, con.to, con.to_port)


func _on_Graph_connection_request(from, from_slot, to, to_slot):
	# Don't connect between OUTBUS and INBUS or BUS to BUS
	if $Graph.get_node(to).type == Parts.INBUS and $Graph.get_node(from).type == Parts.OUTBUS:
		return
	# Don't connect to input that is already connected unless it's a BUS or INPUT
	var node = $Graph.get_node(to)
	if node.type != Parts.BUS1 and node.group != Parts.INPUT:
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


func _on_Help_button_down():
	$About.popup_centered()


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


func confirm_loss():
	if changed:
		$Confirm.dialog_text = "Changes will be lost!"
		$Confirm.popup_centered()
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
			$FileDialog.current_file = file_name
			$FileDialog.mode = FileDialog.MODE_OPEN_FILE
			$FileDialog.popup_centered()
		SAVE:
			if file_name == "":
				$FileDialog.current_file = file_name
				$FileDialog.mode = FileDialog.MODE_SAVE_FILE
				$FileDialog.popup_centered()
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
	file.store_string(to_json(User.data))
	file.close()


func save_data():
	circuit["connections"] = $Graph.get_connection_list()
	circuit["nodes"] = []
	for node in $Graph.get_children():
		if node is GraphNode:
			if node.type == Parts.INPUTPIN or node.type == Parts.OUTPUTPIN:
				node.data = node.get_pin_name()
			circuit["nodes"].append({ "type": node.type, "index": node.index, "group": node.group, "subidx": node.subidx, "name": node.name, "x": node.offset.x, "y": node.offset.y, "depth": node.depth, "data": node.data })
	var file = File.new()
	file.open(file_name, File.WRITE)
	if file.is_open():
		file.store_string(to_json(circuit))
		file.close()
		set_changed(false)
	action = NOACTION


func load_user_data():
	var file = File.new()
	if file.file_exists(USER_DATA):
		file.open(USER_DATA, File.READ)
		var data_in = parse_json(file.get_as_text())
		file.close()
		if typeof(data_in) == TYPE_DICTIONARY:
			User.data = data_in


func load_data():
	var file = File.new()
	$Alert.dialog_text = "Error loading circuit"
	if file.file_exists(file_name):
		file.open(file_name, File.READ)
		var data_in = parse_json(file.get_as_text())
		file.close()
		if typeof(data_in) == TYPE_DICTIONARY:
			circuit = data_in
			init_graph()
			set_filename(file_name)
			set_changed(false)
		else:
			alert()
	else:
		alert()
	action = NOACTION

func init_graph():
	clear_graph()
	if circuit.has("nodes"):
		for node in circuit.nodes:
			for prop in ["index", "group", "subidx", "depth", "data"]:
				if not node.keys().has(prop):
					node[prop] = 0
			var part: Part = Parts.get_part(node.index, node.group, node.subidx)
			part.offset = Vector2(node.x, node.y)
			if part.type == Parts.INPUTPIN or part.type == Parts.OUTPUTPIN:
				part.set_pin_name(node.data)
			# A non-connected part seems to have a name containing @ marks
			# But when it is added to the scene, the @ marks are removed
			$Graph.add_child(part, true)
			call_deferred("check_for_at_marks")
			part.setup()
			connect_part(part)
			part.name = node.name
			if node.depth > 0:
				for n in node.depth:
					part.add_slots()
		if circuit.has("connections"):
			for con in circuit.connections:
				var _e = $Graph.connect_node(con.from, con.from_port, con.to, con.to_port)


func alert(txt = ""):
	if txt != "":
		$Alert.dialog_text = txt
	$Alert.popup_centered()


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
