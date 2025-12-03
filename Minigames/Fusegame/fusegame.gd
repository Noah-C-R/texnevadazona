extends Control

const GRID_COLS := 4
const GRID_ROWS := 4
const GRID_SIZE := GRID_COLS * GRID_ROWS
const MIN_BROKEN := 2
const MAX_BROKEN := 4

enum FuseState { GOOD, BROKEN }
enum GameState { INTRO, PLAYING }

@onready var selection_rect : ColorRect   = $Selection
@onready var title_label    : Label       = $TitleLabel
@onready var grid           : GridContainer = $Grid
@onready var fuse_window    : Control     = $FuseWindow
@onready var fuse_sprite    : TextureRect = $FuseWindow/FuseSprite
@onready var broken_fuse    : Texture2D   = load("res://Minigames/Fusegame/brokenfuse.png")
@onready var good_fuse      : Texture2D   = load("res://Minigames/Fusegame/goodfuse.png")

@onready var popup          : Control     = $Popup
@onready var popup_label    : Label       = $Popup/Label

var fuse_slots = []
var fuse_states : Array[int] = []
var selected_index : int = 0
var broken_remaining : int = 0
var in_window : bool = false
var state : GameState = GameState.INTRO

func _ready() -> void:
	randomize()

	# collect slots
	fuse_slots = grid.get_children()

	# set up states
	fuse_states.resize(GRID_SIZE)
	for i in range(GRID_SIZE):
		fuse_states[i] = FuseState.GOOD

	# choose 2–4 unique broken fuses
	var num_broken = randi_range(MIN_BROKEN, MAX_BROKEN)
	var indices := []
	for i in range(GRID_SIZE):
		indices.append(i)
	indices.shuffle()
	for i in range(num_broken):
		fuse_states[indices[i]] = FuseState.BROKEN
	broken_remaining = num_broken

	_update_title()
	_update_selection()

	fuse_window.visible = false
	fuse_sprite.visible = false

	# intro popup
	popup.visible = true
	popup_label.text = "Use the D-Pad to search the Fuses,\n" \
		+ "and then replace the broken ones.\n\n" \
		+ "Use the X Button to select/check a Fuse.\n" \
		+ "Use the X Button to replace the Fuse.\n" \
		+ "Use the A Button to exit."
	state = GameState.INTRO

func _process(_delta: float) -> void:
	match state:
		GameState.INTRO:
			_process_intro()
		GameState.PLAYING:
			if in_window:
				_process_window_input()
			else:
				_process_grid_input()

func _process_intro() -> void:
	# any face button or D-pad to continue
	if _any_start_button_pressed():
		popup.visible = false
		state = GameState.PLAYING

func _any_start_button_pressed() -> bool:
	return (
		Input.is_action_just_pressed("ui_accept") or  # X
		Input.is_action_just_pressed("ui_cancel") or  # A
		Input.is_action_just_pressed("ui_left") or
		Input.is_action_just_pressed("ui_right") or
		Input.is_action_just_pressed("ui_up") or
		Input.is_action_just_pressed("ui_down")
	)

func _process_grid_input() -> void:
	if Input.is_action_just_pressed("ui_left"):
		_move_selection(-1, 0)
	elif Input.is_action_just_pressed("ui_right"):
		_move_selection(1, 0)
	elif Input.is_action_just_pressed("ui_up"):
		_move_selection(0, -1)
	elif Input.is_action_just_pressed("ui_down"):
		_move_selection(0, 1)
	elif Input.is_action_just_pressed("ui_accept"):
		_open_fuse_window()

func _process_window_input() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_try_replace_fuse()
	elif Input.is_action_just_pressed("ui_cancel"):
		_close_fuse_window()

func _move_selection(dx: int, dy: int) -> void:
	var col := selected_index % GRID_COLS
	var row := selected_index / GRID_COLS

	col = clamp(col + dx, 0, GRID_COLS - 1)
	row = clamp(row + dy, 0, GRID_ROWS - 1)

	selected_index = row * GRID_COLS + col
	_update_selection()

func _update_selection() -> void:
	var slot : Control = fuse_slots[selected_index]
	selection_rect.global_position = slot.global_position - Vector2(4, 4)
	selection_rect.size = slot.size + Vector2(8, 8)

func _open_fuse_window() -> void:
	in_window = true
	fuse_window.visible = true
	fuse_sprite.visible = true

	var state_local := fuse_states[selected_index]
	if state_local == FuseState.BROKEN:
		fuse_sprite.texture = broken_fuse
	else:
		fuse_sprite.texture = good_fuse

func _close_fuse_window() -> void:
	in_window = false
	fuse_window.visible = false
	fuse_sprite.visible = false 

func _try_replace_fuse() -> void:
	if fuse_states[selected_index] == FuseState.BROKEN:
		fuse_states[selected_index] = FuseState.GOOD
		fuse_sprite.texture = good_fuse
		broken_remaining -= 1
		_update_title()

		if broken_remaining <= 0:
			_on_puzzle_complete()

func _update_title() -> void:
	title_label.text = "Find the dead fuses! (%d)" % broken_remaining

func _on_puzzle_complete() -> void:
	# TODO: connect with main game
	get_tree().quit() # replace with scene change later
