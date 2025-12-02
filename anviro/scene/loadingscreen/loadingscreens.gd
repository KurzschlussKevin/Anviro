extends Control

# --- KONFIGURATION ---
const SERVER_URL_HEALTH = "http://127.0.0.1:8000/health"
const SERVER_URL_VALIDATE = "http://127.0.0.1:8000/users/me" # <-- NEU: Validierungs-URL
const TIMEOUT_SECONDS = 5.0

# Szenen-Pfade
const LOGIN_SCENE = "res://auth/auth_controlling.tscn" # Pfad angepasst an dein Projekt
const DASHBOARD_SCENE = "res://scene/dashboard/dashboard.tscn"

# Speicher-Daten
const SAVE_PATH = "user://user_profile.save"
const ENC_KEY = "DeinGeheimesPasswortHier" 

# --- NODES ---
@onready var loadinginfo: Label = $loadinginfo
@onready var loadingbar: ProgressBar = $Loadingbar

# Wir brauchen zwei Requests: Einen für Health, einen für Token-Check
var http_health: HTTPRequest
var http_validate: HTTPRequest
var timeout_timer: Timer
var check_completed: bool = false 

func _ready() -> void:
	loadinginfo.text = "Verbinde zum Server..."
	loadingbar.value = 10
	
	# 1. Health Request erstellen
	http_health = HTTPRequest.new()
	add_child(http_health)
	http_health.request_completed.connect(_on_health_check_completed)
	
	# 2. Validate Request erstellen (NEU)
	http_validate = HTTPRequest.new()
	add_child(http_validate)
	http_validate.request_completed.connect(_on_token_validation_completed)
	
	# Timer erstellen
	timeout_timer = Timer.new()
	timeout_timer.wait_time = TIMEOUT_SECONDS
	timeout_timer.one_shot = true
	timeout_timer.timeout.connect(_on_timeout)
	add_child(timeout_timer)
	
	start_check()

func start_check() -> void:
	timeout_timer.start()
	http_health.request(SERVER_URL_HEALTH)

# --- SCHRITT 1: Ist der Server überhaupt da? ---
func _on_health_check_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if check_completed: return
	timeout_timer.stop()
	
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		print("DEBUG: Server ist ONLINE.")
		_handle_connection_result(true)
	else:
		print("DEBUG: Server nicht erreichbar (Code: ", response_code, ")")
		_handle_connection_result(false)

func _on_timeout() -> void:
	if check_completed: return
	print("DEBUG: Timeout!")
	http_health.cancel_request()
	_handle_connection_result(false)

# --- SCHRITT 2: Entscheiden was wir tun ---
func _handle_connection_result(is_online: bool) -> void:
	check_completed = true
	loadingbar.value = 50
	
	# Daten lesen (jetzt mit Token!)
	var saved_data = load_encrypted_data()
	var has_file = saved_data["exists"]
	var hold_active = saved_data["hold"]
	var token = saved_data["token"]
	
	if is_online:
		loadinginfo.text = "Prüfe Benutzerdaten..."
		
		# WICHTIG: Hier ändern wir die Logik!
		if has_file and hold_active and token != "":
			# Statt direkt ins Dashboard zu gehen, prüfen wir das Token!
			validate_token_on_server(token)
		else:
			print("Online, aber kein Auto-Login -> Login Screen")
			ChangeScene.switch_scene(LOGIN_SCENE, false)
			
	else:
		# Offline Logik
		if has_file and hold_active:
			loadinginfo.text = "Offline Modus..."
			await get_tree().create_timer(1.0).timeout
			ChangeScene.switch_scene(DASHBOARD_SCENE, false)
		else:
			_show_offline_message("Verbindungsfehler (Offline)")

# --- SCHRITT 3: Token beim Server prüfen (NEU) ---
func validate_token_on_server(token: String) -> void:
	print("DEBUG: Validiere Token beim Backend...")
	var headers = ["Authorization: Bearer " + token]
	# Wir senden an /users/me
	http_validate.request(SERVER_URL_VALIDATE, headers, HTTPClient.METHOD_GET)

func _on_token_validation_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	loadingbar.value = 100
	
	# Wenn Server 200 sagt, ist is_active=True in der DB
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		print("DEBUG: Token gültig -> Dashboard")
		loadinginfo.text = "Willkommen zurück!"
		await get_tree().create_timer(0.5).timeout
		ChangeScene.switch_scene(DASHBOARD_SCENE, false)
	else:
		# Wenn Server 401 sagt (weil is_active=False), landen wir hier
		print("DEBUG: Token ungültig/gesperrt (Code: ", response_code, ") -> Login")
		loadinginfo.text = "Sitzung abgelaufen."
		
		# WICHTIG: Die ungültige Datei löschen, damit er nicht in einer Loop hängt
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(SAVE_PATH)
			
		await get_tree().create_timer(1.0).timeout
		ChangeScene.switch_scene(LOGIN_SCENE, false)

# --- Hilfsfunktionen ---
func load_encrypted_data() -> Dictionary:
	var result = {"exists": false, "hold": false, "token": ""}
	
	if not FileAccess.file_exists(SAVE_PATH):
		return result
		
	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENC_KEY)
	if file == null:
		return result
		
	var content = file.get_as_text()
	var json = JSON.new()
	if json.parse(content) == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY:
			result["exists"] = true
			result["hold"] = data.get("hold", false)
			result["token"] = data.get("token", "") # Token mit auslesen!
			
	return result

func _show_offline_message(msg: String) -> void:
	loadinginfo.text = msg
	loadinginfo.modulate = Color.RED
	loadingbar.value = 0
