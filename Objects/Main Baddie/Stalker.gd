extends CharacterBody3D

var player = null
const SPEED = 4.0

@onready var nav_agent = $NavigationAgent3D
	
func _process(delta):
	velocity = Vector3.ZERO
	nav_agent.set_target_position(Car.I.global_position)
	var next_nav_point = nav_agent.get_next_path_position()
	velocity = (next_nav_point - global_transform.origin).normalized() * SPEED
	move_and_slide()	
	
