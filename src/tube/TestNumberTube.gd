extends Node2D

func _ready():
	Parts.hide()

func _on_Timer_timeout():
	$ViewportContainer/Viewport/NumberTube/NumberRoll.dec()
