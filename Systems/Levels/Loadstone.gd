class_name Loadstone

extends Marker3D

@export var trigger_range := 300
@export var unload_distance := 1200
@export var level_scn : PackedScene
@export var level_parent : Node

var level : Node
func _physics_process(_delta: float) -> void:
	if !level && global_position.distance_to(Car.I.global_position) < trigger_range:
		level = level_scn.instantiate()
		level_parent.add_child(level)
		
		if level.has_method("on_load"):
			level.on_load()
	
	if level && global_position.distance_to(Car.I.global_position) > unload_distance:
		if level.has_method("on_unload"):
			level.on_unload()
		
		level.queue_free()
		level = null
	
