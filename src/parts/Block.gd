extends Part

var num_slots = 0
var inputs_to_add = []
var outputs_to_add = []

func set_the_title(txt: String):
	title = txt.get_file().get_basename().to_upper()


func add_pins(circuit: Circuit, file_name):
	set_the_title(file_name)
	for node in circuit.nodes:
		match node.type:
			"INPUTPIN":
				add_slot()
				inputs_to_add.append([0, node.name])
			"INPUTBUS":
				add_slot()
				inputs_to_add.append([1, node.name])
			"OUTPUTPIN":
				add_slot()
				outputs_to_add.append([0, node.name])
			"OUTPUTBUS":
				add_slot()
				outputs_to_add.append([1, node.name])
	configure_slots()


func add_slot():
	if num_slots < inputs_to_add.size() or num_slots < outputs_to_add.size():
		var slot
		if num_slots > 0:
			slot = $HBox.duplicate()
		else:
			slot = $HBox
		add_child(slot) # Create a new slot
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
			col_left = Color.red
			$HBox/Left.text = inputs_to_add[idx][1]
		else:
			enable_left = false
		if idx < outputs_to_add.size():
			enable_right = true
			type_right = outputs_to_add[idx][0]
			col_right = Color.red
			$HBox/Right.text = inputs_to_add[idx][1]
		else:
			enable_right = false
		set_slot(idx, enable_left, type_left, col_left, enable_right, type_right, col_right)
