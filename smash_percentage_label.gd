extends PanelContainer


var label: Label
var percent_symbol: String = "%"


func _ready() -> void:
	label = $Label


func update_label(percentage: float):
	percentage = snapped(percentage, 0.1)
	label.text = "SMASH: %s" % [percentage]
	label.text += percent_symbol
	
