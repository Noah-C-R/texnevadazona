class_name Synchronizer

extends Node

static var I : Synchronizer

@export var zero_volume = -40
@export var bar_length = 1.739

var time : float
var bar_count : int

@export var driving_building : AudioStream
@export var driving_peak : AudioStream
@export var monster_bass : AudioStream
@export var monster_build : AudioStream

@export var players : Array[AudioStreamPlayer]

var await_bars : Dictionary[Callable, int]

class PlayStatus:
	signal stream_begin
	signal stream_end

func _init():
	I = self

func _ready() -> void:
	play(players[0], driving_peak, "Music", 1, 5)
	await play(players[1], monster_bass, "Music", 16, 10).stream_begin
	create_tween().tween_property(players[0], "volume_db", -10, 10)
	
	play(players[1], monster_build, "Music", 32)
	
##[player : AudioStreamPlayer] the stream to play the sound on
##[stream : AudioStream] the sound to play
##[bus := ""] what bus should this sound be played on. If left empty it will default to master
##[bar := 0] what bar to synchronize to. If left empty, it will be played immediatly
##[fade_in := 0.0] how long should it take for the sound to reach max volume after beginning
##[volume := 0.0] what volume, offseted from the stream's default volume, should it be played at 
func play(player : AudioStreamPlayer, stream : AudioStream, bus := "", bar := 0, fade_in := 0.0, volume := 0):
	var play_status = PlayStatus.new()
	
	if bar != 0:
		await_bar(bar, func(): 
			start_stream(player, stream, bus, fade_in, volume)
			play_status.stream_begin.emit()
			player.finished.connect(func(): play_status.stream_end.emit())
			)
		return play_status
	
	start_stream(player, stream, bus, fade_in, volume)
	player.finished.connect(func(): play_status.stream_end.emit())
	return play_status

func start_stream(player : AudioStreamPlayer, stream : AudioStream, bus : String, fade_in : float, volume : float):
	player.stream = stream
	player.bus = bus
	
	player.play()
	if fade_in != 0:
		create_tween().tween_method(func(vol): player.volume_db = vol, zero_volume, volume, fade_in)
	else:
		player.volume_db = volume

func await_bar(bar : int, function):
	await_bars[function] = bar

func _process(delta: float) -> void:
	time += delta
	if fmod(time, bar_length) <= delta:
		bar_count += 1
		
		for function in await_bars:
			var bar_queue = await_bars[function]
			if bar_count % bar_queue == 0:
				prints("CALL BAR", bar_queue)
				function.call()
				await_bars.erase(function)
