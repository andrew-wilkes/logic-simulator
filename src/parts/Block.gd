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

func setup():
	set_pins()
	data = { "source_file": "" }
	type = "Block"


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
					set_internal_value(con.from, value, reverse, con.to_port)
		else:
			if con.from == node.name:
				if nodes[con.to].node.type == "OUTPUTBUS":
					emit_signal("bus_changed", self, value, reverse)
				else:
					set_internal_value(con.to, value, reverse, con.to_port)


func set_internal_value(node_name, v, reverse, port):
	var ob = nodes[node_name]
	var obn = ob.node
	match obn.type:
		"LOOPBUS":
			if ob.value != v:
				ob.value = v
				reverse = not reverse
			else:
				return
		"BUSMUX":
			if port < 4 and ob.values[port] != v:
				ob.values[port] = v
				if port != ob.selected_port:
					return
				ob.value = v
			else:
				return
		"REG", "COUNTER", "SHIFTREG":
			if port == 0:
				ob.vin = v
			return
		"ROM":
			# Set address
			v %= obn.data.memory.mem_size
			obn.value = v
			if ob.inputs[1].level: # /OE
				return
			v = obn.data.memory.words[obn.value]
		"RAM":
			if port == 1: # Data
				if ob.inputs[3].level: # /W
					return
				if obn.data.memory.width == 8:
					v %= 0x100
				obn.data.memory.words[obn.value] = v
			elif port == 0: # Address
				v %= obn.data.memory.mem_size
				ob.value = v
			if ob.inputs[2].level: # /OE
				return
			v = obn.data.memory.words[ob.value]
		"DECODER":
			if port != 0:
				return
			v %= obn.data.size
			for n in obn.data.size:
				update_internal_output(ob, v == n, n, reverse)
			return
		"ALU":
			if port == 0:
				ob.a = v
			if port == 1:
				ob.b = v
			v = ob.a
			b = ob.b
			# Decide function
			var f = int(ob.inputs[4].level)
			f = 2 * f + int(ob.inputs[3].level)
			f = 2 * f + int(ob.inputs[2].level)
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
	update_internal_bus(obn, v, reverse, port)


func reset():
	.reset()
	for node in nodes:
		var n = nodes[node]
		for idx in n.inputs.size():
			n.inputs[idx].count = 0
	# Don't bother with reversible inputs


func update_output(level: bool, port: int, reverse: bool):
	var node = inputs_to_add[port][1]
	update_internal_output(node, level, port, reverse)


func update_internal_output(node, level: bool, port: int, reverse: bool):
	for con in circuit.connections:
		if reverse:
			if con.to == node.name:
				apply_internal_input(nodes[con.from], level, con.from_port, reverse)
		else:
			if con.from == node.name:
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
		"BUSMUX":
			node.selected_port = int(node.inputs[4].level) + 2 * int(node.inputs[5].level)
			update_internal_bus(node.node, node.values[node.selected_port], false, 0)
			return
		"REG":
			if node.inputs[3].level: # Reset
				node.value = 0
				update_internal_bus(node.node, 0, false, 0)
			# Detect not rising edge of CK
			if not node.inputs[2].level or node.inputs[2].last_level:
				return
			node.inputs[2].last_level = node.inputs[2].level
			if node.inputs[1].level: # LD
				node.value = node.vin
				update_internal_bus(node.node, node.vin, false, 0)
			return
		"COUNTER":
			if node.inputs[4].level: # Reset
				node.value = 0
				update_internal_bus(node.node, 0, false, 0)
			# Detect not rising edge of CK
			if not node.inputs[3].level or node.inputs[3].last_level:
				return
			node.inputs[3].last_level = node.inputs[3].level
			if node.inputs[2].level: # LD
				node.value = node.vin
				update_internal_bus(node.node, node.vin, false, 0)
			else:
				node.value = wrapi(node.value + int(node.inputs[1].level), 0, 0xffff) 
				update_internal_bus(node.node, node.value, false, 0)
			return
		"SHIFTREG":
			if node.inputs[5].level: # Reset
				node.value = 0
				update_internal_bus(node.node, 0, false, 0)
			# Detect not rising edge of CK
			if not node.inputs[4].level or node.inputs[4].last_level:
				return
			node.inputs[4].last_level = node.inputs[4].level
			if node.inputs[3].level: # LD
				node.value = node.vin
				update_internal_bus(node.node, node.vin, false, 0)
			else:
				var v = node.value
				if node.inputs[2].level: # EN
					v /= 2 # Shift right
					if node.inputs[1].level: # SI
						v += msbs[node.node.data.bits]
					node.value = v
				update_internal_bus(node.node, v, false, 0)
			return
		"ROM":
			if port == 1 and level == false: # /OE
				update_internal_bus(node.node, node.node.data.memory.words[node.value], false, 0)
			return
		"RAM":
			if port == 3: # /W
				if node.inputs[3].level:
					return
				else:
					node.node.data.memory.words[node.value] = node.node.a
			if node.inputs[2].level: # /OE
				return
			update_internal_bus(node.node, node.node.data.memory.words[node.value], false, 0)
			return
		"DECODER":
			var v = 0
			# Port 0 is the bus
			port = node.node.data.size
			while port > 0:
				v *= 2
				v += int(node.inputs[port].level)
				port -= 1
			update_internal_bus(node.node, v, false, 0)
			return
		"ALU":
			set_internal_value(node.node.name, node.a, reverse, 0)
			return
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
	var vin = 0
	var value = 0
	var values = [0, 0, 0, 0]
	var a = 0
	var b = 0
	var selected_port = 0
	func _init(_node):
		node = _node
		for _n in 6:
			inputs.append(Part.Pin.new())
		for _n in 16:
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
