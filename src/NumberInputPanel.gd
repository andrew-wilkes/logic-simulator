extends PopupPanel

var hex_mode: bool
var key_up: bool
var start: bool
var opener
var txt
var n = 0

func open(_hex_mode: bool, width: int):
	opener = self
	txt = $M/HBox/Label
	hex_mode = _hex_mode
	if hex_mode:
		n = 2 if width == 8 else 4
	else:
		n = width
	key_up = true
	start = true
	if _hex_mode:
		txt.text = "Enter HEX value using keyboard"
	else:
		txt.text = "Enter BINARY value using keyboard"
	popup()
	# Correct expansion issue
	yield(get_tree(), "idle_frame")
	rect_size = Vector2.ZERO


func _input(event):
	if event is InputEventKey and opener == self:
		if event.pressed:
			if key_up:
				var x = event.scancode
				if x < 48: # 0
					return
				if hex_mode:
					if x > 96:
						x -= 32 # To uppercase
					if x > 70: # F
						return # Invalid
					if x > 57 and x < 65:
						return
					if start:
						txt.text = "0x" + "0".repeat(n)
				else:
					if x > 49: # 1
						return
					if start:
						txt.text = "0b" + "0".repeat(n)
				for i in n - 1:
					txt.text[2 + i] = txt.text[3 + i]
				txt.text[1 + n] = char(x)
				key_up = false
				start = false
		else:
			key_up = true


func _on_Button_pressed():
	hide()
