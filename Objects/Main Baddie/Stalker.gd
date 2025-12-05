extends CharacterBody3D

var player = null
const SPEED = 4.0

@onready var nav_agent = $NavigationAgent3D


func _ready() -> void:
	while true:
		await get_tree().physics_frame
		

func _physics_process(delta):
	nav_agent.set_target_position(Car.I.global_position)
	var next_nav_point = nav_agent.get_next_path_position()
	
	velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
	
	if global_position.distance_to(next_nav_point) > 1:
		var target_point_level = Vector3(next_nav_point.x, global_position.y, next_nav_point.z)
		var look_direction = (target_point_level - global_position)
		var target_angle = atan2(look_direction.x, look_direction.z)
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 10)
		
	move_and_slide()
