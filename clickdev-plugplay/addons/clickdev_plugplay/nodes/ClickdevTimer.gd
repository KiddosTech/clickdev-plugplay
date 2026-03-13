## ClickdevTimer.gd
## Author : Ahmad Ilham Kurniawan
## Version: 1.0.0

@tool
class_name ClickdevTimer
extends Timer

@export var timer_name: String = "Timer1"

func _ready() -> void:
	one_shot = true
