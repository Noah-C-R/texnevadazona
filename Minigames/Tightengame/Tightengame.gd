class_name TightenerGame

extends Control

signal minigame_finished(success: bool)

@export var num_dots : int = 12       			# how many dots total for this level
@export var dot_speed : float = 450.0			# Speed of the dots 
@export var spawn_interval_min : float = 0.25	# Min time to spawn
@export var spawn_interval_max : float = 1.0	# Max time to spawn
@export var success_ratio : float = 0.9  		# 90% of dots must be hit
@export var spin_degrees_per_hit : float = 20.0

@onready var bolt_indicator : Sprite2D = $PivotNode/RotatingIndicator
@onready var title_label : Label    = $TitleLabel
@onready var lane        : Control  = $Lane
@onready var hit_zone    : ColorRect = $HitZone
@onready var popup       : Control  = $Popup
@onready var popup_label : Label    = $Popup/Label

enum GameState { INTRO, PLAYING, RESULT }
var state : GameState = GameState.INTRO
var result_success : bool = false
var required_hits : int = 0
var next_spawn_interval : float = 0.0
var hits : int = 0
var active_notes : Array = []
var spawn_timer : float = 0.0
var spawned_count : int = 0
var GoodSound := load("res://Assets/Minigame sounds/tighten.wav")
var BadSound := load("res://Assets/Minigame sounds/tighten_fail.wav")
var screen_height : float = 0.0
var sound_cooldown := 0.1
var last_sound_time := -999.0


func _ready() -> void:
	randomize()
	#bolt_indicator.pivot_offset = bolt_indicator.size * 0.5
	screen_height = get_viewport_rect().size.y
	hits = 0
	required_hits = int(ceil(num_dots * success_ratio))
	_update_title()

	spawned_count = 0
	next_spawn_interval = randf_range(spawn_interval_min, spawn_interval_max)
	_update_title()

	# intro popup
	popup.visible = true
	popup_label.text = "Hit a button when the • is in the zone!"
	state = GameState.INTRO

func _process(delta: float) -> void:
	match state:
		GameState.INTRO:
			_wait_for_any_button_to_start()
		GameState.PLAYING:
			_process_playing(delta)
		GameState.RESULT:
			_wait_for_any_button_to_finish()

func _wait_for_any_button_to_start() -> void:
	if _any_button_pressed():
		popup.visible = false
		state = GameState.PLAYING

func _wait_for_any_button_to_finish() -> void:
	# TODO Connect with main game
	if _any_button_pressed():
		minigame_finished.emit(result_success)

func _any_button_pressed() -> bool:
	return Input.is_action_just_pressed("ui_left") \
		or Input.is_action_just_pressed("ui_right") \
		or Input.is_action_just_pressed("ui_up") \
		or Input.is_action_just_pressed("ui_down") \
		or Input.is_action_just_pressed("ui_cancel") \
		or Input.is_action_just_pressed("ui_b") \
		or Input.is_action_just_pressed("ui_accept") \
		or Input.is_action_just_pressed("ui_select") \
		or Input.is_action_just_pressed("Car_Break") \
		or Input.is_action_just_pressed("Car_Accelerate")

func _process_playing(delta: float) -> void:
	# 1) spawn dots
	if spawned_count < num_dots:
		spawn_timer += delta
		if spawn_timer >= next_spawn_interval:
			spawn_timer = 0.0
			_spawn_dot()
			next_spawn_interval = randf_range(spawn_interval_min, spawn_interval_max)

	# 2) move dots
	_move_notes(delta)

	# 3) check for hits in the zone
	_check_input_for_hit()

	# 4) check for fail
	if spawned_count >= num_dots and active_notes.is_empty() and hits < required_hits:
		_on_fail()


func _spawn_dot() -> void:
	var lbl := Label.new()
	lbl.text = "•"
	lbl.add_theme_font_size_override("font_size", 42)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var start_pos = Vector2()
	start_pos.x = lane.size.x * 0.5 - 8.0
	start_pos.y = 0.0

	lane.add_child(lbl)
	lbl.position = start_pos

	active_notes.append(lbl)
	spawned_count += 1

func _move_notes(delta: float) -> void:
	for lbl in active_notes.duplicate():
		lbl.position.y += dot_speed * delta

		if lbl.global_position.y > screen_height:
			active_notes.erase(lbl)
			play_sound(false)
			lbl.queue_free()

func _check_input_for_hit() -> void:
	if not _any_button_pressed():
		return
	if active_notes.is_empty():
		return

	var lbl : Label = active_notes[0]
	var dot_y = lbl.global_position.y + lbl.size.y * 0.5

	var zone_top    = hit_zone.global_position.y
	var zone_bottom = zone_top + hit_zone.size.y

	if dot_y >= zone_top and dot_y <= zone_bottom:
		_on_correct_hit(lbl)
	else:
		play_sound(false)
		active_notes.erase(lbl)
		lbl.queue_free()

func _on_correct_hit(lbl: Label) -> void:
	play_sound(true)
	hits += 1
	active_notes.erase(lbl)
	lbl.queue_free()
	_update_title()

	# spin bolt
	var target_rotation = bolt_indicator.rotation + deg_to_rad(spin_degrees_per_hit)
	var tween = create_tween()
	tween.tween_property(bolt_indicator, "rotation", target_rotation, 0.1)
	
	if hits >= required_hits:
		_on_success()

func play_sound(is_good: bool) -> void:
	var now := Time.get_ticks_msec() / 1000.0

	if now - last_sound_time < sound_cooldown:
		return

	last_sound_time = now

	if is_good:
		$AudioStreamPlayer.stream = GoodSound
		$AudioStreamPlayer.play(0.0)
	else:
		$AudioStreamPlayer.stream = BadSound
		$AudioStreamPlayer.play(0.0)

func _update_title() -> void:
	var remaining = required_hits - hits
	if remaining < 0:
		remaining = 0
	title_label.text = "Tighten! (%d left)" % remaining

func _on_success() -> void:
	result_success = true
	state = GameState.RESULT
	popup_label.text = "SUCCESS"
	popup.visible = true

func _on_fail() -> void:
	result_success = false
	state = GameState.RESULT
	popup_label.text = "FAILURE"
	popup.visible = true
