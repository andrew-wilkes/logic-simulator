extends Part

class_name BiOutput

func update_output(level: bool, _port: int, _reverse: bool):
	$Label.text = String(int(level))
