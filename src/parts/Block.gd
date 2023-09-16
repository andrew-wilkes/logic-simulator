extends Part

class_name Block

"""
nodes stores PartNode instances
node is PartData instance
"""

var num_slots = 0
var external_inputs = []
var external_outputs = []
var circuit: Circuit
var nodes = {}

func setup():
	set_pins()
	data = { "source_file": "" }
	type = "Block"
	if Data.trace: Logger.clear()


func set_value(v: int, _reverse, port = 0):
	if Data.trace: Logger.add(["set_value", name, v, port])
	var node = external_inputs[port][1]
	update_internal_bus(node, v, 0)


func update_internal_bus(node, value, port):
	if Data.trace: Logger.add(["update_internal_bus", node.name, value, port])
	for con in circuit.connections:
		if con.from == node.name and con.from_port == port:
			if nodes[con.to].node.type == "OUTPUTBUS":
				if Data.trace: Logger.add(["bus_changed", nodes[con.to].node.name, value, nodes[con.to].node.data.port])
				emit_signal("bus_changed", self, value, false, nodes[con.to].node.data.port)
			else:
				set_internal_value(con.to, value, con.to_port)


func set_internal_value(node_name, v, port):
	if Data.trace: Logger.add(["set_internal_value", node_name, v, port])
	var ob = nodes[node_name]
	var obn = ob.node
	match obn.type:
		"LOOPBUS": # Should not be used!
			if ob.value != v:
				ob.value = v
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
		"OUTBUS8", "OUTBUS16":
			for n in ob.outputs.size():
				var level = bool(v % 2)
				v /= 2
				update_internal_output(ob, level, n)
			return
		"REG", "COUNTER", "SHIFTREG":
			if port == 0:
				ob.vin = v
			return
		"ROM":
			# Set address
			v %= obn.data.memory.mem_size
			ob.value = v
			if ob.inputs[1].level: # /OE
				return
			v = obn.data.memory.words[ob.value]
		"RAM":
			if port == 1: # Data
				if obn.data.memory.width == 8:
					v %= 0x100
					ob.vin = v # Remember the value on the data bus 
				if ob.inputs[3].level: # /W
					return
				obn.data.memory.words[ob.value] = v
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
				update_internal_output(ob, v == n, n)
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
			update_internal_output(ob, v >= maxvs[obn.data.bits], 1)
			v %= maxvs[obn.data.bits]
			var msb2 = v >= msbs[obn.data.bits]
			update_internal_output(ob, v == 0, 2) # Zero
			var of = false
			match f:
				2,3,4:
					of = msb2 > msb1
				5:
					of = msb2 < msb1
			update_internal_output(ob, of, 3) # OF
			update_internal_output(ob, msb2, 4) # Sign
	update_internal_bus(obn, v, port)


func reset():
	.reset()
	for node in nodes:
		var n = nodes[node]
		for idx in n.inputs.size():
			n.inputs[idx].count = 0


func update_output(level: bool, port: int, _reverse: bool):
	if Data.trace: Logger.add(["update_output", name, level, port])
	var node = external_inputs[port][1]
	# External port is pin of block
	# Internal pin output is port 0
	apply_internal_inputs(node, level, 0)


func update_internal_output(node, level: bool, port: int):
	if Data.trace: Logger.add(["update_internal_output", node.node.name, level, port])
	node.outputs[port].level = level
	apply_internal_inputs(node.node, level, port)


func apply_internal_inputs(node, level: bool, port: int):
	for con in circuit.connections:
		if con.from == node.name and con.from_port == port:
			apply_internal_input(nodes[con.to], level, con.to_port)


func apply_internal_input(node, level, port):
	if Data.trace: Logger.add(["apply_internal_input", node.node.name, level, port])
	var pin = node.inputs[port]
	if pin.untouched: # Reset this after update_output
		pin.level = not level # Ensure that change is recognized
	# return if no change to established input
	if pin.level == level:
		return false
	# Detect race condition
	pin.count += 1
	if pin.count > RACE_TRIGGER_COUNT:
		emit_signal("unstable", self, port)
		return false
	pin.last_level = pin.level
	pin.level = level
	pin.untouched = false
	port = 0
	match node.node.type:
		"OUTPUTPIN":
			set_output(level, node.node.data.port)
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
		"NOR":
			level = not (node.inputs[0].level or node.inputs[1].level)
		"XOR":
			level = (not node.inputs[0].level and node.inputs[1].level) or (node.inputs[0].level and not node.inputs[1].level)
		"MULT":
			if node.inputs[2].level: # Select
				level = node.inputs[1].level # B
			else:
				level = node.inputs[0].level # A
		"SRFLIPFLOP":
			# Init outputs
			if untouched:
				untouched = false
				update_internal_output(node, false, 0)
				update_internal_output(node, true, 1)
			if node.inputs[0].level: # Set
				update_internal_output(node, not node.inputs[1].level, 0)
				update_internal_output(node, false, 1)
			elif node.inputs[1].level: # Reset
				update_internal_output(node, false, 0)
				update_internal_output(node, not node.inputs[0].level, 1)
			return
		"DLATCH":
			if untouched:
				untouched = false
				update_internal_output(node, false, 0)
				update_internal_output(node, true, 1)
			if node.inputs[0].level: # Enable
				update_internal_output(node, node.inputs[1].level, 0)
				update_internal_output(node, not node.inputs[1].level, 1)
			return
		"DFLIPFLOP":
			if untouched:
				untouched = false
				update_internal_output(node, false, 0)
				node.inputs[2].last_level = false
			if node.inputs[0].level: # Set
				update_internal_output(node, true, 0)
			else:
				if node.inputs[3].level: # Reset
					update_internal_output(node, false, 0)
				else:
					# Detect rising edge of CK
					if node.inputs[2].level and not node.inputs[2].last_level:
						node.inputs[2].last_level = true
						update_internal_output(node, node.inputs[1].level, 0)
					node.inputs[2].last_level = node.inputs[2].level
			return
		"JKFLIPFLOP":
			# Init outputs
			if untouched:
				untouched = false
				update_internal_output(node, false, 0)
				update_internal_output(node, true, 1)
			# Detect rising edge of CK
			if node.inputs[1].level and not node.inputs[1].last_level:
				node.inputs[1].last_level = true
				if node.inputs[0].level and node.inputs[2].level: # Toggle
					update_internal_output(node, not node.outputs[0].level, 0)
					update_internal_output(node, not node.outputs[1].level, 1)
				else:
					if node.inputs[0].level: # Set
						update_internal_output(node, true, 0)
						update_internal_output(node, false, 1)
					if node.inputs[2].level: # Reset
						update_internal_output(node, true, 1)
						update_internal_output(node, false, 0)
			return
		"ADDER":
			if untouched:
				untouched = false
				update_internal_output(node, false, 0)
				update_internal_output(node, false, 1)
			var sum: int = int(node.inputs[0].level) + int(node.inputs[1].level) + int(node.inputs[2].level)
			update_internal_output(node, bool(sum % 2), 0) # Sum
# warning-ignore:integer_division
			update_internal_output(node, bool(sum / 2), 1) # Cout
			return
		"BUSMUX":
			node.selected_port = int(node.inputs[4].level) + 2 * int(node.inputs[5].level)
			update_internal_bus(node.node, node.values[node.selected_port], 0)
			return
		"REG":
			if node.inputs[3].level: # Reset
				node.value = 0
				update_internal_bus(node.node, 0, 0)
			# Detect not rising edge of CK
			if not node.inputs[2].level or node.inputs[2].last_level:
				return
			node.inputs[2].last_level = node.inputs[2].level
			if node.inputs[1].level: # LD
				node.value = node.vin
				update_internal_bus(node.node, node.vin, 0)
			return
		"COUNTER":
			if node.inputs[4].level: # Reset
				node.value = 0
				update_internal_bus(node.node, 0, 0)
			# Detect not rising edge of CK
			if not node.inputs[3].level or node.inputs[3].last_level:
				return
			node.inputs[3].last_level = node.inputs[3].level
			if node.inputs[2].level: # LD
				node.value = node.vin
				update_internal_bus(node.node, node.vin, 0)
			else:
				node.value = wrapi(node.value + int(node.inputs[1].level), 0, 0xffff) 
				update_internal_bus(node.node, node.value, 0)
			return
		"SHIFTREG":
			if node.inputs[5].level: # Reset
				node.value = 0
				update_internal_bus(node.node, 0, 0)
			# Detect not rising edge of CK
			if not node.inputs[4].level or node.inputs[4].last_level:
				return
			node.inputs[4].last_level = node.inputs[4].level
			if node.inputs[3].level: # LD
				node.value = node.vin
				update_internal_bus(node.node, node.vin, 0)
			else:
				var v = node.value
				if node.inputs[2].level: # EN
					v /= 2 # Shift right
					if node.inputs[1].level: # SI
						v += msbs[node.node.data.bits]
					node.value = v
				update_internal_bus(node.node, v, 0)
			return
		"ROM":
			if node.inputs[1].level == false: # /OE
				update_internal_bus(node.node, node.node.data.memory.words[node.value], 0)
			return
		"RAM":
			if node.inputs[3].level == false: # /W
				node.node.data.memory.words[node.value] = node.vin
			if node.inputs[2].level == false: # /OE
				update_internal_bus(node.node, node.node.data.memory.words[node.value], 0)
			return
		"DECODER":
			var v = 0
			# Port 0 is the bus
			port = 4 # Unused inputs should be false
			while port > 0:
				v *= 2
				v += int(node.inputs[port].level)
				port -= 1
			v %= node.node.data.size
			for n in node.node.data.size:
				update_internal_output(node, v == n, n)
			return
		"INBUS8", "INBUS16":
			var v = 0
			for port in range(node.inputs.size() - 1, -1, -1):
				v *= 2
				v += int(node.inputs[port].level)
			set_internal_value(node.node.name, v, 0)
			return
		"ALU":
			set_internal_value(node.node.name, node.a, 0)
			return
	update_internal_output(node, level, port)


func set_the_title(txt: String):
	title = txt.get_file().get_basename().to_upper()


func add_pins(circ: Circuit, add_slots):
	var ok = true
	circuit = circ
	var i = {}
	var o = {}
	for node in circ.nodes:
		match node.type:
			"INPUTPIN":
				i[node.offset.y] = [0, node]
			"INPUTBUS":
				i[node.offset.y] = [1, node]
			"OUTPUTPIN":
				o[node.offset.y] = [0, node]
			"OUTPUTBUS":
				o[node.offset.y] = [1, node]
			"BLOCK":
				ok = load_block_circuit(node)
	var ikeys = i.keys()
	var okeys = o.keys()
	ikeys.sort()
	okeys.sort()
	var port = 0
	for key in ikeys:
		i[key][1].data["port"] = port
		external_inputs.append(i[key])
		if add_slots:
			add_slot()
		port += 1
	port = 0
	for key in okeys:
		o[key][1].data["port"] = port
		external_outputs.append(o[key])
		if add_slots:
			add_slot()
		port += 1
	if add_slots:
		configure_slots()
	add_nodes()
	return ok


class PartNode:
	var node
	var port = 0
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
		for _n in 16:
			inputs.append(Part.Pin.new())
		for _n in 16:
			outputs.append(Part.Pin.new())


func add_nodes():
	for node in circuit.nodes:
		nodes[node.name] = PartNode.new(node)


func add_slot():
	if num_slots < external_inputs.size() or num_slots < external_outputs.size():
		if num_slots > 0:
			add_child($HBox.duplicate()) # Create a new slot
		num_slots += 1


func configure_slots():
	var idx = 0
	var type_left = 0
	var type_right = 0
	var enable_left = false
	var enable_right = false
	var col_left = Color.white
	var col_right = Color.white
	while idx < num_slots:
		if idx < external_inputs.size():
			enable_left = true
			type_left = external_inputs[idx][0]
			if type_left == 0:
				col_left = Color.white
			else:
				col_left = Color.yellow
			get_child(idx).get_child(0).text = external_inputs[idx][1].data.tag
		else:
			enable_left = false
		if idx < external_outputs.size():
			enable_right = true
			type_right = external_outputs[idx][0]
			if type_right == 0:
				col_right = Color.white
			else:
				col_right = Color.yellow
			get_child(idx).get_child(2).text = external_outputs[idx][1].data.tag
		else:
			enable_right = false
		set_slot(idx, enable_left, type_left, col_left, enable_right, type_right, col_right)
		idx += 1


func load_block_circuit(node: Block):
	var ok = false
	if node.data.has("source_file"):
		var sub_circuit = Data.main.load_data(node.data.source_file)
		if sub_circuit is Circuit:
			ok = node.add_pins(sub_circuit, false)
			assert(Data.main.connect_part(node))
	return ok
