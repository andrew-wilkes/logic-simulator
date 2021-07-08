extends Part

class_name BiOutput

func update_output(level: bool, _port: int, _reverse: bool):
	$Label.text = String(int(level))


func set_data(d: Dictionary):
	if d.has("tag"):
		data = d
		$Tag.text = d.tag


func get_data():
	return { "tag": $Tag.text }
