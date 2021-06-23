tool
extends GraphNode

class_name Part

signal output_changed(node, slot, level, reverse)
signal unstable(node, slot)
signal short_circuit(node, port, reverse)
signal bus_changed(node, value, reverse)
signal part_variant_selected(part, pos)
signal part_clicked(part)
signal data_changed

export var has_tt = false
export var locked = false
export var bits = 0
export var is_reversible_input = false

const RACE_TRIGGER_COUNT = 4

enum PIN_MODE { HIGH, OUTPUT, INPUT, BI }

var group := 0
var index := 0
var subidx := 0
var input_levels = {}
var last_input_levels = {}
var inputs_effected = {}
var selected_port = 0
var in_port_map = []
var in_port_mode = []
var out_port_map = []
var out_port_mode = []
var output_enabled = false
var bit_lengths = [4, 8, 16]
var msbs = [8, 128, 32768]
var maxvs = [16, 256, 65536]
var output_levels = {}
var value := -1
var a := 0
var b := 0
var vin = 0
var data = {} setget set_data, get_data
var type := 0

var frame_style = preload("res://assets/GraphNodeFrameStyle.tres")

func _ready():
	set("custom_styles/frame", frame_style)
	# The following code stops the graph nodes from inheriting from Part when Engine.is_editor_hint() in Parts is run, sometimes. So their type number is zero
	if Engine.is_editor_hint():
		print("Running tool script for: ", name)
	else:
		connect_inner_io_nodes()
		var _e = connect("gui_input", self, "check_if_clicked")


func check_if_clicked(event):
	if event is InputEventMouseButton and has_tt:
		emit_signal("part_clicked", self)


func connect_inner_io_nodes():
	if type == Parts.TYPES.INPUT or type == Parts.TYPES.OUTPUT:
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
		node.type = Parts.TYPES[node.name]
		if node.get_child(0).name == "V":
			node.set_value(0)
		remove_child(node)
		emit_signal("part_variant_selected", node, offset)
		queue_free()


func _on_Pin_text_changed(_new_text):
	emit_signal("offset_changed")


func set_title(_v):
	title = title.strip_edges()


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
					Parts.TYPES.INBUS, Parts.TYPES.BUS1:
						in_port_mode.append(PIN_MODE.BI)
					_:
						in_port_mode.append(PIN_MODE.INPUT)
			if is_slot_enabled_right(idx):
				out_port_map.append(idx)
				match type:
					Parts.TYPES.INBUS, Parts.TYPES.BUS1:
						out_port_mode.append(PIN_MODE.BI)
					Parts.TYPES.OUTPUT1:
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
	output_levels[port] = level
	var col = Color.red if level else Color.blue
	if reverse:
		set("slot/%d/left_color" % in_port_map[port], col)
	else:
		set("slot/%d/right_color" % out_port_map[port], col)
	emit_signal("output_changed", self, port, level, reverse)


# Gets passed the port that has an input level
func update_output(level: bool, port: int, reverse: bool):
	if type == Parts.TYPES.OUTPUT1:
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
	last_input_levels[port] = input_levels.get(port, false)
	input_levels[port] = level
	match type:
		Parts.TYPES.NOT:
			level = !level
			set_output(level, 0)
		Parts.TYPES.OUTPUT1:
			set_output(level, port, reverse)
		Parts.TYPES.OR, Parts.TYPES.NOR, Parts.TYPES.AND, Parts.TYPES.NAND, Parts.TYPES.XOR:
			set_default_input_levels()
			match type:
				Parts.TYPES.OR:
					level = input_levels[0] or input_levels[1]
				Parts.TYPES.NOR:
					level = not (input_levels[0] or input_levels[1])
				Parts.TYPES.AND:
					level = input_levels[0] and input_levels[1]
				Parts.TYPES.NAND:
					level = not (input_levels[0] and input_levels[1])
				Parts.TYPES.XOR:
					level = (not input_levels[0] and input_levels[1]) or (input_levels[0] and not input_levels[1])
			set_output(level, 0)
		Parts.TYPES.MULT:
			set_default_input_levels()
			if input_levels[0]: # Select
				set_output(input_levels[2], 0) # A
			else:
				set_output(input_levels[1], 0) # B
		Parts.TYPES.SRFLIPFLOP:
			set_default_input_levels()
			# Init outputs
			if output_levels.size() == 0:
				output_levels = { 0: false, 1: true }
				set_output(false, 0)
				set_output(true, 1)
			if input_levels[0]: # Set
				set_output(not input_levels[1], 0)
				set_output(false, 1)
			else:
				if input_levels[1]: # Reset
					set_output(false, 0)
					set_output(not input_levels[0], 1)
		Parts.TYPES.DLATCH:
			set_default_input_levels()
			# Init outputs
			if output_levels.size() == 0:
				output_levels = { 0: false, 1: true }
				set_output(false, 0)
				set_output(true, 1)
			if input_levels[0]: # Enable
				set_output(input_levels[1], 0)
				set_output(not input_levels[1], 1)
		Parts.TYPES.DFLIPFLOP:
			set_default_input_levels()
			# Init outputs
			if output_levels.size() == 0:
				output_levels = { 0: false }
				set_output(false, 0)
			if input_levels[0]: # Set
				set_output(true, 0)
			else:
				if input_levels[3]: # Reset
					set_output(false, 0)
				else:
					# Detect rising edge of CK
					if input_levels[2] and not last_input_levels[2]:
						set_output(input_levels[1], 0)
					last_input_levels[2] = input_levels[2]
		Parts.TYPES.ADDER:
			set_default_input_levels()
			# Init outputs
			if output_levels.size() == 0:
				output_levels = { 0: false, 1: false }
				set_output(false, 0)
				set_output(false, 1)
			var sum: int = int(input_levels[0]) + int(input_levels[1]) + int(input_levels[2])
			set_output(bool(sum % 2), 0) # Sum
# warning-ignore:integer_division
			set_output(bool(sum / 2), 1) # Cout
		Parts.TYPES.JKFLIPFLOP:
			set_default_input_levels()
			# Init outputs
			if output_levels.size() == 0:
				output_levels = { 0: false, 1: true }
				set_output(false, 0)
				set_output(true, 1)
			# Detect not rising edge of CK
			if not input_levels[1] or last_input_levels[1]:
				return
			last_input_levels[1] = input_levels[1]
			if input_levels[0] and input_levels[2]: # Toggle
				set_output(not output_levels[0], 0)
				set_output(not output_levels[1], 1)
			else:
				if input_levels[0]: # Set
					set_output(true, 0)
					set_output(false, 1)
				if input_levels[2]: # Reset
					set_output(true, 1)
					set_output(false, 0)
		Parts.TYPES.REG:
			set_default_input_levels()
			if input_levels[3]: # Reset
				output_enabled = true
				set_value(0, false, false)
			# Detect not rising edge of CK
			if not input_levels[2] or last_input_levels[2]:
				return
			last_input_levels[2] = input_levels[2]
			if input_levels[1]: # LD
				value = -1 # Make sure it propagates
				output_enabled = true
				set_value(vin, false, false)
		Parts.TYPES.COUNTER:
			set_default_input_levels()
			if input_levels[4]: # Reset
				output_enabled = true
				value = -1 # Make sure it propagates
				set_value(0, false, false)
			# Detect not rising edge of CK
			if not input_levels[3] or last_input_levels[3]:
				return
			last_input_levels[3] = input_levels[3]
			output_enabled = true
			if input_levels[2]: # LD
				value = -1 # Make sure it propagates
				set_value(vin, false, false)
			else:
				set_value(wrapi(value + int(input_levels[1]), 0, 0xffff), false, false)
		Parts.TYPES.SHIFTREG:
			set_default_input_levels()
			if input_levels[5]: # Reset
				output_enabled = true
				value = -1 # Make sure it propagates
				set_value(0, false, false)
			# Detect not rising edge of CK
			if not input_levels[4] or last_input_levels[4]:
				return
			last_input_levels[4] = input_levels[4]
			output_enabled = true
			if input_levels[3]: # LD
				value = -1 # Make sure it propagates
				set_value(vin, false, false)
			else:
				var v = value
				if input_levels[2]: # EN
					v /= 2 # Shift right
					if input_levels[1]: # SI
						v += msbs[data.bits]
				set_value(v, false, false)
		Parts.TYPES.ALU:
			set_default_input_levels()
			if port < 0: # a or b changed. Ensure that dummy pin is not ignored.
				var _r = input_levels.erase(port)
			# Decide function
			var f = int(input_levels[4])
			f = 2 * f + int(input_levels[3])
			f = 2 * f + int(input_levels[2])
			a %= maxvs[bits]
			b %= maxvs[bits]
			var v = a
			var msb1 = v >= msbs[bits]
			match f:
				1:
					v = b
				2:
					v += 1
				3:
					v = b + 1
				4:
					v += b
				5:
					if b > 0:
						v = v + maxvs[bits] - b # Invert b and add 1
				6:
					v &= b
				7:
					v |= b
			var msb2 = v >= msbs[bits]
			set_output(v >= maxvs[bits], 1) # Cout
			set_output(v == 0, 2) # Zero
			set_output(msb1 != msb2, 3) # OF
			set_output(msb2, 4) # Sign
			set_value(v % maxvs[bits], false, false, -1)
		Parts.TYPES.BUSMUX:
			set_default_input_levels()
			selected_port = int(input_levels[4]) + 2 * int(input_levels[5])
		_:
			set_value(level, reverse, true)


func set_default_input_levels():
	for idx in get_connection_input_count():
		if not input_levels.has(idx):
			input_levels[idx] = false


# This function is overwritten in busses
func set_value(_v: int, _reverse: bool, _from_pin: bool, _port := 0):
	emit_signal("bus_changed", self, _v, _reverse)


func set_data(d):
	match type:
		Parts.TYPES.INPUTPIN, Parts.TYPES.OUTPUTPIN:
			set_pin_name(d)


func get_data():
	var v = null
	match type:
		Parts.TYPES.INPUTPIN, Parts.TYPES.OUTPUTPIN:
			v = get_pin_name()
	return v


func get_pin_name():
	return get_node("Pin").text


func set_pin_name(txt):
	if txt is String:
		get_node("Pin").text = txt


# Run code when part is added to graph
func dropped():
	emit_signal("data_changed") # To avoid warning
