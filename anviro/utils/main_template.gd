extends Control
class_name MainTemplate

# --- KONSTANTEN ---
const SAVE_PATH = "user://user_profile.save"
const ENC_KEY = "DeinGeheimesPasswortHier" 

# Pfade für Navigation
const SCENE_DASHBOARD = "res://scene/dashboard/dashboard.tscn"
const SCENE_KUNDEN = "res://scene/kunden/kundenverwaltung.tscn"
const SCENE_MITARBEITER = "res://scene/mitarbeiter/mitarbeiterverwaltung.tscn"
const SCENE_VERTRIEB = "res://scene/vertrieb/vertiebsbereich.tscn"
const SCENE_LOGIN = "res://auth/auth_controlling.tscn"

# --- UI NODES ---
@onready var label_username: Label = $Personalinfos/Username
@onready var label_rolle: Label = $Personalinfos/Rolle
@onready var panel_user_infos: Panel = $Personalinfos/UserInfos

# Sidebar Buttons
@onready var btn_dashboard: Button = $SideBoard/VSplitContainer/MarginContainer/VBoxContainer/Dashboard
@onready var btn_kunden: Button = $SideBoard/VSplitContainer/MarginContainer/VBoxContainer/Kundenverwaltung
@onready var btn_mitarbeiter: Button = $SideBoard/VSplitContainer/MarginContainer/VBoxContainer/Mitarbeiterverwaltung
@onready var btn_vertrieb: Button = $SideBoard/VSplitContainer/MarginContainer/VBoxContainer/Vertriebsbereich

var current_token: String = ""

func _ready() -> void:
	if not ApiAuth.logout_completed.is_connected(_on_logout_completed):
		ApiAuth.logout_completed.connect(_on_logout_completed)
	
	if not ApiAuth.user_data_received.is_connected(_on_user_data_received):
		ApiAuth.user_data_received.connect(_on_user_data_received)
	
	_setup_sidebar_navigation()
	_load_local_user_data()

# --- DATEN LADEN & SPEICHERN ---

func _load_local_user_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("Template: Keine User-Datei gefunden.")
		_do_local_logout()
		return

	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENC_KEY)
	if file == null:
		_do_local_logout()
		return

	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) == OK:
		var data = json.data
		current_token = data.get("token", "")
		
		# 1. SOFORT ANZEIGEN, was wir lokal haben (Für Offline Modus)
		var local_name = data.get("username", "")
		var local_role = int(data.get("role_id", 0))
		
		if local_name != "":
			label_username.text = local_name
			label_rolle.text = _get_role_name(local_role)
		
		# 2. Wenn Token da ist, versuchen wir ONLINE zu aktualisieren
		if current_token != "":
			ApiAuth.fetch_user_data(current_token)
		else:
			_do_local_logout()

func _on_user_data_received(success: bool, data: Dictionary) -> void:
	if success:
		# UI Update mit frischen Daten vom Server
		var new_name = str(data.get("username", "Gast"))
		var new_role_id = int(data.get("role_id", 0))
		
		label_username.text = new_name
		label_rolle.text = _get_role_name(new_role_id)
		
		# WICHTIG: Die neuen Daten jetzt lokal speichern für den nächsten Offline-Start!
		_update_local_save_file(new_name, new_role_id)
		
	else:
		print("Session Check fehlgeschlagen (vielleicht offline?), behalte alte Daten.")
		# Wir loggen hier NICHT aus, damit der Offline-Modus weitergeht

func _update_local_save_file(username: String, role_id: int) -> void:
	# Wir lesen erst alles, um Token/Hold nicht zu verlieren
	if not FileAccess.file_exists(SAVE_PATH): return
	
	var file_read = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENC_KEY)
	if file_read == null: return
	
	var json = JSON.new()
	var parse_err = json.parse(file_read.get_as_text())
	file_read.close() # Wichtig: Schließen bevor wir schreiben
	
	if parse_err == OK:
		var data = json.data
		# Neue Daten hinzufügen
		data["username"] = username
		data["role_id"] = role_id
		
		# Wieder speichern
		var file_write = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, ENC_KEY)
		if file_write:
			file_write.store_string(JSON.stringify(data))

# --- Helper ---
func _get_role_name(id: int) -> String:
	match id:
		1: return "Leser"
		2: return "Prüfer"
		3: return "Teamleiter"
		4: return "BackOffice"
		5: return "Administrator"
		_: return "Rolle: " + str(id)

# --- Navigation & Logout (Unverändert) ---
func _setup_sidebar_navigation() -> void:
	btn_dashboard.pressed.connect(func(): ChangeScene.switch_scene(SCENE_DASHBOARD))
	btn_kunden.pressed.connect(func(): ChangeScene.switch_scene(SCENE_KUNDEN))
	btn_mitarbeiter.pressed.connect(func(): ChangeScene.switch_scene(SCENE_MITARBEITER))
	btn_vertrieb.pressed.connect(func(): ChangeScene.switch_scene(SCENE_VERTRIEB))

func _on_personalinfos_pressed() -> void:
	panel_user_infos.visible = !panel_user_infos.visible

func _on_close_pressed() -> void:
	panel_user_infos.visible = false

func _on_log_out_pressed() -> void:
	if current_token != "":
		ApiAuth.logout_user(current_token)
	_do_local_logout()

func _on_logout_completed(_success):
	pass

func _do_local_logout() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	ChangeScene.switch_scene(SCENE_LOGIN)
