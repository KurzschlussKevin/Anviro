extends Control



func _on_personalinfos_pressed() -> void:
	$Personalinfos/UserInfos.visible = true


func _on_close_pressed() -> void:
	$Personalinfos/UserInfos.visible = false


func _on_log_out_pressed() -> void:
	pass # Replace with function body.
