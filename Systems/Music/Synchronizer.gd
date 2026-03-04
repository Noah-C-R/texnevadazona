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

class ScheduledBar:
	var loop := false
	var looped := false
	var loop_bar := 1
	var bar : int
	var fun : Callable

var scheduled_bars : Array[ScheduledBar]

class PlayStatus:
	signal stream_begin
	signal stream_end
	var schedualed_bar : ScheduledBar

class StopStatus:
	signal stop_begin
	signal stop_finish

func _init():
	I = self

func is_player_free(index : int):
	if index < 0 || index >= players.size():
		print("Invalid player index")
	return !players[index].playing

func play_player(index : int, stream : AudioStream, bus := "", bar := 0, fade_in := 0.0, volume := 0, loop := false, loop_bar := 0):
	if index < 0 || index >= players.size():
		print("Invalid player index")
		return
	
	print("LB", loop_bar)
	return play(players[index], stream, bus, bar, fade_in, volume, loop, loop_bar)

##[player : AudioStreamPlayer] the stream to play the sound on
##[stream : AudioStream] the sound to play
##[bus := ""] what bus should this sound be played on. If left empty it will default to master
##[bar := 0] what bar to synchronize to. If left empty, it will be played immediatly
##[fade_in := 0.0] how long should it take for the sound to reach max volume after beginning
##[volume := 0.0] what volume, offseted from the stream's default volume, should it be played at 
func play(player : AudioStreamPlayer, stream : AudioStream, bus := "", bar := 0, fade_in := 0.0, volume := 0, loop := false, loop_bar := 1):
	var play_status = PlayStatus.new()
	
	print("LB", loop_bar)
	if bar != 0:
		play_status.schedualed_bar = schedule_bar(bar, func(looped):
			if looped:
				fade_in = 0
			start_stream(player, stream, bus, fade_in, volume)
			play_status.stream_begin.emit()
			player.finished.connect(func(): play_status.stream_end.emit(), Node.CONNECT_ONE_SHOT)
			, loop, loop_bar)
		return play_status
	else:
		start_stream(player, stream, bus, fade_in, volume)
		player.finished.connect(func(): play_status.stream_end.emit(), Node.CONNECT_ONE_SHOT)
		return play_status

func start_stream(player : AudioStreamPlayer, stream : AudioStream, bus : String, fade_in : float, volume : float):
	player.stream = stream
	player.bus = bus
	
	player.play()
	if fade_in != 0:
		create_tween().tween_method(func(vol): 
			player.volume_db = vol
			, zero_volume, volume, fade_in)
	else:
		player.volume_db = volume

func stop_player(index : int, fade_out := 0, bar := 0):
	if index < 0 || index >= players.size():
		print("Invalid player index")
		return
	
	return stop(players[index], fade_out, bar)

func stop(player : AudioStreamPlayer, fade_out := 0, bar := 0):
	var stop_status = StopStatus.new()
	
	if bar != 0:
		schedule_bar(bar, func(looped): 
			stop_status.stop_begin.emit()
			stop_stream(player, stop_status, fade_out)
			, false)
		return stop_status
	
	stop_stream(player, stop_status, fade_out)
	return stop_status

func stop_stream(player : AudioStreamPlayer, stop_status : StopStatus, fade_out := 0):
	if fade_out == 0:
		player.volume_db = -40
		return
	
	var tween = create_tween().tween_property(player, "volume_db", -40, fade_out)
	tween.finished.connect(func(): 
		player.stop()
		stop_status.stop_finish.emit()
		, Node.CONNECT_ONE_SHOT)

func schedule_bar(bar : int, function, loop := false, loop_bar := 1):
	var scheduled = ScheduledBar.new()
	scheduled.bar = bar
	scheduled.fun = function
	scheduled.loop = loop
	scheduled.loop_bar = loop_bar
	
	scheduled_bars.append(scheduled)
	return scheduled

func _process(delta: float) -> void:
	time += delta
	if fmod(time, bar_length) <= delta:
		bar_count += 1

		for scheduled_bar in scheduled_bars:
			if bar_count % scheduled_bar.bar == 0:
				print(scheduled_bar.bar, scheduled_bar.loop)
				
				if !scheduled_bar.loop:
					scheduled_bar.fun.call(false)
					scheduled_bar.looped = false
					scheduled_bar.loop = false
					scheduled_bars.erase(scheduled_bar)
					
				elif !scheduled_bar.looped:
					scheduled_bar.fun.call(scheduled_bar.looped)
					scheduled_bar.looped = true
					print("SET LOOPED")
			
			if scheduled_bar.looped:
				if bar_count % scheduled_bar.loop_bar == 0:
					print("LOOP")
					scheduled_bar.fun.call(scheduled_bar.looped)
				
