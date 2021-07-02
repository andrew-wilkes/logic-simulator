extends GraphNode

class_name Part

signal output_changed(node, port, level, reverse)
signal bus_changed(node, value, reverse)
signal unstable(node, port, reverse)
signal part_variant_selected(part, pos)
signal part_clicked(part)
signal data_changed

const RACE_TRIGGER_COUNT = 4

export var has_tt = false
export var locked = false
export var num_bytes = 2
export var is_reversible_input = false
export var is_input = false

var input_pins = []
var output_pins = []
var selected_port = 0
var output_enabled = false
var bit_lengths = [4, 8, 16]
var msbs = [8, 128, 32768]
var maxvs = [16, 256, 65536]
var value := 0
var a := 0
var b := 0
var vin = 0
var data = {} setget set_data, get_data
var type := ""
var read = true
var format = ""

var frame_style = preload("res://assets/GraphNodeFrameStyle.tres")

func _ready():
	set("custom_styles/frame", frame_style)


func check_if_clicked(event):
	if event is InputEventMouseButton and has_tt:
		emit_signal("part_clicked", self)


func _on_Pin_text_changed(_new_text):
	emit_signal("offset_changed")


func setup():
	set_pins()


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
	for output_pin in output_pins:
		output_pin.count = 0


func get_value_from_inputs(reverse):
	var v = 0
	var pins = input_pins
	if reverse:
		pins = output_pins
	var num_bits = pins.size() - 1
	# Port 0 is the bus
	var port = num_bits
	for n in num_bits:
		v *= 2
		v += int(pins[port].level)
		port -= 1
	return v


func set_input(level: bool, port: int, reverse = false):
	var col = Color.red if level else Color.blue
	if reverse:
		set("slot/%d/right_color" % output_pins[port].slot, col)
	else:
		set("slot/%d/left_color" % input_pins[port].slot, col)
	update_output(level, port, reverse)


func set_output(level: bool, port: int, reverse := false):
	var col = Color.red if level else Color.blue
	var pin = output_pins[port]
	if reverse:
		pin = input_pins[port]
		set("slot/%d/left_color" % input_pins[port].slot, col)
	else:
		set("slot/%d/right_color" % output_pins[port].slot, col)
	pin.level = level
	pin.count += 1
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
	if pin.count > RACE_TRIGGER_COUNT:
		emit_signal("unstable", self, port, reverse)
		return false
	pin.copy_level()
	pin.level = level
	set_input(level, port, reverse)
	update_output(level, port, reverse)


func set_data(d):
	data = d


func get_data():
	return data


# Run code when part is added to graph
func dropped():
	emit_signal("data_changed") # To avoid warning


func loaded_from_file():
	pass


func update_output(_level, _port, _reverse):
	pass


func change_button(_b):
	_b.text = "Mode"
	data.mode = MODE


func handle_button_press(_b):
	if data.mode == BITS:
		change_bit_depth(_b)
		_b.start_timer()
		rect_size.x = 0
	else:
		data.mode += 1
		data.mode %= 3
		set_format()
		update_display_value()
		emit_signal("data_changed")


func change_bit_depth(_b):
	data.bits = wrapi(data.bits + 1, 0, 3)
	_b.text = String(bit_lengths[data.bits])
	value = 0
	update_display_value()


func set_format():
	if data.mode == HEX:
		format = "0x%0" + String(bit_lengths[data.bits] / 4) + "X"

enum { HEX, DEC, BIN, BITS, MODE }

func update_display_value():
	match data.mode:
		HEX:
			$Label.text = format % value
		DEC:
			$Label.text = String(value)
		BIN:
			$Label.text = Parts.int2bin(value, bit_lengths[data.bits])
