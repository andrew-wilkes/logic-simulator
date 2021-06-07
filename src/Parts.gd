#tool
extends Control

#func _ready():
#	get_enums()


enum { INPUT, INPUTSW, INPUTPUSH, INPUT4, INPUT8, INPUTCLK, NOT, AND, NAND, OR, NOR, XOR, OUTPUT, OUTPUT1, OUTPUT4, OUTPUT8, INBUS, BUS1, OUTBUS, DECODER, SEG7 }

func get_part(idx: int, group: int, subidx = 0):
	var node: Part
	if subidx > 0:
		node = get_child(group).get_child(idx).get_child(subidx).duplicate()
	else:
		node = get_child(group).get_child(idx).duplicate()
	node.group = group
	node.index = idx
	node.subidx = subidx
	node.setup()
	return node

func get_enums():
	var e = "enum { "
	var n = 0
	for a in get_children():
		if a is GraphNode:
			a.type = n
			e += a.name + ", "
			n += 1
		for b in a.get_children():
			if b is GraphNode:
				b.type = n
				e += b.name + ", "
				n += 1
			for c in b.get_children():
				if c is GraphNode:
					c.type = n
					e += c.name + ", "
					n += 1
	print(e.to_upper())
