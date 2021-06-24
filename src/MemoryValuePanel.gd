extends PopupPanel

signal value_changed(v)

var value = 0

func _ready():
	var b = $Button
	for n in 16:
		var nb = b.duplicate()
		nb.text = "%0d 0x%X %s" % [n, n, Parts.int2bin(n, 4)]
		nb.connect("pressed", self, "_on_button_pressed", [n])
		$M/Grid.add_child(nb)
	b.hide()


func open(v):
	value = v
	popup_centered()


func _on_button_pressed(n):
	print(n)
	if n != value:
		emit_signal("value_changed", n)
	hide()
