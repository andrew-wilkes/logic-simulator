extends Part

var rate = 1.875
var running = false

func _on_Start_pressed():
	if running:
		$Start.text = "Start"
		$Timer.stop()
	else:
		$Start.text = "Stop"
		$Timer.start(1.0 / rate)
		output_levels[0] = false
		set_output(output_levels[0], 0)		
	running = !running


func _on_Rate_pressed():
	rate = wrapf(rate * 2.0, 0.9375, 60.0)
	$Timer.wait_time = 1.0 / rate


func _on_Reset_button_down():
	set_output(true, 1)


func _on_Reset_button_up():
	set_output(false, 1)


func _on_Timer_timeout():
	output_levels[0] = !output_levels[0]
	set_output(output_levels[0], 0)
