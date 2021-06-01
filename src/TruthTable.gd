extends Control

func _ready():
	var data = {
		"inputs": ["clock", "D", "S", "R"],
		"outputs": ["Q"],
		"tt": [
			[0,"X",0,0,"L"],
			[1,"X",0,0,"L"],
			["+",0,0,0,0],
			["+",1,0,0,1],
			["X","X",1,0,1],
			["X","X",0,1,0],
			["X","X",1,1,1]
		]
	}
	var grid: GridContainer = $Grid
	grid.columns = data.inputs.size() + data.outputs.size()
	for txt in data.inputs:
		grid.add_child(get_header_label(txt, false))
	for txt in data.outputs:
		grid.add_child(get_header_label(txt, true))
	var idx = 1
	for row in data.tt:
		for txt in row:
			grid.add_child(get_item_label(String(txt), idx > data.inputs.size()))
			idx += 1
		idx = 1
	$Header1.hide()
	$Header2.hide()
	$Cell1.hide()
	$Cell2.hide()
	if get_parent().name == "root":
		show()


func get_header_label(txt, is_output: bool):
	var l = $Header2.duplicate() if is_output else $Header1.duplicate()
	l.text = txt
	return l


func get_item_label(txt, is_output: bool):
	match txt:
		"+":
			txt = "Rising edge"
		"-":
			txt = "Falling edge"
		"L":
			txt = "Last value"
	var l = $Cell2.duplicate() if is_output else $Cell1.duplicate()
	l.text = txt
	return l
