extends DamagePoint

@export var wheel : Wheel

func _healthy():
	print("Healthy")

func _damaged():
	print("Damaged")
	wheel.base_steer = deg_to_rad(randf_range(-10,10))
	wheel.base_rest_len = randf_range(0.01,0.5)

func _broken():
	print("Broken")
	wheel.base_steer = deg_to_rad(randi_range(-50,50))
	wheel.base_brake = 200
	wheel.base_rest_len = randf_range(0.5,1.5)
	
