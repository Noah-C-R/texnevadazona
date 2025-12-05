extends Level

var state_m : StateMachine

@export var zone_0 : Marker3D
@export var zone_1 : Marker3D
@export var zone_2 : Marker3D

@export var crickets_ambient : AudioStream
@export var driving_build_music : AudioStream
@export var driving_full_music : AudioStream
@export var monster_beat : AudioStream
@export var monster_build : AudioStream

func on_load():
	print("START")
	if state_m: state_m.queue_free()
	
	state_m = StateMachine.create(self)
	state_m.add_state("Zone 0", zone_0_enter, null, zone_0_phys)
	state_m.add_state("Zone 1", zone_1_enter, null, zone_1_phys)
	state_m.add_state("Zone 2", zone_2_enter, null, zone_2_phys)
	
	state_m.transfer("Zone 0")

func zone_0_enter():
	
	Synchronizer.I.play_player(0, crickets_ambient, "Ambient", 0, 5, -20)
	Synchronizer.I.play_player(1, driving_build_music, "Music", 8, 10, -10)

func zone_0_phys(_delta : float):
	if Car.I.global_position.distance_to(zone_1.global_position) < 50:
		state_m.transfer("Zone 1")

var zone_1_monster_play_status
func zone_1_enter():
	print("ENTER ZONE 1")
	Synchronizer.I.stop_player(1, 10)
	Synchronizer.I.play_player(3, monster_beat, "Music", 1, 15, 0)

	zone_1_monster_play_status = Synchronizer.I.play_player(3, monster_beat, "Music", 1, 15, true)
	
	
func zone_1_phys(_delta : float):
	if Car.I.global_position.distance_to(zone_2.global_position) < 50:
		zone_1_monster_play_status.schedualed_bar.loop = false
		state_m.transfer("Zone 2")

func zone_2_enter():
	print("ZONE 2!!++++++++++++++++++")
	Synchronizer.I.stop_player(3, 2, 1)
	Synchronizer.I.play_player(4, monster_build, "Music", 1, 0)
	GameManager.I.set_warp_low_color(Color.BLACK)
	
func zone_2_phys(_delta : float):
	pass
