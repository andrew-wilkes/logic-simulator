extends VBoxContainer

enum { NOACTION, NEW, OPEN, SAVE, SAVEAS }

var selected_nodes = {}
var file_name = ""
var changed = false
var action = NOACTION
var fm
var data = {}

func _ready():
	Parts.hide()
	fm = $M/Topbar/File/FileMenu
	fm.add_item("New", NEW)
	fm.add_item("Open", OPEN)
	fm.add_item("Save", SAVE)
	fm.add_item("Save As...", SAVEAS)


func update_levels(node, port, level):
	if node.group == "Inputs":
		reset_race_detection()
	for con in $Graph.get_connection_list():
		if con.from == node.name and con.from_port == port:
			$Graph.get_node(con.to).set_input(level, con.to_port)


func reset_race_detection():
	var nodes = $Graph.get_children()
	for node in nodes:
		if node is GraphNode:
			node.reset()


func add_part(type: String, group = "Gates"):
	var part: GraphNode = Parts.get_part(type, group)
	$Graph.add_child(part)
	part.offset.x = get_viewport().get_mouse_position().x
	changed = true
	var _e = part.connect("output_changed", self, "update_levels")


func remove_connections_to_node(node):
	for con in $Graph.get_connection_list():
		if con.to == node.name or con.from == node.name:
			$Graph.disconnect_node(con.from, con.from_port, con.to, con.to_port)


func _on_not_button_down():
	add_part("NOT")


func _on_and_button_down():
	add_part("AND")


func _on_nand_button_down():
	add_part("NAND")


func _on_or_button_down():
	add_part("OR")


func _on_nor_button_down():
	add_part("NOR")


func _on_xor_button_down():
	add_part("XOR")


func _on_Graph_connection_request(from, from_slot, to, to_slot):
	# Don't connect to input that is already connected
	for con in $Graph.get_connection_list():
		if con.to == to and con.to_port == to_slot:
			return
	$Graph.connect_node(from, from_slot, to, to_slot)
	changed = true


func _on_Graph_disconnection_request(from, from_slot, to, to_slot):
	$Graph.disconnect_node(from, from_slot, to, to_slot)
	changed = true


func _on_Graph_delete_nodes_request():
	for node in selected_nodes.keys():
		if selected_nodes[node]:
			remove_connections_to_node(node)
			node.queue_free()
			changed = true
	selected_nodes = {}


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
			changed = false
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
	file_name = path
	if action == SAVE:
		save_data()
	else:
		load_data()


func save_data():
	data["connections"] = $Graph.get_connection_list()
	data["nodes"] = []
	for node in $Graph.get_children():
		if node is GraphNode:
			data["nodes"].append({ "type": node.type, "group": node.group, "name": node.name, "x": node.offset.x, "y": node.offset.y })
	var file = File.new()
	file.open(file_name, File.WRITE)
	file.store_string(to_json(data))
	file.close()
	changed = false
	action = NOACTION


func load_data():
	var file = File.new()
	$Alert.dialog_text = "Error loading data"
	if file.file_exists(file_name):
		file.open(file_name, File.READ)
		var data_in = parse_json(file.get_as_text())
		file.close()
		if typeof(data) == TYPE_DICTIONARY:
			data = data_in
			changed = false
			init_graph()
		else:
			$Alert.popup_centered()
	else:
		$Alert.popup_centered()
	action = NOACTION


func init_graph():
	clear_graph()
	for node in data["nodes"]:
		var part: Part = Parts.get_part(node.type, node.group)
		part.offset = Vector2(node.x, node.y)
		part.name = node.name
		$Graph.add_child(part)
		var _e = part.connect("output_changed", self, "update_levels")
	for con in data.connections:
		var _e = $Graph.connect_node(con.from, con.from_port, con.to, con.to_port)


func _on_Test_button_down():
	add_part("INPUT", "Inputs")
