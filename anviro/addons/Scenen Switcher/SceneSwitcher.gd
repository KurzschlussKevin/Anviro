extends Node
class_name SceneSwitcher

var fade_layer: CanvasLayer
var color_rect: ColorRect

func _ready():
	# Wir erstellen den Layer nur, wenn er noch nicht existiert
	if not is_instance_valid(fade_layer):
		fade_layer = CanvasLayer.new()
		# WICHTIG: Ein sehr hoher Layer-Wert sorgt dafür, dass das Schwarz ALLES überdeckt
		fade_layer.layer = 128 
		
		color_rect = ColorRect.new()
		color_rect.name = "Fade"
		color_rect.color = Color.BLACK
		# Nimmt den ganzen Bildschirm ein
		color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Klicks durchlassen wenn unsichtbar
		color_rect.modulate.a = 0.0
		
		fade_layer.add_child(color_rect)
		get_tree().root.call_deferred("add_child", fade_layer)

func switch_scene(path: String, with_fade := true) -> void:
	if not ResourceLoader.exists(path):
		return

	if with_fade:
		# Blockiere Maus-Inputs während des Übergangs
		color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		await _fade_out()

	# Wechselt die Szene
	get_tree().change_scene_to_file(path)
	
	# WICHTIG: Wir warten 2 Frames. 
	# 1. Frame: Godot instanziiert die Nodes
	# 2. Frame: Godot zeichnet die UI fertig
	await get_tree().process_frame
	await get_tree().process_frame

	if with_fade:
		await _fade_in()
		# Inputs wieder erlauben
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _fade_out() -> void:
	fade_layer.visible = true
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.3) # Etwas schneller (0.3s)
	await tween.finished

func _fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.3)
	await tween.finished
	fade_layer.visible = false
