extends GraphNode

class_name Part

signal output_changed(node, slot, level, reverse)
signal unstable(node, slot)
signal short_circuit(node, port, reverse)
signal bus_changed(node, value, reverse)
signal part_variant_selected(part, pos)

export var id = ""
export var has_tt = false

const RACE_TRIGGER_COUNT = 4

enum PIN_MODE { HIGH, OUTPUT, INPUT, BI }

export var type := 0 setget set_type

var group := 0
var index := 0
var subidx := 0
var locked = false
var input_levels = {}
var inputs_effected = {}
var in_port_map = []
var in_port_mode = []
var out_port_map = []
var out_port_mode = []
var depth = 0
var bits = 0
var bit_lengths = [4, 8, 16]
var output_levels = {}
var value := -1
var data = {}

var frame_style = preload("res://assets/GraphNodeFrameStyle.tres")

func _ready():
	set("custom_styles/frame", frame_style)
	# The following code stops the graph nodes from inheriting from Part when tool mode in Parts is active
	if type == Parts.INPUT or type == Parts.OUTPUT:
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


func _on_Pin_text_changed(_new_text):
	emit_signal("offset_changed")


func set_title(_v):
	title = title.strip_edges()


func set_type(_t):
	type = _t


func setup():
	set_port_maps()
	var child = get_child(0)
	if child is Button:
		child.focus_mode = Control.FOCUS_NONE
		set_output(child.pressed, 0)
		set_output(child.pressed, 0, true)
		if child.toggle_mode:
			child.connect("toggled", self, "set_io", [0, 0])
		else:
			child.connect("button_down", self, "set_io", [true, 0, 0])
			child.connect("button_up", self, "set_io", [false, 0, 0])


func set_port_maps():
	var idx = 0
	for node in get_children():
		if node is Control:
			if is_slot_enabled_left(idx):
				in_port_map.append(idx)
				match type:
					Parts.INBUS, Parts.BUS1:
						in_port_mode.append(PIN_MODE.BI)
					_:
						in_port_mode.append(PIN_MODE.INPUT)
			if is_slot_enabled_right(idx):
				out_port_map.append(idx)
				match type:
					Parts.INBUS, Parts.BUS1:
						out_port_mode.append(PIN_MODE.BI)
					Parts.OUTPUT1:
						out_port_mode.append(PIN_MODE.INPUT)
					_:
						out_port_mode.append(PIN_MODE.OUTPUT)
			idx += 1


func reset():
	inputs_effected = {}


func get_value_from_inputs(reverse):
	var v = 0
	var port = in_port_map.size()
	if reverse:
		port = out_port_map.size()
	
	for n in bit_lengths[bits]:
		port -= 1
		v *= 2
		if input_levels.keys().has(port):
			v += int(input_levels[port])
	return v


# Input pin and output pin used as outputs
func set_io(level, in_port, out_port):
	set_output(level, out_port)
	set_output(level, in_port, true)


func set_input(level: bool, port: int, reverse = false):
	var col = Color.red if level else Color.blue
	if reverse:
		if out_port_mode[port] == PIN_MODE.HIGH:
			return
		if out_port_mode[port] != PIN_MODE.OUTPUT:
			set("slot/%d/right_color" % out_port_map[port], col)
		else:
			emit_signal("short_circuit", [self, port, reverse])
			return
	else:
		if in_port_mode[port] == PIN_MODE.HIGH:
			return
		if in_port_mode[port] != PIN_MODE.OUTPUT:
			set("slot/%d/left_color" % in_port_map[port], col)
		else:
			emit_signal("short_circuit", [self, port, reverse])
			return
		update_output(level, port, reverse)


func set_output(level: bool, port: int, reverse := false):
	var col = Color.red if level else Color.blue
	if reverse:
		set("slot/%d/left_color" % in_port_map[port], col)
	else:
		set("slot/%d/right_color" % out_port_map[port], col)
	emit_signal("output_changed", self, port, level, reverse)


# Gets passed the port that has an input level
func update_output(level: bool, port: int, reverse: bool):
	if type == Parts.OUTPUT1:
		$Label.text = String(int(level))
	# Cause update for first-time input
	if not input_levels.keys().has(port):
		input_levels[port] = not level
	# Return if no change to established input
	if input_levels[port] == level:
		return
	# Detect race condition
	if inputs_effected.has(port):
		inputs_effected[port] += 1
		if inputs_effected[port] == RACE_TRIGGER_COUNT:
			emit_signal("unstable", self, port)
			return
	else:
		inputs_effected[port] = 1
	# Remember the current input level
	input_levels[port] = level
	match type:
		Parts.NOT:
			level = !level
			set_output(level, 0)
		Parts.OUTPUT1:
			set_output(level, port, reverse)
		Parts.OR, Parts.NOR, Parts.AND, Parts.NAND, Parts.XOR:
			if not input_levels.has(0):
				input_levels[0] = false
			if not input_levels.has(1):
				input_levels[1] = false
			match type:
				Parts.OR:
					level = input_levels[0] or input_levels[1]
				Parts.NOR:
					level = not (input_levels[0] or input_levels[1])
				Parts.AND:
					level = input_levels[0] and input_levels[1]
				Parts.NAND:
					level = not (input_levels[0] and input_levels[1])
				Parts.XOR:
					level = (not input_levels[0] and input_levels[1]) or (input_levels[0] and not input_levels[1])
			set_output(level, 0)
		_:
			set_value(level, reverse, true)


# This function is overwritten in busses
func set_value(_v: int, _reverse: bool, _from_pin: bool):
	emit_signal("bus_changed", self, _v, _reverse)


func get_pin_name():
	return get_node("Pin").text


func set_pin_name(txt):
	if txt is String:
		get_node("Pin").text = txt
