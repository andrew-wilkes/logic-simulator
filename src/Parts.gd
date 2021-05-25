extends HBoxContainer

func get_part(type, group):
	var node: Part = get_node(group).get_node(type).duplicate()
	node.type = node.name
	node.group = group
	return node
