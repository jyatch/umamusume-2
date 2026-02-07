extends Node3D

@export var knight: Skeleton3D
@export var honse: Skeleton3D
@export var kAnims: AnimationPlayer
@export var hAnims: AnimationPlayer

func _ready():
	print("Umamusume!")
	#knight.get_child(1).physical_bones_start_simulation()
	#honse.get_child(1).physical_bones_start_simulation()


func playFastHorse():
	kAnims.play_section("ArmatureAction", 2.5,3.9)
	hAnims.play_section("Armature|ArmatureAction", 2.5,3.9)
	
func playSlowHorse():
	hAnims.play_section("Armature|ArmatureAction", 0.3,2.2)
	if(kAnims.current_animation_position > 2.5):
		kAnims.play_section_backwards("ArmatureAction", 2.5,3.9)
	
func playIdleHorse():
	hAnims.seek(0)
	hAnims.stop()
	kAnims.stop()
	
func playDeadHorse():
	hAnims.play_section("Armature|ArmatureAction",10.2,11.2)
