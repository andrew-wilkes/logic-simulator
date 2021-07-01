extends Button

signal was_pressed(b)
signal button_timer_timeout(b)

func _ready():
	var _e = connect("pressed", self, "emit_pressed")
	start_timer()


func start_timer():
	$Timer.start()


func emit_pressed():
	emit_signal("was_pressed", self)


func _on_Timer_timeout():
	emit_signal("button_timer_timeout", self)
