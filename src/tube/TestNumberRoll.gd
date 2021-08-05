extends Node2D

func _ready():
	Parts.hide()


func _process(delta):
	pass #$PB/PL.motion_offset.y += delta * 100


func _on_Timer_timeout():
	$ViewportContainer/NumberRoll.inc()
