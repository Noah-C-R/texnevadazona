class_name Car

extends VehicleBody3D

static var I : Car

@export var damage_manager : DamageManager
@export var interact_manager : InteractManager
@export var car_controller : CarController
@export var camera : Camera3D
@export var car_exit : Marker3D
@export var default_active_state := "Active"

var car_sm : StateMachine

func _init() -> void:
	I = self
	
func _ready() -> void:
	car_sm = StateMachine.create(self)
	car_sm.add_state("Active", car_active_enter)
	car_sm.add_state("Inactive", car_inactive_enter)
	car_sm.transfer(default_active_state)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Car_Exit"):
		car_sm.transfer("Inactive")

func enter_car():
	car_sm.transfer("Active")

func car_active_enter():
	car_controller.set_active()
	camera.make_current()

func car_inactive_enter():
	car_controller.set_inactive()
	Player.I.enter_player()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	damage_manager.process_physics(state)
