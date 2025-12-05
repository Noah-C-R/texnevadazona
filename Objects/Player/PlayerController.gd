class_name PlayerController

extends Node3D

@export var c_body : CharacterBody3D
@export var head: Node3D

@export var walk_speed := 5.0
@export var gravity := 0.2
@export var mouse_sensitivity := 0.001

@export var accel := 0.3
@export var decel := 0.3

var walk_sm : StateMachine

var move_axis : Vector3

func set_active():
	walk_sm.transfer("Idle")

func set_inactive():
	walk_sm.transfer("None")

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	walk_sm = StateMachine.create(self)
	walk_sm.debug = true
	walk_sm.add_state("None")
	walk_sm.add_state("Idle", null, null, walk_idle_phys)
	walk_sm.add_state("Walk", null, null, walk_walk_phys)
	
	walk_sm.transfer("Idle")

func _process(_delta: float) -> void:
	move_axis = Vector3(Input.get_axis("Player_Walk_Left", "Player_Walk_Right"), 0, Input.get_axis("Player_Walk_Backward", "Player_Walk_Forward")).normalized()
	
	c_body.move_and_slide()
	
func apply_gravity():
	c_body.velocity.y -= gravity

func apply_idle():
	c_body.velocity.x = lerpf(c_body.velocity.x, 0, decel)
	c_body.velocity.z = lerpf(c_body.velocity.z, 0, decel)

func apply_walk():
	var forwards = -c_body.basis.z * move_axis.z
	var sides = c_body.basis.x * move_axis.x
	var dir = (forwards + sides).normalized()
	
	c_body.velocity.x = lerpf(c_body.velocity.x, dir.x * walk_speed, accel)
	c_body.velocity.z = lerpf(c_body.velocity.z, dir.z * walk_speed, decel)

func _input(event: InputEvent) -> void:
	if walk_sm.current_state.state_name != "None" && event is InputEventMouseMotion:
		var look_axis = event.relative
		c_body.rotate_y(-look_axis.x * mouse_sensitivity)
		head.rotate_x(-look_axis.y * mouse_sensitivity)
		
# remove later and replace with a pause screen or something
#func _unhandled_input(_event):
	#if Input.is_action_just_pressed("Toggle_Mouse"):
		#if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE; 
		#else: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;
		
func walk_idle_phys(_delta : float):
	apply_idle()
	apply_gravity()
	if !move_axis.is_zero_approx():
		walk_sm.transfer("Walk")

func walk_walk_phys(_delta : float):
	apply_walk()
	apply_gravity()
	
	if move_axis.is_zero_approx():
		walk_sm.transfer("Idle")
