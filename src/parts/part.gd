extends GraphNode

class_name Part

signal output_changed(node, slot, level, reverse)
signal bus_changed(node, value, reverse)
signal unstable(node, slot)
signal part_variant_selected(part, pos)
signal part_clicked(part)
signal data_changed

const RACE_TRIGGER_COUNT = 4

export var has_tt = false
export var locked = false
export var bits = 0
export var is_reversible_input = false

var input_pins = []
var output_pins = []
var selected_port = 0
var output_enabled = false
var bit_lengths = [4, 8, 16]
var msbs = [8, 128, 32768]
var maxvs = [16, 256, 65536]
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


func check_if_clicked(event):
	if event is InputEventMouseButton and has_tt:
		emit_signal("part_clicked", self)


func _on_Pin_text_changed(_new_text):
	emit_signal("offset_changed")


func setup():
	breakpoint

class Pin:
	var slot = 0
	var level = false
	var last_level = false
	var count = 0
	
	func copy_level():
		last_level = level

func set_pins():
	var slot = 0
	for node in get_children():
		if node is Control:
			if is_slot_enabled_left(slot):
				var input_pin = Pin.new()
				input_pin.slot = slot
				input_pins.append(input_pin)
			if is_slot_enabled_right(slot):
				var output_pin = Pin.new()
				output_pin.slot = slot
				output_pins.append(output_pin)
			slot += 1


func reset():
	for input_pin in input_pins:
		input_pin.count = 0


func get_value_from_inputs(reverse):
	var v = 0
	var pins = input_pins
	if reverse:
		pins = output_pins
	var num_bits = pins.size()
	var port = num_bits
	for n in num_bits:
		port -= 1
		v *= 2
		v += int(pins[port].level)
	return v


func set_input(level: bool, port: int, reverse = false):
	var col = Color.red if level else Color.blue
	if reverse:
		set("slot/%d/right_color" % output_pins[port], col)
	else:
		set("slot/%d/left_color" % input_pins[port], col)
	update_output(level, port, reverse)


func set_output(level: bool, port: int, reverse := false):
	output_pins[port] = level
	var col = Color.red if level else Color.blue
	if reverse:
		set("slot/%d/left_color" % input_pins[port], col)
	else:
		set("slot/%d/right_color" % output_pins[port], col)
	emit_signal("output_changed", self, port, level, reverse)


# Gets passed the port that has an input level passed to it
func apply_input(level: bool, port: int, reverse: bool):
	var pin = input_pins[port]
	if reverse:
		pin = output_pins[port]
	# Cause update for first-time input or
	# return if no change to established input
	if pin.level == level and pin.count > 0:
		return false
	# Detect race condition
	pin.count += 1
	if pin.count == RACE_TRIGGER_COUNT:
			emit_signal("unstable", self, port)
			return false
	pin.copy_level()
	pin.level = level
	update_output(level, port, reverse)


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
