extends VBoxContainer

enum { NOACTION, NEW, OPEN, SAVE, SAVEAS }

var part_menu_scene = preload("res://PartMenu.tscn")

var selected_nodes = {}
var file_name = ""
var changed = false
var action = NOACTION
var fm
var data = {}
var part_group = 0
var pm

func _ready():
	Parts.hide()
	fm = $M/Topbar/V/H/File/FileMenu
	fm.add_item("New", NEW)
	fm.add_item("Open", OPEN)
	fm.add_item("Save", SAVE)
	fm.add_item("Save As...", SAVEAS)
	pm = part_menu_scene.instance()
	$M/Topbar.add_child_below_node($M/Topbar/Left, pm)
	pm.connect("part_selected", self, "add_part")
	$TruthTable.popup_centered()


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
	if node.type == "INPUT":
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
	$Alert.dialog_text = "Unstable connection deleted."
	$Alert.popup_centered()
	for con in $Graph.get_connection_list():
		if con.to == node.name and con.to_port == port:
			$Graph.disconnect_node(con.from, con.from_port, con.to, con.to_port)


func add_part(idx: int, pg: int):
	part_group = pg
	var part: Part = Parts.get_part(idx, pg)
	$Graph.add_child(part, true) # Use a legible_unique_name to ensure that node name is saved and loaded ok
	part.offset = Vector2(get_viewport().get_mouse_position().x, $Graph.get_snap() * (1 + randi() % 5))
	set_changed()
	connect_part(part)


func connect_part(part):
	var _e = part.connect("output_changed", self, "update_levels")
	_e = part.connect("unstable", self, "delete_wire")
	_e = part.connect("offset_changed", self, "set_changed")
	_e = part.connect("mouse_entered", self, "unselect_all")
	if part is BUS:
		_e = part.connect("bus_changed", self, "update_bus")


func remove_connections_to_node(node):
	for con in $Graph.get_connection_list():
		if con.to == node.name or con.from == node.name:
			$Graph.disconnect_node(con.from, con.from_port, con.to, con.to_port)


func _on_Graph_connection_request(from, from_slot, to, to_slot):
	# Don't connect between OUTBUS and INBUS or BUS to BUS
	if $Graph.get_node(to).type == "INBUS" and $Graph.get_node(from).type == "OUTBUS":
		return
	# Don't connect to input that is already connected unless it's a BUS or INPUT
	var node = $Graph.get_node(to)
	if not node is BUS and node.type != "INPUT":
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


func unselect_all():
	if Input.is_key_pressed(KEY_CONTROL) or Input.is_key_pressed(KEY_SHIFT):
		return
	selected_nodes = {}
	$Graph.set_selected(null)


func _on_Graph_node_selected(node):
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
			file_name = ""
			action = SAVE
			do_action()


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
			file_name = ""
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
		$Alert.dialog_text = "No filename was specified"
		$Alert.popup_centered()
		return
	if action == SAVE:
		save_data()
		set_filename(path)
	else:
		load_data()


func set_filename(fn = ""):
	file_name = fn
	$M/Topbar/V/CurrentFile.text = fn.get_file()


func set_changed(status = true):
	changed = status
	$M/Topbar/V/CurrentFile.modulate = Color.orangered if status else Color.greenyellow


func save_data():
	data["connections"] = $Graph.get_connection_list()
	data["nodes"] = []
	for node in $Graph.get_children():
		if node is GraphNode:
			data["nodes"].append({ "type": node.type, "index": node.index, "group": node.group, "name": node.name, "x": node.offset.x, "y": node.offset.y, "depth": node.depth })
	var file = File.new()
	file.open(file_name, File.WRITE)
	file.store_string(to_json(data))
	file.close()
	set_changed(false)
	action = NOACTION


func load_data():
	var file = File.new()
	$Alert.dialog_text = "Error loading data"
	if file.file_exists(file_name):
		file.open(file_name, File.READ)
		var data_in = parse_json(file.get_as_text())
		file.close()
		if typeof(data_in) == TYPE_DICTIONARY:
			data = data_in
			init_graph()
			set_filename(file_name)
			set_changed(false)
		else:
			$Alert.popup_centered()
	else:
		$Alert.popup_centered()
	action = NOACTION

func init_graph():
	clear_graph()
	if data.has("nodes"):
		for node in data.nodes:
			var part: Part = Parts.get_part(node.index, node.group)
			part.offset = Vector2(node.x, node.y)
			# A non-connected part seems to have a name containing @ marks
			# But when it is added to the scene, the @ marks are removed
			$Graph.add_child(part, true)
			connect_part(part)
			part.name = node.name
			if node.depth > 0:
				for n in node.depth:
					part.add_slots()
		if data.has("connections"):
			for con in data.connections:
				var _e = $Graph.connect_node(con.from, con.from_port, con.to, con.to_port)


func _on_FileMenu_mouse_exited():
	$M/Topbar/V/H/File/FileMenu.hide()


func _on_Up_button_down():
	pm.select_menu(1)


func _on_Down_button_down():
	pm.select_menu(-1)
