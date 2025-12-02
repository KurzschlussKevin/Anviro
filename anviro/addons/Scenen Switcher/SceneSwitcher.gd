extends Node
class_name SceneSwitcher

var fade_layer: CanvasLayer

func _ready():
	if not is_instance_valid(fade_layer):
		fade_layer = CanvasLayer.new()
		var color_rect = ColorRect.new()
		color_rect.name = "Fade"
		color_rect.color = Color.BLACK
		color_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		color_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		color_rect.modulate.a = 0.0
		fade_layer.add_child(color_rect)
		# Verzögert hinzufügen, um Setup-Konflikt zu vermeiden
		get_tree().root.call_deferred("add_child", fade_layer)
		fade_layer.visible = false


func switch_scene(path: String, with_fade := true) -> void:
	if not ResourceLoader.exists(path):
		return

	if with_fade:
		await _fade_out()

	# Szenewechsel deferred ausführen, damit der aktuelle Frame fertig wird
	get_tree().change_scene_to_file.bind(path).call_deferred()
	# Optional: einen Frame warten, damit die neue Szene Zeit zum Laden hat
	await RenderingServer.frame_post_draw

	if with_fade:
		await _fade_in()


func _fade_out() -> void:
	var fade = fade_layer.get_node("Fade")
	fade.modulate.a = 0.0
	fade_layer.visible = true
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.5)
	await tween.finished

func _fade_in() -> void:
	var fade = fade_layer.get_node("Fade")
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 0.5)
	await tween.finished
	fade_layer.visible = false
