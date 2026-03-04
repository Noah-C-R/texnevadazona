class_name DamageManager

extends Node3D

@export var vehicle_body : VehicleBody3D
@export_group("Sounds")
@export var sound_break_1 : AudioStreamPlayer
@export var sound_break_2 : AudioStreamPlayer
@export var sound_break_3 : AudioStreamPlayer
@export var sound_alarm_1 : AudioStreamPlayer

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
				
				if force > 10:
					
					if !sound_break_1.playing: sound_break_1.play()
					elif !sound_break_2.playing: sound_break_2.play()
					elif !sound_break_3.playing: sound_break_2.play()
				
					if damage_point.health <= 0:
						if !sound_alarm_1.playing: sound_alarm_1.play()
	
	var damaged : bool
	for point in damage_points:
		if point.health <= 0:
			damaged = true
		
	if !damaged && sound_alarm_1.playing:
		sound_alarm_1.stop()
