extends Area3D

@export var action_name: String

func _ready() -> void:
	var sibling_node = get_parent().get_node("meshes").get_children()
	
	input_ray_pickable = true

func _input_event(camera, event, position, normal, shape_idx) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		_on_clicked()

func _on_clicked() -> void:
	match action_name:
		"play":
			get_tree().change_scene_to_file("res://scenes/Level1.tscn")
		"options":
			print("PUT OPTIONS MENU HERE :DDDDDD")
		"quit":
			get_tree().quit()
