extends DamagePoint

@export var wheel : Wheel

@export var effect : GPUParticles3D

func _healthy():
	print("Healthy")
	wheel.base_steer = 0
	wheel.base_rest_len = 0
	wheel.base_brake = 0
	
	effect.emitting = false

func _damaged():
	print("Damaged")
	wheel.base_steer = deg_to_rad(randf_range(-10,10))
	wheel.base_rest_len = randf_range(0.01,0.5)
	
	effect.emitting = true

func _broken():
	print("Broken")
	wheel.base_steer = deg_to_rad(randi_range(-50,50))
	wheel.base_brake = 200
	wheel.base_rest_len = randf_range(0.5,1.5)
	
