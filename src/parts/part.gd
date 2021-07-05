extends GraphNode

class_name Part

signal output_changed(node, port, level, reverse)
signal bus_changed(node, value, reverse)
signal unstable(node, port, reverse)
signal part_variant_selected(part, pos)
signal part_clicked(part)
signal data_changed

const RACE_TRIGGER_COUNT = 4

var has_tt = false
var locked = false
var num_bytes = 2
var is_reversible_input = false
var is_input = false

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
var format = "0x%02X"
var untouched = true

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
	var untouched = true


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
	if is_reversible_input:
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


# Gets passed the port that has an input level passed to it
func apply_input(level: bool, port: int, reverse: bool):
	var pin = input_pins[port]
	if reverse:
		pin = output_pins[port]
	if pin.untouched: # Reset this after update_output
		pin.level = not level # Ensure that change is recognized
	# return if no change to established input
	if pin.level == level:
		return false
	# Detect race condition
	pin.count += 1
	if pin.count > RACE_TRIGGER_COUNT:
		emit_signal("unstable", self, port, reverse)
		return false
	pin.last_level = pin.level
	pin.level = level
	set_input(level, port, reverse)
	update_output(level, port, reverse)
	pin.untouched = false


func set_input(level: bool, port: int, reverse = false):
	var col = Color.red if level else Color.blue
	if reverse:
		set("slot/%d/right_color" % output_pins[port].slot, col)
	else:
		set("slot/%d/left_color" % input_pins[port].slot, col)


func set_output(level: bool, port: int, reverse := false):
	var col = Color.red if level else Color.blue
	var pin = output_pins[port]
	if reverse:
		pin = input_pins[port]
		set("slot/%d/left_color" % pin.slot, col)
	else:
		set("slot/%d/right_color" % pin.slot, col)
	pin.level = level
	pin.count += 1
	emit_signal("output_changed", self, port, level, reverse)


func set_data(d):
	data = d


func get_data():
	return data


# Run code when part is added to graph
func dropped():
	emit_signal("data_changed") # To avoid warning


func loaded_from_file():
	pass


# Parts that don't process the inputs
func update_output(level, port, _reverse):
	if input_pins[port].untouched: # Last level was unknown
		input_pins[port].last_level = level


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
		#set_format()
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
			$Label.text = int2bin(value)


# Create groups of 4 bits
func int2bin(x: int, num_bits = 8) -> String:
	var _b = ""
	for n in 16:
		if n > 0 and n % 4 == 0:
			if x == 0 and n == num_bits:
				break
			_b = " " + _b
		_b = String(x % 2) + _b
		x /= 2
	return "0b" + _b


func apply_data():
	pass


func set_value(_v, _r, _p):
	pass
