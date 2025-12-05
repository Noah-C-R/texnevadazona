extends Control

signal minigame_finished(success: bool)

@onready var round_indicator : Control = $RoundIndicator
@onready var progress_bar    : Range   = $Progress
@onready var popup           : Control = $Popup
@onready var popup_label     : Label   = $Popup/Label
@onready var sfx_player      : AudioStreamPlayer2D = $AudioStreamPlayer

var progress : float = 0.0
var progress_per_hit : float = 2.0      # how much each press adds
var drain_rate : float = 5.0            # percent per second to drain
var lit_time : float = 0.0              # how long the indicator stays bright
var lit_duration : float = 0.1          # seconds
var last_sound_time := -999.0
var sound := load("res://Assets/Minigame sounds/masher.wav")
enum GameState { INTRO, PLAYING, RESULT }
var state : GameState = GameState.INTRO
var result_success : bool = false

func _ready() -> void:
	randomize()
	progress = 10.0
	progress_bar.value = progress

	round_indicator.modulate = Color(0.5, 0.5, 0.5, 1.0) # dim

	popup.visible = true
	popup_label.text = "Mash any button to fill the bar!"
	sfx_player.stream = sound
	
func _process(delta: float) -> void:
	match state:
		GameState.INTRO:
			_wait_for_any_button_to_start()
		GameState.PLAYING:
			_process_playing(delta)
		GameState.RESULT:
			_wait_for_any_button_to_finish()

func _process_playing(delta: float) -> void:
	# drain
	progress -= drain_rate * delta
	if progress < 0.0:
		progress = 0.0

	_update_progress_bar()

	if progress <= 0.0:
		_on_fail()
		return
	elif progress >= 95.0:
		_on_success()
		return

	# Flash asset on button hit
	if lit_time > 0.0:
		lit_time -= delta
		if lit_time <= 0.0:
			round_indicator.modulate = Color(0.5, 0.5, 0.5, 1.0) # dim

	_check_input()

func _check_input() -> void:
	if Input.is_action_just_pressed("ui_cancel") \
		or Input.is_action_just_pressed("ui_b") \
		or Input.is_action_just_pressed("ui_accept") \
		or Input.is_action_just_pressed("ui_select"):

		progress += progress_per_hit
		if progress > 100.0:
			progress = 100.0

		_update_progress_bar()
		_light_indicator()
		play_sound()

func _light_indicator() -> void:
	round_indicator.modulate = Color(1.0, 1.0, 1.0, 1.0) 
	lit_time = lit_duration

func _update_progress_bar() -> void:
	progress_bar.value = progress

func _wait_for_any_button_to_start() -> void:
	if _any_face_button_pressed():
		popup.visible = false
		state = GameState.PLAYING

func _wait_for_any_button_to_finish() -> void:
	# TODO Connect with main game
	if _any_face_button_pressed():
		minigame_finished.emit(result_success)
		get_tree().quit() # replace with scene change later

func _any_face_button_pressed() -> bool:
	return Input.is_action_just_pressed("ui_cancel") \
		or Input.is_action_just_pressed("ui_b") \
		or Input.is_action_just_pressed("ui_accept") \
		or Input.is_action_just_pressed("ui_select")

func play_sound():
	var now := Time.get_ticks_msec() / 1000.0

	if now - last_sound_time < 0.3:
		return

	last_sound_time = now
	$AudioStreamPlayer.play(0.0)


func _on_success() -> void:
	print("WIN")
	state = GameState.RESULT
	result_success = true
	popup_label.text = "SUCCESS"
	popup.visible = true

func _on_fail() -> void:
	print("FAIL")
	state = GameState.RESULT
	result_success = false
	popup_label.text = "FAILURE"
	popup.visible = true
