extends Control

func get_part(part_name: String):
	var part = find_node(part_name).duplicate()
	part.type = part_name
	part.has_tt = Data.parts.has(part.type)
	part.setup()
	return part


func int2bin(x: int, nbits: int, prefix = "0b"):
	var b = ""
	for n in nbits:
		if n > 0 and n % 4 == 0:
			b = " " + b
		b = String(x % 2) + b
		x /= 2
	return prefix + b
