extends Node3D

@export var knight: Skeleton3D
@export var honse: Skeleton3D

func _ready():
	knight.get_child(1).physical_bones_start_simulation()
	honse.get_child(1).physical_bones_start_simulation()
