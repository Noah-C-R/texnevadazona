extends Control

const MIN_HITS := 10
const MAX_HITS := 20
@onready var title_label    : Label = $TitleLabel

const NOTE_TYPES := [
	{ "action": "MiniGame_Left",  		"label": "←" },
	{ "action": "MiniGame_Right", 		"label": "→" },
	{ "action": "MiniGame_Up",    		"label": "↑" },
	{ "action": "MiniGame_Down",  		"label": "↓" },
	#{ "action": "ui_cancel",		"label": "A" },
	#{ "action": "ui_b",     		"label": "B" },
	#{ "action": "ui_accept",		"label": "X" },
	#{ "action": "ui_select",		"label": "Y" },
	#{ "action": "Car_Break",	    "label": "LT" },
	#{ "action": "Car_Accelerate",   "label": "RT" },
]

@onready var lane : Control = $Lane

var hits_needed : int = 0
var hits : int = 0
var hits_remaining : int = 0
var active_notes : Array = []
var spawn_timer : float = 0.0
var spawn_interval : float = 0.7
var note_speed : float = 150.0

var screen_height : float = 0.0

func _ready() -> void:
	randomize()
	hits_needed = randi_range(MIN_HITS, MAX_HITS)
	screen_height = get_viewport_rect().size.y
	hits_remaining = hits_needed
	print(hits_needed)
	print(hits_remaining)
	
func _process(delta: float) -> void:
	# 1) spawn notes until we have enough potential notes
	if hits < hits_needed:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			_spawn_note()

	# 2) move existing notes down
	_move_notes(delta)

	# 3) check input against the FIRST note in the queue
	_check_input()

func _spawn_note() -> void:
	var note_type = NOTE_TYPES[randi() % NOTE_TYPES.size()]

	var lbl := Label.new()
	lbl.text = note_type["label"]
	lbl.add_theme_font_size_override("font_size", 32)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# start near top of lane, centered horizontally
	var start_pos = Vector2()
	start_pos.x = lane.size.x * 0.5 - 16.0
	start_pos.y = 0.0

	lane.add_child(lbl)
	lbl.position = start_pos
	lbl.set_meta("action", note_type["action"])

	active_notes.append(lbl)

func _move_notes(delta: float) -> void:
	# iterate over a copy so we can safely remove
	for lbl in active_notes.duplicate():
		lbl.position.y += note_speed * delta

		# if it falls off-screen, just remove it (miss)
		if lbl.global_position.y > screen_height:
			active_notes.erase(lbl)
			lbl.queue_free()

func _check_input() -> void:
	if active_notes.is_empty():
		return

	var current_lbl : Label = active_notes[0]
	var needed_action : String = current_lbl.get_meta("action")

	# see if the matching action was just pressed
	if Input.is_action_just_pressed(needed_action):
		_on_correct_hit(current_lbl)

func _on_correct_hit(lbl: Label) -> void:
	hits += 1

	# fade out and remove this note
	lbl.modulate = Color(1, 1, 1, 0.2)
	active_notes.erase(lbl)
	lbl.queue_free()
	_update_title()
	hits_remaining -= 1
	
	if hits >= hits_needed:
		_on_puzzle_complete()

func _on_puzzle_complete() -> void:
	# TODO: replace with return to car scene
	get_tree().quit()
	
func _update_title() -> void:
	title_label.text = "Tighten the clamp! (%d)" % hits_remaining
