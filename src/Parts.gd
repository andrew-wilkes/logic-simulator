extends Control

func get_part(idx: int, group: int, subidx = 0):
	var node: Part
	if subidx > 0:
		node = get_child(group).get_child(idx).get_child(subidx).duplicate()
	else:
		node = get_child(group).get_child(idx).duplicate()
	node.type = node.name
	node.group = group
	node.index = idx
	node.subidx = subidx
	node.setup()
	return node
