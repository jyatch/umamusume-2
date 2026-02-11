extends Area3D


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("players"):
		return
		
	body.start_out_of_bounds_timer()


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("players"):
		return
		
	body.cancel_out_of_bounds_timer()
