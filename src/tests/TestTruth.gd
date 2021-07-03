extends Control

var main_scene = preload("res://Main.tscn")
var main

func _ready():
	Parts.hide()
	main = main_scene.instance()
	add_child(main)
	main.get_node("TestTimer").wait_time = 0.05
	test_parts_that_have_tt()
	#test_part("JKFLIPFLOP")


func test_parts_that_have_tt():
	for group in Parts.get_children():
		print("Group: ", group.name)
		for part in group.get_children():
			if part.has_tt:
				call_deferred("test_part", part.name)
				if not yield(main, "test_completed"):
					return
				main.call_deferred("hide_alert")
			for subpart in part.get_children():
				if subpart is Part and subpart.has_tt:
					call_deferred("test_part", subpart.name)
					if yield(main, "test_completed"):
						return
					main.call_deferred("hide_alert")
		main.call_deferred("alert", "Passed tests")


func check_result(result, part: String):
	if not result[0]:
		main.alert(part + " " + result[1])
	return result[0]


func test_part(type: String):
	var part = Parts.get_part(type)
	print("Test: ", part.name)
	var pos = Vector2(200 + randf() * 1500, randf() * 600)
	main.add_part_to_graph(part, pos)
	main.get_node("c/TruthTable").open(part)
	var part_data = Data.parts[part.type]
	# Add input pins
	for i in part.get_connection_input_count():
		var input_pin = Parts.get_part("INPUTPIN")
		input_pin.get_node("Pin").text = part_data.inputs[i]
		assert(input_pin.name == "INPUTPIN")
		main.add_part_to_graph(input_pin, Vector2(pos.x - 200, pos.y - rand_range(-100, 100)))
		main.get_node("Graph").connect_node(input_pin.name, 0, part.name, i)
	# Add output pins
	for i in part.get_connection_output_count():
		var output_pin = Parts.get_part("OUTPUTPIN")
		output_pin.get_node("Pin").text = part_data.outputs[i]
		assert(output_pin.name == "OUTPUTPIN")
		main.add_part_to_graph(output_pin, Vector2(pos.x + 200, pos.y - rand_range(-100, 100)))
		main.get_node("Graph").connect_node(part.name, i, output_pin.name, 0)
	main.get_node("c/TruthTable").run_test()
