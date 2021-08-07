extends TabContainer

const ROLL_DELAY = 0.5
const REPEAT_DELAY = 0.2
const MESSAGE_TIME = 0.5

var message
var num_roll: NumberRoll
var bits
var up: bool
var rt: Timer
var rolling = false
var hex: Label
var dec: Label
var neg: Label

func _ready():
	Parts.hide()
	message = find_node("Message")
	bits = find_node("Bits")
	num_roll = find_node("NumberRoll")
	rt = find_node("RollTimer")
	hex = find_node("hex")
	dec = find_node("dec")
	neg = find_node("neg")
	var _e = num_roll.connect("notice", self, "update_message")
	bits.text = String(num_roll.num_bits)
	show_value()


func update_message(id):
	match id:
		num_roll.BORROW:
			message.text = "Borrow in"
		num_roll.OVERFLOW:
			message.text = "Signed overflow"
		num_roll.CARRY:
			message.text = "Carry out"
		num_roll.OK:
			message.text = ""
	if id != num_roll.OK:
		rt.paused = true
		yield(get_tree().create_timer(MESSAGE_TIME), "timeout")
		message.text = ""
		rt.paused = false


func _on_BitsButton_pressed():
	num_roll.num_bits = wrapi(num_roll.num_bits + 1, 4, 9)
	num_roll.set_values(num_roll.BIN)
	bits.text = String(num_roll.num_bits)
	num_roll.value = 0
	show_value()


func _on_RollTimer_timeout():
	if rolling:
		if up:
			num_roll.inc()
		else:
			num_roll.dec()
		rt.start(REPEAT_DELAY)
		show_value()


func _on_Up_button_down():
	num_roll.inc()
	up = true
	rt.start(ROLL_DELAY)
	rolling = true
	show_value()


func _on_Up_button_up():
	rolling = false
	rt.stop()


func _on_Down_button_down():
	num_roll.dec()
	up = false
	rt.start(ROLL_DELAY)
	rolling = true
	show_value()


func _on_Down_button_up():
	rolling = false
	rt.stop()


func show_value():
	if num_roll.value >= num_roll.maxv / 2:
		neg.text = String(num_roll.value - num_roll.maxv)
	else:
		neg.text = String(num_roll.value)
	dec.text = String(num_roll.value)
	hex.text = "0x%02X" % num_roll.value


func _on_Learn_tab_selected(tab):
	if tab == 1:
		var _e = get_tree().change_scene("res://Main.tscn")
