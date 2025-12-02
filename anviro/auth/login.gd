extends HSplitContainer

const dashboard_scene = "res://scene/dashboard/dashboard.tscn"

# Speicher-Konstanten
const SAVE_PATH = "user://user_profile.save" 
const ENC_KEY = "DeinGeheimesPasswortHier" # Unbedingt ändern!

@onready var email: LineEdit = $authlogin/Email
@onready var passwort: LineEdit = $authlogin/Passwort
@onready var hold_login: CheckBox = $authlogin/HoldLogin

func _ready() -> void:
	if not ApiAuth.login_completed.is_connected(_on_login_completed):
		ApiAuth.login_completed.connect(_on_login_completed)

func _on_login_pressed() -> void:
	var email_text := email.text.strip_edges()
	var pw_text := passwort.text
	var hold := hold_login.button_pressed

	if email_text == "" or pw_text == "":
		print("Bitte E-Mail und Passwort eingeben.")
		return

	ApiAuth.login_user(email_text, pw_text, hold)

func _on_login_completed(success: bool, message: String, user_id: int, token: String) -> void:
	if success:
		print("LOGIN ERFOLGREICH: ", message)
		
		# 1. Wir holen uns den aktuellen Status der "Angemeldet bleiben" Checkbox
		var is_hold_active = hold_login.button_pressed
		
		# 2. Wir speichern ID, Token und Hold-Status verschlüsselt
		save_encrypted_user_data(user_id, token, is_hold_active)
		
		ChangeScene.switch_scene(dashboard_scene, false)
	else:
		print("LOGIN FEHLGESCHLAGEN: ", message)
		# Optional: $authlogin/FehlerLabel.text = message

# --- Speicher-Funktion ---
func save_encrypted_user_data(uid: int, token: String, hold: bool) -> void:
	# Dictionary mit genau den geforderten Daten
	var user_data = {
		"user_id": uid,
		"token": token,
		"hold": hold
	}
	
	var json_string = JSON.stringify(user_data)
	
	# Datei mit Verschlüsselung öffnen (Godot 4.x / 4.5 Syntax)
	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, ENC_KEY)
	
	if file == null:
		printerr("Fehler beim Speichern der User-Daten: ", FileAccess.get_open_error())
		return
	
	file.store_string(json_string)
	file.close() # Datei schließen
	print("User-Daten (ID, Token, Hold) sicher gespeichert.")
