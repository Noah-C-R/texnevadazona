extends InteractPoint

@export var wheel_damage_point : DamagePoint

func fix():
	wheel_damage_point.heal(100)
	print("HEAL WHEEL")
