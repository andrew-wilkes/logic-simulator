extends Part

signal part_variant_selected(part, pos)

func _ready():
	if name == "INPUT":
		for node in get_children():
			if node is Control:
				node.connect("gui_input", self, "_on_gui_input", [node])
			for child in node.get_children():
				if child is Button:
					child.focus_mode = Control.FOCUS_NONE


func _on_gui_input(event, node):
	if event is InputEventMouseButton:
		node.type = node.name
		node.setup()
		remove_child(node)
		emit_signal("part_variant_selected", node, offset)
		queue_free()
