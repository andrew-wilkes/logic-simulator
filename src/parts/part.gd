extends GraphNode

class_name Part

signal output_changed(node, slot, level, reverse)
signal bus_changed(node, value, reverse)
signal unstable(node, slot)
signal short_circuit(node, port, reverse)
signal part_variant_selected(part, pos)
signal part_clicked(part)
signal data_changed

enum PIN_MODE { HIGH, OUTPUT, INPUT, BI }

const RACE_TRIGGER_COUNT = 4

export var has_tt = false
export var locked = false
export var bits = 0
export var is_reversible_input = false

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
var output_levels = { 0: false }
var value := -1
var a := 0
var b := 0
var vin = 0
var data = {} setget set_data, get_data
var type := 0
var read = true

var frame_style = preload("res://assets/GraphNodeFrameStyle.tres")

func _ready():
	set("custom_styles/frame", frame_style)
	set_input_levels()


func check_if_clicked(event):
	if event is InputEventMouseButton and has_tt:
		emit_signal("part_clicked", self)


func _on_Pin_text_changed(_new_text):
	emit_signal("offset_changed")


func setup():
	breakpoint


func set_port_maps():
	var slot = 0
	for node in get_children():
		if node is Control:
			if is_slot_enabled_left(slot):
				in_port_map.append(slot)
				match type:
					Parts.TYPES.INBUS, Parts.TYPES.BUS1:
						in_port_mode.append(PIN_MODE.BI)
					_:
						in_port_mode.append(PIN_MODE.INPUT)
			if is_slot_enabled_right(slot):
				out_port_map.append(slot)
				match type:
					Parts.TYPES.INBUS, Parts.TYPES.BUS1:
						out_port_mode.append(PIN_MODE.BI)
					Parts.TYPES.OUTPUT1:
						out_port_mode.append(PIN_MODE.INPUT)
					_:
						out_port_mode.append(PIN_MODE.OUTPUT)
			slot += 1


func reset():
	inputs_effected = {}


func get_value_from_inputs(reverse):
	var v = 0
	var num_bits = in_port_map.size()
	if reverse:
		num_bits = out_port_map.size()
	var port = num_bits
	for n in num_bits:
		port -= 1
		v *= 2
		if input_levels.keys().has(port):
			v += int(input_levels[port])
	return v


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


# Gets passed the port that has an input level passed to it
func apply_input(level: bool, port: int, reverse: bool):
	# Cause update for first-time input
	if not input_levels.keys().has(port):
		input_levels[port] = not level
	# Return if no change to established input
	if input_levels[port] == level:
		return false
	# Detect race condition
	if inputs_effected.has(port):
		inputs_effected[port] += 1
		if inputs_effected[port] == RACE_TRIGGER_COUNT:
			emit_signal("unstable", self, port)
			return false
	else:
		inputs_effected[port] = 1
	# Remember the current input level
	last_input_levels[port] = input_levels.get(port, false)
	input_levels[port] = level
	update_output(level, port, reverse)


func set_input_levels():
	for idx in get_connection_input_count():
		input_levels[idx] = false


func set_data(d):
	data = d


func get_data():
	return data


# Run code when part is added to graph
func dropped():
	emit_signal("data_changed") # To avoid warning
	emit_signal("part_variant_selected")


func loaded_from_file():
	pass


func update_output(level, port, reverse):
	breakpoint
