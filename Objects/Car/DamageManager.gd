class_name DamageManager

extends Node3D

@export var vehicle_body : VehicleBody3D
var damage_points : Array[Node]

func _ready() -> void:
	damage_points = get_children()

func process_physics(state : PhysicsDirectBodyState3D):
	var num_collisions = state.get_contact_count()
	
	for idx in num_collisions:
		var force = state.get_contact_local_velocity_at_position(idx).length()
		var pos = state.get_contact_local_position(idx)
		
		for damage_point in damage_points:
			if pos.distance_to(damage_point.global_position) < damage_point.influence:
				damage_point.damage(force)
