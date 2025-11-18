extends Node

func _ready() -> void:
	for level in get_children():
		level.queue_free()
