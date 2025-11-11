class_name InteractManager

extends Node3D
	
var interact_points : Array[Node]

func _ready() -> void:
	interact_points = get_children()

func interact(point : Vector3):
	for interact_point in interact_points:
		if point.distance_to(interact_point.global_position) < interact_point.range:
			interact_point.interact()
			return interact_point.name
	
	return ""
