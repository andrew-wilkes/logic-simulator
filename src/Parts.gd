extends Control

func get_part(part_name: String):
	var part = find_node(part_name).duplicate()
	part.type = part_name
	part.has_tt = Data.parts.has(part.type)
	part.setup()
	return part
