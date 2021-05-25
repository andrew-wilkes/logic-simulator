extends GraphNode

class_name Part

signal output_changed(node, slot, level)
signal unstable(node, slot)

const RACE_TRIGGER_COUNT = 4

var type = ""
var group = ""
var input_levels = {}
var inputs_effected = {}

func _ready():
	var child = get_child(0)
	if child is CheckButton:
		set_output(child.pressed, 0)
		child.connect("toggled", self, "set_output", [0])


func reset():
	inputs_effected = {}


func set_input(level: bool, port: int):
	var col = Color.red if level else Color.blue
	set("slot/%d/left_color" % [0,2][port], col)
	update_output(level, port)


func set_output(level: bool, slot: int):
	var col = Color.red if level else Color.blue
	set("slot/%d/right_color" % slot, col)
	# Output the port number
	emit_signal("output_changed", self, 0, level)


func update_output(level: bool, port: int):
	if type == "OUTPUT":
		$Label.text = String(int(level))
		return
	# Cause update for first-time input
	if not input_levels.has(port):
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
	if type == "NOT":
		level = !level
		set_output(level, 0)
	else:
		if not input_levels.has(0):
			input_levels[0] = false
		if not input_levels.has(1):
			input_levels[1] = false
		match type:
			"OR":
				level = input_levels[0] or input_levels[1]
			"NOR":
				level = not (input_levels[0] or input_levels[1])
			"AND":
				level = input_levels[0] and input_levels[1]
			"NAND":
				level = not (input_levels[0] and input_levels[1])
			"XOR":
				level = (not input_levels[0] and input_levels[1]) or (input_levels[0] and not input_levels[1])
		set_output(level, 1)
