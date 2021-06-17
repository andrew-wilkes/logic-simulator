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
enum TYPES { INPUT = 1, INPUTPIN, INPUTSW, INPUTPUSH, INPUT4, INPUT8, INPUTCLK, NOT, AND, NAND, OR, NOR, XOR, OUTPUT, OUTPUTPIN, OUTPUT1, OUTPUT4, OUTPUT8, INBUS, BUS1, OUTBUS,  MULT, SRLIPFLOP, DLATCH, DFLIPFLOP, JKFLIPFLOP, ADDER, DECODER, SEG7, REG, COUNTER, LOOPBACK }

func get_part(part_name: String):
	var part = find_node(part_name).duplicate()
	part.type = TYPES[part.name]
	part.setup()
	return part

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
