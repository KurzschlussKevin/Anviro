extends Control
class_name MainTemplate

# Pfade für Navigation
const SCENE_DASHBOARD = "res://scene/dashboard/dashboard.tscn"
const SCENE_KUNDEN = "res://scene/kunden/kundenverwaltung.tscn"
const SCENE_MITARBEITER = "res://scene/mitarbeiter/mitarbeiterverwaltung.tscn"
const SCENE_VERTRIEB = "res://scene/vertrieb/vertiebsbereich.tscn"
const SCENE_LOGIN = "res://auth/auth_controlling.tscn"

# UI Elemente aus dem Template
@onready var panel_user_infos: Panel = $Personalinfos/UserInfos
@onready var btn_dashboard: Button = $SideBoard/VSplitContainer/MarginContainer/VBoxContainer/Dashboard
@onready var btn_kunden: Button = $SideBoard/VSplitContainer/MarginContainer/VBoxContainer/Kundenverwaltung
@onready var btn_mitarbeiter: Button = $SideBoard/VSplitContainer/MarginContainer/VBoxContainer/Mitarbeiterverwaltung
@onready var btn_vertrieb: Button = $SideBoard/VSplitContainer/MarginContainer/VBoxContainer/Vertriebsbereich

func _ready() -> void:
	# Navigation verbinden
	_setup_sidebar_navigation()
	
	# Logout Signal global verbinden, falls noch nicht geschehen
	if not ApiAuth.logout_completed.is_connected(_on_logout_completed):
		ApiAuth.logout_completed.connect(_on_logout_completed)

# --- Navigation ---
func _setup_sidebar_navigation() -> void:
	btn_dashboard.pressed.connect(func(): ChangeScene.switch_scene(SCENE_DASHBOARD))
	btn_kunden.pressed.connect(func(): ChangeScene.switch_scene(SCENE_KUNDEN))
	btn_mitarbeiter.pressed.connect(func(): ChangeScene.switch_scene(SCENE_MITARBEITER))
	btn_vertrieb.pressed.connect(func(): ChangeScene.switch_scene(SCENE_VERTRIEB))

# --- Logout Logik (für alle Seiten gleich) ---
func _on_personalinfos_pressed() -> void:
	panel_user_infos.visible = !panel_user_infos.visible

func _on_close_pressed() -> void:
	panel_user_infos.visible = false

func _on_log_out_pressed() -> void:
	# Versuche Token aus Datei zu lesen für Logout
	# (Vereinfacht, besser wäre Token im Singleton zu halten)
	ApiAuth.logout_user("") 
	_do_local_logout()

func _on_logout_completed(_success):
	pass

func _do_local_logout() -> void:
	if FileAccess.file_exists("user://user_profile.save"):
		DirAccess.remove_absolute("user://user_profile.save")
	ChangeScene.switch_scene(SCENE_LOGIN)
