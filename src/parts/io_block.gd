extends Part

class_name IoBlock

func _ready():
	._ready()
	# connect_inner_io_nodes
	for node in get_children():
		if node is Control:
			node.connect("gui_input", self, "on_inner_node_gui_input", [node])
		for child in node.get_children():
			if child is Button:
				child.focus_mode = Control.FOCUS_NONE


func on_inner_node_gui_input(event, node):
	if event is InputEventMouseButton:
		node.setup()
		node.type = node.name # This is the pure name used when loading a circuit
		if node.get_child(0).name == "V":
			node.set_value(0, false)
		remove_child(node)
		emit_signal("part_variant_selected", node, offset)
		queue_free() # Remove this IoBlock
