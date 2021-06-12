extends Control

var main_scene = preload("res://Main.tscn")
var main

func _ready():
	Parts.hide()
	main = main_scene.instance()
	add_child(main)
	test_parts_that_have_tt()


func test_parts_that_have_tt():
	var gid = 0
	for group in Parts.get_children():
		print("Group: ", group.name)
		var idx = 0
		for part in group.get_children():
			if part.has_tt:
				call_deferred("test_part", idx, gid)
				if not yield(main, "test_completed"):
					return
				main.call_deferred("hide_alert")
			var sub_idx = 0
			for subpart in part.get_children():
				if subpart is Part and subpart.has_tt:
					call_deferred("test_part", idx, gid, sub_idx)
					if yield(main, "test_completed"):
						return
					main.call_deferred("hide_alert")
				sub_idx += 1
			idx += 1
		gid += 1
		main.alert("Passed tests")


func check_result(result, part: String):
	if not result[0]:
		main.alert(part + " " + result[1])
	return result[0]


func test_part(idx: int, group: int, subidx = 0):
	var part = Parts.get_part(idx, group, subidx)
	print("Test: ", part.name)
	main.add_part_to_graph(part, Vector2.ZERO)
	main.get_node("TruthTable").open(part)
	var part_data = Data.parts[part.id]
	# Add input pins
	for i in part.get_connection_input_count():
		var input_pin = Parts.get_part(0, 0, 1)
		input_pin.get_node("Pin").text = part_data.inputs[i]
		assert(input_pin.name == "INPUTPIN")
		main.add_part_to_graph(input_pin, Vector2.ZERO)
		main.get_node("Graph").connect_node(input_pin.name, 0, part.name, i)
	# Add output pins
	for i in part.get_connection_output_count():
		var output_pin = Parts.get_part(7, 0, 1)
		output_pin.get_node("Pin").text = part_data.outputs[i]
		assert(output_pin.name == "OUTPUTPIN")
		main.add_part_to_graph(output_pin, Vector2.ZERO)
		main.get_node("Graph").connect_node(part.name, i, output_pin.name, 0)
	main.get_node("TruthTable").run_test()
