tool
# Manually add enums to match the part name
# Reload this file and ensure that the enum indexes match with the part type property value
extends Control

func _ready():
	tool_stuff()
	pass


func tool_stuff():
	# Stop autoloaded scene showing up in Tool script mode
	if Engine.is_editor_hint():
		print("Running parts tool script")
		hide()
		print(get_parent().name)
		get_enums()


# part type equates to the enum value
enum { INPUT = 1, INPUTPIN, INPUTSW, INPUTPUSH, INPUT4, INPUT8, INPUTCLK, NOT, AND, NAND, OR, NOR, XOR, OUTPUT, OUTPUTPIN, OUTPUT1, OUTPUT4, OUTPUT8, INBUS, BUS1, OUTBUS,  MULT, SRLIPFLOP, DLATCH, DFLIPFLOP, JKFLIPFLOP, ADDER, DECODER, SEG7, REG, COUNTER }

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
	var n = 1
	for a in get_children():
		if a is Part:
			a.type = n
			e += a.name + ", "
			n += 1
		for b in a.get_children():
			if b is Part:
				print(b.name)
				b.type = n
				e += b.name + ", "
				n += 1
			for c in b.get_children():
				if c is Part:
					c.type = n
					e += c.name + ", "
					n += 1
	print(e.to_upper())
	print(n)
