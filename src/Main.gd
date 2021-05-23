extends VBoxContainer

var selected_nodes = {}

func _ready():
	Parts.hide()


func add_part(name: String):
	var part: Control = Parts.get_node(name).duplicate()
	$Graph.add_child(part)
	part.offset.x = get_viewport().get_mouse_position().x

"""
func _input(event):
	if event.is_action_pressed("delete"):
		$Graph.
"""

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


func _on_Graph_disconnection_request(from, from_slot, to, to_slot):
	$Graph.disconnect_node(from, from_slot, to, to_slot)


func _on_Graph_delete_nodes_request():
	for node in selected_nodes.keys():
		if selected_nodes[node]:
			node.queue_free()
	selected_nodes = {}


func _on_Graph_node_selected(node):
	selected_nodes[node] = true


func _on_Graph_node_unselected(node):
	selected_nodes[node] = false
