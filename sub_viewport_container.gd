extends SubViewportContainer


var player_model: Node3D


func _ready() -> void:
	player_model = $"SubViewport/honse jouster"


func _process(delta: float) -> void:
	player_model.rotate(Vector3.UP, 0.0174533)
