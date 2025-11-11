class_name Player

extends Node3D

static var I : Player

@export var camera : Camera3D
@export var player_controller : PlayerController
@export var collision_shape : CollisionShape3D
@export var hand_raycast : RayCast3D
@export var pointer : TextureRect
@export var default_active_state := "Inactive"

var player_sm : StateMachine

var current_carpart_hover : String

func _init() -> void:
	I = self

func _ready() -> void:
	player_sm = StateMachine.create(self)
	player_sm.add_state("Active", player_active_enter)
	player_sm.add_state("Inactive", player_inactive_enter)
	player_sm.transfer(default_active_state)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Action"):
		interact()

func interact():
	match current_carpart_hover:
		"CarDoor":
			player_sm.transfer("Inactive")
			Car.I.enter_car()
		
func _physics_process(delta: float) -> void:
	if hand_raycast.is_colliding():
		var col = hand_raycast.get_collider()
		if col is Car:
			var interaction = Car.I.interact_manager.interact(hand_raycast.get_collision_point())
			if !interaction.is_empty():
				current_carpart_hover = interaction
				set_pointer_color(Color.RED)
			else:
				current_carpart_hover = ""
				set_pointer_color(Color.WHITE)

func set_pointer_color(color : Color):
	pointer.modulate = color
	
func enter_player():
	player_sm.transfer("Active")

func player_active_enter():
	camera.make_current()
	player_controller.set_active()
	collision_shape.disabled = false
	global_position = Car.I.car_exit.global_position
	visible = true

func player_inactive_enter():
	player_controller.set_inactive()
	collision_shape.disabled = true
	visible = false
