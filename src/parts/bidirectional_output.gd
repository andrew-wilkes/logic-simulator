extends Part

class_name BiOutput

func _ready():
	is_input = true
	var _e = $Tag.connect("text_changed", self, "text_changed")


func text_changed(_t):
	emit_signal("data_changed")


func update_output(level: bool, _port: int, _reverse: bool):
	$Label.text = String(int(level))


func set_data(d: Dictionary):
	if has_node("Tag") and d.has("tag"):
		data = d
		$Tag.text = d.tag


func get_data():
	return { "tag": $Tag.text }

