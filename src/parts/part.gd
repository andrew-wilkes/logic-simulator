extends GraphNode

class_name Part

signal output_changed(node, port, level, reverse)
signal bus_changed(node, value, reverse)
signal unstable(node, port, reverse)
signal part_variant_selected(part, pos)
signal part_clicked(part)
signal data_changed
signal part_entered(part)
signal part_exited(part)

const RACE_TRIGGER_COUNT = 4

var has_tt = false
var locked = false
export var num_bytes = 2
var is_reversible_input = false
var is_input = false
var mouse_sensor_scene = preload("res://parts/MouseSensor.tscn")

var input_pins = []
var output_pins = []
var selected_port = 0
var output_enabled = false
var bit_lengths = [4, 8, 16]
var msbs = [8, 128, 32768]
var maxvs = [16, 256, 65536]
var value := 0
var last_value := 0
var a := 0
var b := 0
var vin = 0
export var data = {} setget set_data, get_data
var type := ""
var read = true
var format = "0x%02X"
var untouched = true
var frame_style = preload("res://assets/GraphNodeFrameStyle.tres")

func _ready():
	set("custom_styles/frame", frame_style)


func mouse_action(event: InputEvent):
	if event is InputEventMouseButton and has_tt:
		emit_signal("part_clicked", self)


func _on_Pin_text_changed(_new_text):
	emit_signal("offset_changed")


func setup():
	set_pins()


class Pin:
	var slot = 0
	var type = 0
	var level = false
	var last_level = false
	var count = 0
	var untouched = true


func set_pins():
	var slot = 0
	var left_port = 0
	var right_port = 0
	for node in get_children():
		if node is Control:
			if is_slot_enabled_left(slot):
				var input_pin = Pin.new()
				input_pin.slot = slot
				input_pin.type = get_connection_input_type(left_port)
				input_pins.append(input_pin)
				left_port += 1
			if is_slot_enabled_right(slot):
				var output_pin = Pin.new()
				output_pin.slot = slot
				output_pin.type = get_connection_output_type(right_port)
				output_pins.append(output_pin)
				right_port += 1
			slot += 1


func part_entered():
	#for idx in input_pins.size():
	#	var _pin = set_pin_color(idx, true, Color.orange)
	#for idx in output_pins.size():
	#	var _pin = set_pin_color(idx, false, Color.orange)
	emit_signal("part_entered", self)


func part_exited():
	#for idx in input_pins.size():
	#	reset_pin_color(idx, true)
	#for idx in output_pins.size():
	#	reset_pin_color(idx, false)
	emit_signal("part_exited", self)


func reset_pin_color(port, is_input_pin):
	var level
	if is_input_pin:
		level = input_pins[port].level
	else:
		level = output_pins[port].level
	var col = Color.red if level else Color.blue
	var _pin = set_pin_color(port, is_input_pin, col)


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


func preset_input(level: bool, port: int):
	input_pins[port].level = level
	set_input(level, port)


func set_input(level: bool, port: int, reverse = false):
	var col = Color.red if level else Color.blue
	var _pin = set_pin_color(port, not reverse, col)


func set_output(level: bool, port: int, reverse := false):
	var col = Color.red if level else Color.blue
	var pin = set_pin_color(port, reverse, col)
	pin.level = level
	pin.count += 1
	emit_signal("output_changed", self, port, level, reverse)


func set_pin_color(port: int, left_pin: bool, col: Color):
	var pin
	if left_pin:
		pin = input_pins[port]
		set("slot/%d/left_color" % pin.slot, col)
	else:
		pin = output_pins[port]
		set("slot/%d/right_color" % pin.slot, col)
	return pin


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

enum { HEX, DEC, BIN, BITS, MODE }

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


func change_bit_depth(_b, inc = 1):
	data.bits = wrapi(data.bits + inc, 0, 3)
	_b.text = String(bit_lengths[data.bits])
	value = 0
	set_format()
	update_display_value()


func set_format():
	format = "0x%0" + String(bit_lengths[data.bits] / 4) + "X"


func update_display_value():
	match data.mode:
		DEC:
			$Label.text = String(value)
		BIN:
			$Label.text = int2bin(value, bit_lengths[data.bits])
		_:
			$Label.text = format % value


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


func supress_error():
	emit_signal("bus_changed")
	emit_signal("part_variant_selected", 1, 2)
