extends Node

var thelog: PoolStringArray

func _ready():
	if Data.trace:
		$Popup.show()


func add(items: Array):
	var txt = "%-26s" % items[0]
	for i in items.size():
		if i > 0:
			txt += "%-12s" % items[i]
	thelog.append(txt)


func output():
	print(thelog.join("\n"))


func clear():
	thelog.resize(0)


func save():
	var fn = "../data/log.txt"
	var file = File.new()
	file.open(fn, File.WRITE)
	file.store_string(thelog.join("\n"))
	file.close()


func _on_Clear_pressed():
	clear()


func _on_Print_pressed():
	output()


func _on_Save_pressed():
	save()
