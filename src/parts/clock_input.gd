extends Part

class_name ClockInput

var rate = 1.875
var running = false

func _ready():
	is_input = true


func _on_Start_pressed():
	if running:
		$Start.text = "Start"
		$Timer.stop()
	else:
		$Start.text = "Stop"
		$Timer.start(1.0 / rate)
		output_pins[0].level = false
		set_output(output_pins[0].level, 0)
	running = !running


func _on_Rate_pressed():
	rate = wrapf(rate * 2.0, 0.9375, 60.0)
	$Timer.wait_time = 1.0 / rate


func _on_Reset_button_down():
	set_output(true, 1)


func _on_Reset_button_up():
	set_output(false, 1)


func _on_Timer_timeout():
	output_pins[0].level = !output_pins[0].level
	set_output(output_pins[0].level, 0)


func setup():
	.setup()
	set_output(false, 0)
	set_output(false, 1)
