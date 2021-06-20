extends Button

signal was_pressed(me)

func _ready():
	var _e = connect("pressed", self, "emit_pressed")


func emit_pressed():
	emit_signal("was_pressed", self)
