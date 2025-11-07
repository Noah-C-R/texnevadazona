class_name DamagePoint

extends Marker3D

signal healthy
signal damaged
signal broken
signal take_damage
signal heal_damage

func _healthy(): pass
func _damaged(): pass
func _broken(): pass
func _take_damage(amount : float): pass
func _heal_damage(amount : float): pass

@export var health : float
@export var max_health : float
@export var influence : float

@export var damage_threshold := 1.5

@export var damaged_level : float
@export var broken_level : float

var damage_sm : StateMachine

func _ready() -> void:
	damage_sm = StateMachine.create(self)
	damage_sm.add_state("Healthy", damage_healthy_enter, null, damage_healthy_phys)
	damage_sm.add_state("Damaged", damage_damaged_enter, null, damage_damaged_phys)
	damage_sm.add_state("Broken", damage_broken_enter, null, damage_broken_phys)
	damage_sm.transfer("Healthy")

func damage(amount : float):
	if amount < damage_threshold: return
	
	var prev_health = health
	health = clamp(health - amount, 0, max_health)
	
	take_damage.emit(amount - health)
	_take_damage(amount - health)

func heal(amount : float):
	health = clamp(health + amount, 0, max_health)
	
	heal_damage.emit(amount - health)
	_heal_damage(amount - health)

func damage_healthy_enter():
	print(name, ": Healthy")
	healthy.emit()
	_healthy()

func damage_healthy_phys(delta : float):
	if health < damaged_level:
		damage_sm.transfer("Damaged")

func damage_damaged_enter():
	print(name, ": Damaged")
	damaged.emit()
	_damaged()
	
func damage_damaged_phys(delta : float):
	if health >= damaged_level:
		damage_sm.transfer("Healthy")
	if health < broken_level:
		damage_sm.transfer("Broken")

func damage_broken_enter():
	print(name, ": Broken")
	broken.emit()
	_broken()
	
func damage_broken_phys(delta : float):
	if health > broken_level:
		damage_sm.transfer("Broken")
