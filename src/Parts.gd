extends Control

func get_part(idx: int, group: int):
	var node: Part = get_child(group).get_child(idx).duplicate()
	node.type = node.name
	node.group = group
	node.index = idx
	node.setup()
	return node
