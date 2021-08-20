extends Part

"""
nodes stores PartNode instances
node is PartData instance
"""

var num_slots = 0
var inputs_to_add = []
var outputs_to_add = []
var circuit: Circuit
var nodes = {}

func set_value(v: int, reverse = false, port = 0):
	var node
	if reverse:
		node = outputs_to_add[port][1]
	else:
		node = inputs_to_add[port][1]
	update_internal_bus(node, v, reverse, port)


func update_internal_bus(node, value, reverse, port):
	for con in circuit.connections:
		if reverse:
			if con.to == node.name:
				if nodes[con.from].node.type == "INPUTBUS":
					emit_signal("bus_changed", self, value, reverse)
				else:
					set_internal_value(nodes[con.from].node, value, reverse, con.to_port)
		else:
			if con.from == node.name:
				if nodes[con.to].node.type == "OUTPUTBUS":
					emit_signal("bus_changed", self, value, reverse)
				else:
					set_internal_value(nodes[con.to].node, value, reverse, con.to_port)


func set_internal_value(node, v, reverse, port):
	if node.type == "LOOPBUS":
		if node.value != v:
			node.value = v
			reverse = not reverse
		else:
			return
	else:
		var ob = nodes[node.name]
		var obn = ob.node
		match node.type:
			"BUSMUX":
				if port < 4:
					obn.values[port] = v
				if port != obn.selected_port:
					return
				obn.value = v
			"DECODER":
				pass
			"ALU":
				if port == 0:
					obn.a = v
				if port == 1:
					obn.b = v
				v = obn.a
				b = obn.b
				# Decide function
				var f = int(obn.inputs[4])
				f = 2 * f + int(obn.inputs[3])
				f = 2 * f + int(obn.inputs[2])
				a %= maxvs[obn.data.bits]
				b %= maxvs[obn.data.bits]
				var msb1 = v >= msbs[obn.data.bits]
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
							v -= b # maxvs[data.bits] - b # Invert b and add 1
					6:
						v &= b
					7:
						v |= b
				# Cout
				update_internal_output(ob, v >= maxvs[obn.data.bits], 1, reverse)
				v %= maxvs[obn.data.bits]
				var msb2 = v >= msbs[obn.data.bits]
				update_internal_output(ob, v == 0, 2, reverse) # Zero
				var of = false
				match f:
					2,3,4:
						of = msb2 > msb1
					5:
						of = msb2 < msb1
				update_internal_output(ob, of, 3, reverse) # OF
				update_internal_output(ob, msb2, 4, reverse) # Sign
	update_internal_bus(node, v, reverse, port)


func reset():
	.reset()
	for node in nodes:
		var inputs: Dictionary = nodes[node].inputs
		for idx in inputs:
			inputs[idx].count = 0
	# Don't bother with reversible inputs


func update_output(level: bool, port: int, reverse: bool):
	var node = inputs_to_add[port][1]
	update_internal_output(node, level, port, reverse)


func update_internal_output(node, level: bool, port: int, reverse: bool):
	for con in circuit.connections:
		if reverse:
			if con.to == node.name and con.to_port == port:
				apply_internal_input(nodes[con.from], level, con.from_port, reverse)
		else:
			if con.from == node.name and con.from_port == port:
				apply_internal_input(nodes[con.to], level, con.to_port, reverse)


func apply_internal_input(node, level, port, reverse):
	var pin
	if reverse:
		pin = node.outputs[port]
	else:
		pin = node.inputs[port]
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
	pin.untouched = false # Not sure if this is needed
	port = 0
	match node.node.type:
		"OUTPUTPIN":
			set_output(level, get_output_pin_port(node.node), reverse)
			return
		"NOT":
			level = not level
		"NAND":
			level = not(node.inputs[0].level and node.inputs[1].level)
		"AND":
			level = node.inputs[0].level and node.inputs[1].level
		"XOR":
			level = (not node.inputs[0].level and node.inputs[1].level) or (node.inputs[0].level and not node.inputs[1].level)
		"OR":
			level = node.inputs[0].level or node.inputs[1].level
	update_internal_output(node.node, level, port, reverse)


func get_output_pin_port(node):
	var port = 0
	while outputs_to_add[port][1] != node and port < 99:
		port += 1
	return port


func update_bus(node, value, reverse = false):
	emit_signal("bus_changed", node, value, reverse)


func set_the_title(txt: String):
	title = txt.get_file().get_basename().to_upper()


func add_pins(circ: Circuit, file_name):
	circuit = circ
	set_the_title(file_name)
	for node in circ.nodes:
		match node.type:
			"INPUTPIN":
				inputs_to_add.append([0, node])
				add_slot()
			"INPUTBUS":
				inputs_to_add.append([1, node])
				add_slot()
			"OUTPUTPIN":
				outputs_to_add.append([0, node])
				add_slot()
			"OUTPUTBUS":
				outputs_to_add.append([1, node])
				add_slot()
	configure_slots()
	add_nodes()


class PartNode:
	var node
	var inputs = []
	var outputs = []
	func _init(_node):
		node = _node
		for _n in 5:
			inputs.append(Part.Pin.new())
			outputs.append(Part.Pin.new())


func add_nodes():
	for node in circuit.nodes:
		nodes[node.name] = PartNode.new(node)


func add_slot():
	if num_slots < inputs_to_add.size() or num_slots < outputs_to_add.size():
		if num_slots > 0:
			add_child($HBox.duplicate()) # Create a new slot
		num_slots += 1


func configure_slots():
	var idx = 0
	var type_left = 0
	var type_right = 0
	var enable_left = false
	var enable_right = false
	var col_left
	var col_right
	while idx < num_slots:
		if idx < inputs_to_add.size():
			enable_left = true
			type_left = inputs_to_add[idx][0]
			if type_left == 0:
				col_left = Color.white
			else:
				col_left = Color.yellow
			get_child(idx).get_child(0).text = inputs_to_add[idx][1].data.tag
		else:
			enable_left = false
		if idx < outputs_to_add.size():
			enable_right = true
			type_right = outputs_to_add[idx][0]
			if type_right == 0:
				col_right = Color.white
			else:
				col_right = Color.yellow
			get_child(idx).get_child(2).text = outputs_to_add[idx][1].data.tag
		else:
			enable_right = false
		set_slot(idx, enable_left, type_left, col_left, enable_right, type_right, col_right)
		idx += 1
