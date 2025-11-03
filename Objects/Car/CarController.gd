class_name CarController

extends Node3D

@export var acceleration : float
@export var max_speed : float
@export var boost_acceleration : float
@export var max_boost_speed : float
@export var break_force : float
@export_range(0,90) var steering_angle : float
@export_range(0,2) var steering_time_sec : float
@export_range(1,5) var steering_speed_mod : float

@export_group("VehicleBodies")
@export var vehicle_body : VehicleBody3D
@export var wheel_front_left : VehicleWheel3D
@export var wheel_front_right : VehicleWheel3D
@export var wheel_back_left : VehicleWheel3D
@export var wheel_back_right : VehicleWheel3D

var engine_sm : StateMachine
var steering_sm : StateMachine

var forward_velocity_mag : float
var steering_mag : float
var steering_tween : Tween

func _ready() -> void:
	steering_tween = create_tween()
	engine_sm = StateMachine.create(self)
	steering_sm = StateMachine.create(self)
	
	engine_sm.debug = true
	steering_sm.debug = true
	
	engine_sm.add_state("Idle", engine_idle_enter, null, engine_idle_phys)
	engine_sm.add_state("Accelerate", engine_accelerate_enter, null, engine_accelerate_phys)
	engine_sm.add_state("Break", engine_break_enter, null, engine_break_phys, engine_break_exit)
	engine_sm.add_state("Boost", engine_boost_enter, null, engine_boost_phys, engine_boost_exit)
	
	steering_sm.add_state("Center", steering_center_enter, null, steering_center_process)
	steering_sm.add_state("Left", steering_left_enter, null, steering_left_phys)
	steering_sm.add_state("Right", steering_right_enter, null, steering_right_phys)

	engine_sm.transfer("Idle")
	steering_sm.transfer("Center")

func _physics_process(delta: float) -> void:
	forward_velocity_mag = abs((vehicle_body.linear_velocity * vehicle_body.transform.basis.z).length())
	steering_mag = remap(forward_velocity_mag, 0, max_speed, 1, steering_speed_mod)
	
func engine_idle_enter():
	vehicle_body.engine_force = 0
	vehicle_body.brake = 0
	
func engine_idle_phys(delta : float):
	if Input.is_action_pressed("Car_Accelerate"):
		engine_sm.transfer("Accelerate")
	elif Input.is_action_pressed("Car_Break"):
		engine_sm.transfer("Break")
	
func engine_accelerate_enter():
	vehicle_body.engine_force = acceleration
	vehicle_body.brake = 0

func engine_accelerate_phys(elta : float):
	if forward_velocity_mag > max_speed:
		vehicle_body.engine_force = 0
	else:
		vehicle_body.engine_force = acceleration
	
	if Input.is_action_pressed("Car_Boost"):
		engine_sm.transfer("Boost")
	elif Input.is_action_just_released("Car_Accelerate"):
		engine_sm.transfer("Idle")
		
func engine_break_enter():
	vehicle_body.engine_force = 0
	vehicle_body.brake = break_force
	
func engine_break_phys(delta : float):
	if Input.is_action_just_released("Car_Break"):
		engine_sm.transfer("Idle")
		
func engine_break_exit():
	vehicle_body.brake = 0

func engine_boost_enter():
	vehicle_body.engine_force = boost_acceleration
	vehicle_body.brake = 0

func engine_boost_phys(delta : float):
	if forward_velocity_mag > max_boost_speed:
		vehicle_body.engine_force = 0
	else:
		vehicle_body.engine_force = boost_acceleration
	
	if Input.is_action_just_released("Car_Boost"):
		engine_sm.transfer("Idle")
		
func engine_boost_exit():
	vehicle_body.engine_force = 0

func steering_center_enter():
	if steering_tween:
		steering_tween.kill()
		steering_tween = create_tween()
	steering_tween.tween_property(vehicle_body, "steering", 0, .5)

func steering_center_process(delta : float):
	var axis = Input.get_axis("Car_Turn_Left", "Car_Turn_Right")
	if axis == -1:
		steering_sm.transfer("Left")
	elif axis == 1:
		steering_sm.transfer("Right")

func steering_left_enter():
	var target_angle = deg_to_rad(steering_angle)
	
	if steering_tween:
		steering_tween.kill()
		steering_tween = create_tween()
	steering_tween.tween_property(vehicle_body, "steering", target_angle / steering_mag, steering_time_sec)

func steering_left_phys(delta : float):
	var axis = Input.get_axis("Car_Turn_Left", "Car_Turn_Right")
	if axis == 0:
		steering_sm.transfer("Center")
	elif axis == 1:
		steering_sm.transfer("Right")

func steering_right_enter():
	var target_angle = -deg_to_rad(steering_angle)
	
	if steering_tween:
		steering_tween.kill()
		steering_tween = create_tween()
	steering_tween.tween_property(vehicle_body, "steering", target_angle / steering_mag, steering_time_sec)

func steering_right_phys(delta : float):
	var axis = Input.get_axis("Car_Turn_Left", "Car_Turn_Right")
	if axis == 0:
		steering_sm.transfer("Center")
	elif axis == -1:
		steering_sm.transfer("Left")
