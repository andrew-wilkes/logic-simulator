extends VBoxContainer

enum { NOACTION, NEW, OPEN, OPENB, SAVE, SAVEAS, SETTINGS, QUIT, ABOUT, LICENCES, MANUAL }

signal test_completed(passed)

const USER_DATA = "user://user-data.dat"

var part_menu_scene = preload("res://PartMenu.tscn")
var block_scene = preload("res://parts/Block.tscn")

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
	fm.add_item("Open as block", OPENB, KEY_MASK_CTRL | KEY_B)
	fm.add_separator()
	fm.add_item("Save", SAVE, KEY_MASK_CTRL | KEY_S)
	fm.add_item("Save As...", SAVEAS, KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_S)
	fm.add_separator()
	fm.add_item("Quit", QUIT, KEY_MASK_CTRL | KEY_Q)
	fm.connect("id_pressed", self, "_on_FileMenu_id_pressed")
	pm = part_menu_scene.instance()
	$M/Topbar/H.add_child_below_node($M/Topbar/H/Left, pm)
	pm.connect("part_selected", self, "add_part")
	var i = InputEventKey.new()
	i.alt = true
	i.scancode = KEY_F
	$M/Topbar/V/H/File.shortcut = i # shortcut doesn't work
	hm = $M/Topbar/V/H/Help.get_popup()
	hm.add_item("About", ABOUT, KEY_MASK_CTRL | KEY_A)
	hm.add_item("Manual", MANUAL, KEY_MASK_CTRL | KEY_M)
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
		if node is Part and (node.type == "INPUTPIN" or node.type == "INPUTBUS"):
			var pin_name = node.data.tag
			if _data.inputs.has(pin_name):
				input_pins[pin_name] = node
	# Add missing pins
	var i = 0
	for pin_name in _data.inputs:
		var input_pin
		if not input_pins.keys().has(pin_name):
			if part_data.part.get_connection_input_type(i) == 1:
				input_pin = Parts.get_part("INPUTBUS")
			else:
				input_pin = Parts.get_part("INPUTPIN")
			input_pin.set_pin_name(pin_name)
			input_pins[pin_name] = input_pin
			add_part_to_graph(input_pin, Vector2(get_viewport().size.x * 0.3, 50 + i * 100) + $Graph.scroll_offset)
		i += 1
	$c/TruthTable.highlight_inputs(input_pins.keys(), _data.inputs)
	# Find output pins
	for node in $Graph.get_children():
		if node is Part and (node.type == "OUTPUTPIN" or node.type == "OUTPUTBUS"):
			var pin = node.data.tag
			if _data.outputs.has(pin):
				output_pins[pin] = node
				node.last_value = 0
				node.value = 0
	# Add missing pins
	i = 0
	for pin_name in _data.outputs:
		var output_pin
		if not output_pins.keys().has(pin_name):
			if part_data.part.get_connection_output_type(i) == 1:
				output_pin = Parts.get_part("OUTPUTBUS")
			else:
				output_pin = Parts.get_part("OUTPUTPIN")
			output_pin.set_pin_name(pin_name)
			output_pins[pin_name] = output_pin
			add_part_to_graph(output_pin, Vector2(get_viewport().size.x * 0.7, 50 + i * 100) + $Graph.scroll_offset)
		i += 1
	$c/TruthTable.highlight_outputs(output_pins.keys(), _data.inputs, _data.outputs)
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
		show_row = $c/TruthTable.grid.columns == part_data.tt[test_count].size()
		reset_race_detection()
		for idx in part_data.inputs.size():
			var x = part_data.tt[test_count][idx]
			if x is String:
				if x.is_valid_hex_number(true):
					x = x.hex_to_int()
				else:
					match x:
						"X":
							x = randi() % 2
						"+":
							x = 1
						"-":
							x = 0
			var node = input_pins[part_data.inputs[idx]]
			if node.output_pins[0].type == 0:
				node.set_output(bool(x), 0)
			else:
				node.set_value(x, false, 0)
			if show_row:
				$c/TruthTable.highlight_value(display_row, idx, true)
		new_test = false
	else:
		# Check result
		var offset = part_data.inputs.size()
		for idx in part_data.outputs.size():
			var wanted = part_data.tt[test_count][idx + offset]
			# Output pin only has input pin
			var pin = output_pins[part_data.outputs[idx]]
			var last_value: int
			var got: int
			if pin.input_pins[0].type == 0:
				last_value = int(pin.input_pins[0].last_level)
				got = int(pin.input_pins[0].level)
			else:
				last_value = pin.last_value
				got = pin.value
			if wanted is String:
				if wanted.is_valid_hex_number(true):
					wanted = wanted.hex_to_int()
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
				$Graph.get_node(con.from).set_value(value, reverse)
		else:
			if con.from == node.name:
				$Graph.get_node(con.to).set_value(value, reverse, con.to_port)


# A part output level has changed
func update_levels(node, port, level, reverse = false):
	if node.is_input:
		reset_race_detection()
	for con in $Graph.get_connection_list():
		if reverse:
			if con.to == node.name and con.to_port == port:
				$Graph.get_node(con.from).apply_input(level, con.from_port, reverse)
		else:
			if con.from == node.name and con.from_port == port:
				$Graph.get_node(con.to).apply_input(level, con.to_port, reverse)


func reset_race_detection():
	unselect_all()
	var nodes = $Graph.get_children()
	for node in nodes:
		if node is GraphNode:
			node.reset()


func apply_all_inputs():
	var nodes = $Graph.get_children()
	for node in nodes:
		if node is GraphNode and not node.is_input:
			apply_outputs(node)
	for node in nodes:
		if node is GraphNode and node.is_input:
			apply_outputs(node)


func apply_outputs(node):
			for idx in node.output_pins.size():
				var p = node.output_pins[idx]
				if p.type == 0:
					update_levels(node, idx, p.level, false)
				else:
					update_bus(node, 0, false)
			if node.is_reversible_input:
				# Only port 0 is used
				update_levels(node, 0, false, true)


func delete_wire(node, port, reverse):
	alert("Unstable connection deleted.")
	for con in $Graph.get_connection_list():
		if reverse:
			if con.from != node.name or con.from_port != port:
				continue
		else:
			if con.to != node.name or con.to_port != port:
				continue
		$Graph.disconnect_node(con.from, con.from_port, con.to, con.to_port)
		break


func add_part(part_name: String, _button):
	part_button = _button
	var part: Part = Parts.get_part(part_name)
	if tt_show_request(part):
		return
	if part.locked and part.has_tt and not User.data.unlocked.has(part.type):
		$c/TruthTable.open(part)
		alert("Create the circuit and succesfully test it to unlock the part.")
	else:
		add_part_to_graph(part, Vector2(get_viewport().get_mouse_position().x, get_part_placement_offset(part.type) + 20) + $Graph.scroll_offset)


func connect_part(part):
	var _e = part.connect("gui_input", part, "mouse_action")
	_e = part.connect("mouse_entered", part, "part_entered")
	_e = part.connect("mouse_exited", part, "part_exited")
	_e = part.connect("part_entered", self, "highlight_connected_pins")
	_e = part.connect("part_exited", self, "unhighlight_connected_pins")
	_e = part.connect("part_variant_selected", self, "add_part_to_graph")
	_e = part.connect("output_changed", self, "update_levels")
	_e = part.connect("unstable", self, "delete_wire")
	_e = part.connect("offset_changed", self, "set_changed")
	_e = part.connect("part_clicked", self, "tt_show_request")
	_e = part.connect("data_changed", self, "set_changed")
	_e = part.connect("bus_changed", self, "update_bus")


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


func remove_connections_to_node(node):
	for con in $Graph.get_connection_list():
		if con.to == node.name or con.from == node.name:
			$Graph.disconnect_node(con.from, con.from_port, con.to, con.to_port)


func highlight_connected_pins(node):
	for con in $Graph.get_connection_list():
		if con.to == node.name:
			var _pin = $Graph.get_node(con.from).set_pin_color(con.from_port, false, Color.orange)
			_pin = node.set_pin_color(con.to_port, true, Color.orange)
		var source_output_pin_not_set = true
		if con.from == node.name:
			var _pin = $Graph.get_node(con.to).set_pin_color(con.to_port, true, Color.orange)
			if source_output_pin_not_set:
				_pin = node.set_pin_color(con.from_port, false, Color.orange)
			source_output_pin_not_set = false


func unhighlight_connected_pins(node):
	for con in $Graph.get_connection_list():
		if con.to == node.name:
			var _pin = $Graph.get_node(con.from).reset_pin_color(con.from_port, false)
			_pin = node.reset_pin_color(con.to_port, true)
		var source_output_pin_not_reset = true
		if con.from == node.name:
			var _pin = $Graph.get_node(con.to).reset_pin_color(con.to_port, true)
			if source_output_pin_not_reset:
				_pin = node.reset_pin_color(con.from_port, false)
			source_output_pin_not_reset = false


func _on_Graph_connection_request(from, from_slot, to, to_slot):
	# Don't connect between OUTBUS and INBUS or BUS to BUS
	if $Graph.get_node(to).type == "INBUS" and $Graph.get_node(from).type == "OUTBUS":
		return
	if $Graph.get_node(to).type == "BUS1" and $Graph.get_node(from).type == "BUS1":
		return
	if $Graph.get_node(to).type == "LOOPBACK" and $Graph.get_node(from).type == "LOOPBACK":
		return
	# Don't connect to input that is already connected unless it's a BUS or INPUT
	var to_node = $Graph.get_node(to)
	if to_node.type != "BUS1" and to_node.type != "INPUT" and to_node.type != "LOOPBACK":
		for con in $Graph.get_connection_list():
			if con.to == to and con.to_port == to_slot: # Docs incorrect to_slot is a port
				return
	$Graph.connect_node(from, from_slot, to, to_slot)
	# Propagate level or value
	var from_node = $Graph.get_node(from)
	if to_node.get_connection_input_type(to_slot) == 0:
		if to_node.is_reversible_input:
			from_node.apply_input(to_node.input_pins[to_slot].level, from_slot, true)
		else:
			to_node.apply_input(from_node.output_pins[from_slot].level, to_slot, false)
	else:
		if to_node.is_reversible_input:
			from_node.set_value(to_node.value, true, from_slot)
		else:
			to_node.set_value(from_node.value, false, to_slot)
	set_changed()


func _on_Graph_disconnection_request(from, from_slot, to, to_slot):
	$Graph.disconnect_node(from, from_slot, to, to_slot)
	set_changed()


func _input(event):
	if event is InputEventKey:
		if event.scancode == KEY_DELETE and event.pressed:
			# Before adding _input to NumberInputPanel, could simply connect signal from GraphEdit
			# But now need this _input function in main
			_on_Graph_delete_nodes_request()


func _on_Graph_delete_nodes_request():
	for node in selected_nodes.keys():
		if selected_nodes[node]:
			remove_connections_to_node(node)
			if is_instance_valid(node):
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
		SAVE, OPENB:
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
		MANUAL:
			var _e = OS.shell_open("https://gdscript.com/downloads/digital-logic-simulator-manual/")
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

var open_as_block = false

func do_action():
	match action:
		NEW:
			set_changed(false)
			set_filename()
			clear_graph()
		OPEN:
			clear_graph()
			open_file_dialog()
		OPENB:
			open_as_block = true
			open_file_dialog()
		SAVE:
			if file_name == "":
				$c/FileDialog.current_file = file_name
				$c/FileDialog.mode = FileDialog.MODE_SAVE_FILE
				$c/FileDialog.popup_centered()
			else:
				save_data()


func open_file_dialog():
	$c/FileDialog.current_file = file_name
	$c/FileDialog.mode = FileDialog.MODE_OPEN_FILE
	$c/FileDialog.popup_centered()


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
		var circuit = load_data(file_name)
		if circuit is Circuit:
			init_graph(circuit)


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
	circuit.connections = $Graph.get_connection_list()
	circuit.scroll_offset = $Graph.scroll_offset
	circuit.zoom = $Graph.zoom
	circuit.snap_distance = $Graph.snap_distance
	circuit.use_snap = $Graph.use_snap
	circuit.minimap_enabled = $Graph.minimap_enabled
	for node in $Graph.get_children():
		if node is GraphNode:
			var node_data = PartData.new()
			node_data.name = node.name
			node_data.type = node.type
			node_data.offset = node.offset
			node_data.data = node.data
			circuit.nodes.append(node_data)
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


func load_data(fn):
	$c/Alert.dialog_text = "Error loading circuit"
	if ResourceLoader.exists(fn):
		var circuit = ResourceLoader.load(fn)
		if circuit is Circuit:
			return circuit
		else:
			alert()
	else:
		alert()
	action = NOACTION

var blocks = {}

func init_graph(circuit: Circuit):
	set_changed(false)
	if open_as_block:
		var block = block_scene.instance()
		$Graph.add_child(block, true)
		block.offset = $Graph.scroll_offset + Vector2(100, 100)
		block.add_pins(circuit, file_name)
		block.setup()
		block.data.source_file = file_name
		connect_part(block)
		open_as_block = false
		set_filename() # Avoid over-writing the cct. data
		return
	clear_graph()
	$Graph.zoom = circuit.zoom
	$Graph.snap_distance = circuit.snap_distance
	$Graph.use_snap = circuit.use_snap
	$Graph.minimap_enabled = circuit.minimap_enabled
	call_deferred("set_scroll_offset", circuit.scroll_offset)
	for node in circuit.nodes:
		var part: Part
		if node.type == "Block":
			if node.data.has("source_file"):
				var sub_circuit = load_data(node.data.source_file)
				if sub_circuit is Circuit:
					part = block_scene.instance()
					part.add_pins(sub_circuit, node.data.source_file)
					part.setup()
					part.data.source_file = node.data.source_file
					blocks[part.name] = part
		else:
			part = Parts.get_part(node.type)
		part.offset = node.offset
		# A non-connected part seems to have a name containing @ marks
		# But when it is added to the scene, the @ marks are removed
		$Graph.add_child(part, true)
		call_deferred("check_for_at_marks")
		connect_part(part)
		part.name = node.name
		part.data = node.data
		part.apply_data()
	yield(get_tree(), "idle_frame") # Get lots of out of range errors without this
	for con in circuit.connections:
		# Check for block that has missing connections
		if blocks.has(con.to):
			if blocks[con.to].inputs_to_add.size() <= con.to_port:
				blocks[con.to].set_overlay(2)
				continue
		if blocks.has(con.from):
			if blocks[con.from].outputs_to_add.size() <= con.from_port:
				blocks[con.from].set_overlay(2)
				continue
		var _e = $Graph.connect_node(con.from, con.from_port, con.to, con.to_port)
	apply_all_inputs()


func set_scroll_offset(offset: Vector2):
	$Graph.scroll_offset = offset


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


func _on_Graph_scroll_offset_changed(_ofs):
	set_changed()


func _on_Learn_pressed():
	var _e = get_tree().change_scene("res://Learn.tscn")
