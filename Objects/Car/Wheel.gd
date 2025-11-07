class_name Wheel

extends VehicleWheel3D

@export var base_steer : float:
	set(val):
		steering = steer_val + val
		base_steer = val
	get():
		return base_steer
@export var base_brake : float:
	set(val):
		brake = brake_val + val
		base_brake = val
	get():
		return base_brake

@export var base_accel : float:
	set(val):
		engine_force = accel_val + val
		base_accel = val
	get():
		return base_accel

@export var base_rest_len : float:
	set(val):
		engine_force = rest_len_val + val
		base_rest_len = val
	get():
		return base_accel

var steer_val : float:
	set(val):
		steering = val + base_steer
		steer_val = val
	get():
		return steer_val
var brake_val : float:
	set(val):
		brake = val + base_brake
		brake_val = val
	get():
		return brake_val
var accel_val : float:
	set(val):
		engine_force = val + base_accel
		accel_val = val
	get():
		return accel_val
		
var rest_len_val : float:
	set(val):
		engine_force = val + rest_len_val
		rest_len_val = val
	get():
		return rest_len_val
