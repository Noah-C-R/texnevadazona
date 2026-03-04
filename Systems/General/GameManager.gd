class_name GameManager

extends Node

@export var warp_effect : ColorRect

static var I : GameManager

func _init():
	I = self

func set_warp_mid_threshold(value : float):
	warp_effect.material.set("shader_parameter/color_mid_threshold", value)

func set_warp_low_color(color : Color):
	warp_effect.material.set("shader_parameter/color_low", color)


func _begin_level(level):
	pass
