class_name CarController

extends Node3D

@export var acceleration : float
@export var max_speed : float
@export var reverse_acceleration : float
@export var max_reverse_speed : float
@export var boost_acceleration : float
@export var max_boost_speed : float
@export var break_force : float
@export_range(0,90) var steering_angle : float
@export_range(0,2) var steering_time_sec : float
@export_range(1,10) var steering_angle_velocity_mod : float
@export_range(1,10) var steering_speed_velocity_mod : float

@export_group("VehicleBodies")
@export var vehicle_body : VehicleBody3D
@export var wheel_front_left : Wheel
@export var wheel_front_right : Wheel
@export var wheel_back_left : Wheel
@export var wheel_back_right : Wheel

@export_group("Sounds")
@export var sound_idle : AudioStreamPlayer
@export var sound_accel : AudioStreamPlayer
@export var sound_rev : AudioStreamPlayer

var idle_volume := -20
var accel_volume := -10


var engine_sm : StateMachine
var steering_sm : StateMachine

var forward_velocity_mag : float
var steering_angle_mag : float
var steering_speed_mag : float
var steering_tween : Tween

var last_active_engine_state : String
var last_active_steer_state : String

func set_active():
	engine_sm.transfer(last_active_engine_state)
	steering_sm.transfer(last_active_steer_state)

func set_inactive():
	last_active_engine_state = engine_sm.current_state.state_name
	last_active_steer_state = steering_sm.current_state.state_name
	engine_sm.transfer("None")
	steering_sm.transfer("None")

func _ready() -> void:
	steering_tween = create_tween()
	engine_sm = StateMachine.create(self)
	steering_sm = StateMachine.create(self)
	
	engine_sm.add_state("None")
	engine_sm.add_state("Idle", engine_idle_enter, null, engine_idle_phys, engine_idle_exit)
	engine_sm.add_state("Accelerate", engine_accelerate_enter, null, engine_accelerate_phys, engine_accelerate_exit)
	engine_sm.add_state("Break", engine_break_enter, null, engine_break_phys, engine_break_exit)
	engine_sm.add_state("Reverse", engine_reverse_enter, null, engine_reverse_phys, engine_boost_exit)
	engine_sm.add_state("Boost", engine_boost_enter, null, engine_boost_phys, engine_boost_exit)
	engine_sm.add_state("Park", engine_park_enter, null, engine_park_phys)
	
	steering_sm.add_state("None")
	steering_sm.add_state("Center", steering_center_enter, null, steering_center_process)
	steering_sm.add_state("Left", steering_left_enter, null, steering_left_phys)
	steering_sm.add_state("Right", steering_right_enter, null, steering_right_phys)

	engine_sm.transfer("Idle")
	steering_sm.transfer("Center")

func _physics_process(_delta: float) -> void:
	forward_velocity_mag = abs((vehicle_body.linear_velocity * vehicle_body.transform.basis.z).length())
	steering_angle_mag = clamp(remap(forward_velocity_mag, 0, max_speed, 1, steering_angle_velocity_mod), 1, steering_angle_velocity_mod)
	steering_speed_mag = clamp(remap(forward_velocity_mag, 0, max_speed, 1, steering_speed_velocity_mod), 1, steering_speed_velocity_mod)

func set_steer(val):
	wheel_front_left.steer_val = val
	wheel_front_right.steer_val = val

func set_accel(val):
	wheel_back_left.accel_val = val
	wheel_back_right.accel_val = val

func set_break(val):
	wheel_back_left.brake_val = val
	wheel_back_right.brake_val = val

func engine_idle_enter():
	set_accel(0.0)
	set_break(0.0)
	
	get_tree().create_tween().tween_property(sound_idle, "volume_db", idle_volume, 2)
	sound_idle.play()
	
func engine_idle_phys(_delta : float):
	if Input.is_action_pressed("Car_Accelerate"):
		engine_sm.transfer("Accelerate")
	elif Input.is_action_pressed("Car_Break"):
		engine_sm.transfer("Break")
	elif Input.is_action_just_released("Car_Park"):
		engine_sm.transfer("Park")

func engine_idle_exit():
	print("EXIT IDLE")
	var tween = get_tree().create_tween().tween_property(sound_idle, "volume_db", -30, 1)
	
func engine_accelerate_enter():
	set_accel(acceleration)
	set_break(0)
	
	get_tree().create_tween().tween_property(sound_accel, "volume_db", accel_volume, 2)
	sound_accel.play()
	

func engine_accelerate_phys(_delta : float):
	if forward_velocity_mag > max_speed:
		set_accel(0)
	else:
		set_accel(acceleration)
	
	if Input.is_action_pressed("Car_Boost"):
		engine_sm.transfer("Boost")
	elif Input.is_action_just_released("Car_Accelerate"):
		engine_sm.transfer("Idle")

func engine_accelerate_exit():
	get_tree().create_tween().tween_property(sound_accel, "volume_db", -30, 2)

func engine_break_enter():
	set_accel(0)
	set_break(break_force)
	
func engine_break_phys(_delta : float):
	if Input.is_action_just_released("Car_Break"):
		engine_sm.transfer("Idle")

	if forward_velocity_mag < 0.1:
		engine_sm.transfer("Reverse")
		
func engine_break_exit():
	set_break(0)
	
func engine_reverse_enter():
	set_break(0)
	await get_tree().create_timer(0.3).timeout
	set_accel(-reverse_acceleration)

func engine_reverse_phys(_delta : float):
	if Input.is_action_just_released("Car_Break"):
		engine_sm.transfer("Idle")
		
func engine_reverse_exit():
	set_accel(0)

func engine_boost_enter():
	set_accel(boost_acceleration)
	set_break(0)

func engine_boost_phys(_delta : float):
	if forward_velocity_mag > max_boost_speed:
		set_accel(0)
	else:
		set_accel(boost_acceleration)
	
	if Input.is_action_just_released("Car_Boost"):
		engine_sm.transfer("Idle")
		
func engine_boost_exit():
	set_accel(0)

func engine_park_enter():
	set_break(1000)
	set_accel(0)

func engine_park_phys(_delta : float):
	if Input.is_action_just_released("Car_Park"):
		set_break(0)
		engine_sm.transfer("Idle")

func steering_center_enter():
	if steering_tween:
		steering_tween.kill()
		steering_tween = create_tween()
	steering_tween.tween_property(wheel_front_left, "steer_val", 0, steering_time_sec)
	steering_tween.parallel().tween_property(wheel_front_right, "steer_val", 0, steering_time_sec)

func steering_center_process(_delta : float):
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
	steering_tween.tween_property(wheel_front_left, "steer_val", target_angle / steering_angle_mag, steering_time_sec * steering_speed_mag)
	steering_tween.parallel().tween_property(wheel_front_right, "steer_val", target_angle / steering_angle_mag, steering_time_sec * steering_speed_mag)

func steering_left_phys(_delta : float):
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
	steering_tween.tween_property(wheel_front_left, "steer_val", target_angle / steering_angle_mag, steering_time_sec * steering_speed_mag)
	steering_tween.parallel().tween_property(wheel_front_right, "steer_val", target_angle / steering_angle_mag, steering_time_sec * steering_speed_mag)

func steering_right_phys(_delta : float):
	var axis = Input.get_axis("Car_Turn_Left", "Car_Turn_Right")
	if axis == 0:
		steering_sm.transfer("Center")
	elif axis == -1:
		steering_sm.transfer("Left")
