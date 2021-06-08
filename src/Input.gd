extends Part

signal part_variant_selected(part, pos)

func _ready():
	if type == Parts.INPUT:
		for node in get_children():
			if node is Control:
				node.connect("gui_input", self, "_on_gui_input", [node])
			for child in node.get_children():
				if child is Button:
					child.focus_mode = Control.FOCUS_NONE


func _on_gui_input(event, node):
	if event is InputEventMouseButton:
		node.index = node.get_parent().index
		node.subidx = node.get_index()
		node.setup()
		if node.get_child(0).name == "V":
			node.set_value(0)
		remove_child(node)
		emit_signal("part_variant_selected", node, offset)
		queue_free()


func set_value(value: int, reverse = false, _from_pin = false):
	get_child(0).text = "0x%02X" % value
	emit_signal("bus_changed", self, value, reverse)
	var num_bits = 4 if type == Parts.INPUT4 else 8
	for n in num_bits:
		var level = bool(value % 2)
		value /= 2
		set_output(level, n + 1, reverse)


func _on_Pin_text_changed(_new_text):
	emit_signal("offset_changed")
