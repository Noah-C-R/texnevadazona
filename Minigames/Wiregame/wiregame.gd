extends Control

@onready var selection_rect : ColorRect = $Selection
@onready var wire_layer     : Control   = $Harness/WireLayer
@onready var popup          : Control   = $Popup
@onready var popup_label    : Label     = $Popup/Label

var carrying_bottom_index : int = -1

const COLORS = [
	{name = "red",   col = Color(1, 0, 0)},
	{name = "blue",  col = Color(0, 0.5, 1)},
	{name = "yellow", col = Color(1, 0.9, 0)},
	{name = "white", col = Color(1, 1, 1)},
	{name = "black", col = Color(0.05, 0.05, 0.05)}
]

var num_wires : int
var bottom_colors : Array
var top_colors : Array

var bottom_slots = []
var top_slots = []

var selecting_bottom := true
var bottom_index := 0
var top_index := 0
var carrying_color : Variant = null
var solved := 0

enum GameState { INTRO, PLAYING }
var state : GameState = GameState.INTRO

func _ready() -> void:
	randomize()
	bottom_slots = $Harness/BottomSlots.get_children() as Array[ColorRect]
	top_slots    = $Harness/TopSlots.get_children()    as Array[ColorRect]
	_start_puzzle()

	# intro popup text (from your screenshot)
	popup.visible = true
	popup_label.text = "Use the D-Pad to select the wire,\n" \
		+ "and then replace the wire in the\n" \
		+ "corresponding wire harness hole.\n\n" \
		+ "Use the X Button to select the wire,\n" \
		+ "and the A Button to cancel."
	state = GameState.INTRO

func _start_puzzle() -> void:
	num_wires = randi_range(3, 5)

	var pool = COLORS.duplicate()
	pool.shuffle()
	bottom_colors = pool.slice(0, num_wires)
	top_colors = bottom_colors.duplicate()
	top_colors.shuffle()

	for i in range(bottom_slots.size()):
		var visible = i < num_wires
		bottom_slots[i].visible = visible
		top_slots[i].visible    = visible
		if visible:
			bottom_slots[i].color = bottom_colors[i].col
			top_slots[i].color    = top_colors[i].col
			top_slots[i].set_meta("correct_name", top_colors[i].name)
			top_slots[i].set_meta("filled", false)

	selecting_bottom = true
	bottom_index = 0
	top_index = 0
	carrying_color = null
	solved = 0
	_update_highlight()

func _process(_delta: float) -> void:
	match state:
		GameState.INTRO:
			_process_intro()
		GameState.PLAYING:
			_process_playing()

func _process_intro() -> void:
	if _any_start_button_pressed():
		popup.visible = false
		state = GameState.PLAYING

func _any_start_button_pressed() -> bool:
	return (
		Input.is_action_just_pressed("ui_accept") or  # X
		Input.is_action_just_pressed("ui_cancel") or  # A
		Input.is_action_just_pressed("ui_left")   or
		Input.is_action_just_pressed("ui_right")  or
		Input.is_action_just_pressed("ui_up")     or
		Input.is_action_just_pressed("ui_down")
	)

func _process_playing() -> void:
	if Input.is_action_just_pressed("ui_left"):
		_move_selection(-1)
	elif Input.is_action_just_pressed("ui_right"):
		_move_selection(1)

	elif Input.is_action_just_pressed("ui_accept"):
		if selecting_bottom:
			_pick_wire()
		elif carrying_color != null:
			_place_wire()

	elif Input.is_action_just_pressed("ui_cancel"):
		if not selecting_bottom:
			selecting_bottom = true
			carrying_color = null
			_update_highlight()

func _move_selection(dir: int) -> void:
	if selecting_bottom:
		bottom_index = clamp(bottom_index + dir, 0, num_wires - 1)
	else:
		top_index = clamp(top_index + dir, 0, num_wires - 1)
	_update_highlight()

func _pick_wire() -> void:
	carrying_color = bottom_colors[bottom_index]
	carrying_bottom_index = bottom_index
	selecting_bottom = false
	top_index = 0
	_update_highlight()

func _place_wire() -> void:
	var slot = top_slots[top_index]
	if slot.get_meta("filled"):
		return

	var correct_name : String = slot.get_meta("correct_name")
	if carrying_color.name == correct_name:
		slot.set_meta("filled", true)
		_draw_wire(carrying_bottom_index, top_index, carrying_color.col)
		solved += 1
		if solved == num_wires:
			_on_puzzle_complete()
	else:
		var original_color : Color = top_colors[top_index].col
		slot.color = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		slot.color = original_color

	selecting_bottom = true
	carrying_color = null
	_update_highlight()

func _draw_wire(bottom_i: int, top_i: int, color: Color) -> void:
	var top_slot    : ColorRect = top_slots[top_i]
	var bottom_slot : ColorRect = bottom_slots[bottom_i]

	var line := Line2D.new()
	line.default_color = color
	line.width = 6.0
	wire_layer.add_child(line)

	var top_center    = top_slot.global_position + top_slot.size * 0.5
	var bottom_center = bottom_slot.global_position + bottom_slot.size * 0.5

	top_center    -= wire_layer.global_position
	bottom_center -= wire_layer.global_position

	line.points = PackedVector2Array([top_center, bottom_center])

func _update_highlight() -> void:
	var slot : ColorRect = bottom_slots[bottom_index] if selecting_bottom else top_slots[top_index]

	selection_rect.visible = true
	selection_rect.global_position = slot.global_position - Vector2(4, 4)
	selection_rect.size = slot.size + Vector2(8, 8)

func _on_puzzle_complete() -> void:
	# TODO: replace with return to car scene
	get_tree().quit() 
