@tool
extends CheckButton
var is_export:int
var base_text

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on:
		is_export = 1
	else :
		is_export = 0
