extends Control

#export var run_tool = true setget add_mouse_sensor

func get_part(part_name: String):
	var part = find_node(part_name).duplicate()
	part.type = part_name
	part.has_tt = Data.parts.has(part.type)
	part.setup()
	return part


func add_mouse_sensor(_v):
	#return
	#var mouse_sensor = Control.new()
	#mouse_sensor.mouse_filter = Control.MOUSE_FILTER_PASS
	#mouse_sensor.name = "PHOV"
	#for group in get_children():
	#	for p in group.get_children():
	for p in $Gates/OUTPUT.get_children():
			var node = p.get_node_or_null("PHOV")
			if node != null:
				node.queue_free()
				print(p.name)
		#print(p.owner.name)
		#var ms = mouse_sensor.duplicate()
		#p.add_child(ms)
		#ms.set_owner(get_tree().get_edited_scene_root())
