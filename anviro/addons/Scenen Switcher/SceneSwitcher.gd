extends Node
class_name SceneSwitcher

# Diese Variable ist im "Sofort"-Modus nicht mehr nötig, aber wir lassen die Signatur
# der Funktion gleich, damit du deinen anderen Code nicht ändern musst.

func _ready() -> void:
	# Wir brauchen hier kein Setup mehr für Fades
	pass

func switch_scene(path: String, _with_fade := false) -> void:
	# 1. Sicherheitscheck: Existiert die Szene überhaupt?
	if not ResourceLoader.exists(path):
		printerr("SceneSwitcher: FEHLER! Szene nicht gefunden: ", path)
		return

	# 2. Der eigentliche Wechsel
	# "call_deferred" ist der Trick gegen Flackern und Abstürze.
	# Es sagt Godot: "Mach erst alles fertig, was du gerade tust (Rendering),
	# und DANN wechsle die Szene."
	get_tree().call_deferred("change_scene_to_file", path)
	
	print("SceneSwitcher: Wechsle zu -> ", path)
