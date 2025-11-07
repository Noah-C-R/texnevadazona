extends VehicleBody3D

@export var damage_manager : DamageManager

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	damage_manager.process_physics(state)
