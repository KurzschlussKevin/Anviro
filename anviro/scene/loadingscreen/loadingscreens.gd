extends Control

# --- KONFIGURATION ---
const SERVER_URL = "http://127.0.0.1:8000/health"
const TIMEOUT_SECONDS = 5.0

# Szenen-Pfade
const LOGIN_SCENE = "res://auth/auth_controlling.tscn"
const DASHBOARD_SCENE = "res://scene/dashboard/dashboard.tscn"

# Speicher-Daten (Müssen EXAKT mit deinem Login-Script übereinstimmen!)
const SAVE_PATH = "user://user_profile.save"
const ENC_KEY = "DeinGeheimesPasswortHier" # <-- WICHTIG: Das gleiche Passwort wie beim Speichern nutzen!

# --- NODES ---
@onready var loadinginfo: Label = $loadinginfo
@onready var loadingbar: ProgressBar = $Loadingbar

var http_request: HTTPRequest
var timeout_timer: Timer
var check_completed: bool = false # Verhindert, dass Timer und HTTP gleichzeitig feuern

func _ready() -> void:
	# UI Reset
	loadinginfo.text = "Verbinde zum Server..."
	loadinginfo.modulate = Color.WHITE
	loadingbar.value = 10
	
	# HTTP Request erstellen
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_server_check_completed)
	
	# Timeout Timer erstellen
	timeout_timer = Timer.new()
	timeout_timer.wait_time = TIMEOUT_SECONDS
	timeout_timer.one_shot = true
	timeout_timer.timeout.connect(_on_timeout)
	add_child(timeout_timer)
	
	# Starten
	check_server_connection()

func check_server_connection() -> void:
	print("DEBUG: Starte Verbindungsversuch...")
	timeout_timer.start() # Timer läuft los (5 Sek)
	var error = http_request.request(SERVER_URL)
	
	if error != OK:
		# Falls Hardware-Fehler sofort abbrechen
		_handle_connection_result(false)

# --- EVENT: Server antwortet (bevor die 5 Sek um sind) ---
func _on_server_check_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if check_completed: return # Falls Timer schon zugeschlagen hat -> ignorieren
	
	timeout_timer.stop() # Timer stoppen
	
	var is_online = (result == HTTPRequest.RESULT_SUCCESS and response_code == 200)
	
	if is_online:
		print("DEBUG: Server ist ONLINE.")
		_handle_connection_result(true)
	else:
		print("DEBUG: Server antwortet nicht korrekt (Code: ", response_code, ")")
		_handle_connection_result(false)

# --- EVENT: 5 Sekunden sind um (Server hat nicht geantwortet) ---
func _on_timeout() -> void:
	if check_completed: return
	
	print("DEBUG: Timeout! Keine Antwort nach 5 Sekunden.")
	http_request.cancel_request() # Laufenden Request abbrechen
	_handle_connection_result(false) # Wir behandeln das als "Offline"

# --- HAUPTLOGIK: Entscheiden, wohin es geht ---
func _handle_connection_result(is_online: bool) -> void:
	check_completed = true # Markieren, dass wir fertig sind
	
	# Wir prüfen JETZT die Speicherdatei
	var saved_data = load_encrypted_hold_status()
	var has_save_file = saved_data["exists"]
	var hold_active = saved_data["hold"]
	
	loadingbar.value = 100
	
	if is_online:
		# --- FALL: ONLINE ---
		loadinginfo.text = "Verbunden!"
		await get_tree().create_timer(0.5).timeout
		
		if has_save_file and hold_active:
			print("ONLINE & HOLD ACTIVE -> Gehe zum Dashboard (Auto-Login)")
			# Hier könntest du theoretisch den Token noch schnell beim Server validieren
			ChangeScene.switch_scene(DASHBOARD_SCENE, false)
		else:
			print("ONLINE & KEIN HOLD -> Gehe zum Login")
			ChangeScene.switch_scene(LOGIN_SCENE, false)
			
	else:
		# --- FALL: OFFLINE (oder Timeout) ---
		if has_save_file and hold_active:
			loadinginfo.text = "Offline Modus..."
			await get_tree().create_timer(1.0).timeout
			print("OFFLINE & HOLD ACTIVE -> Gehe zum Dashboard (Offline-Modus)")
			ChangeScene.switch_scene(DASHBOARD_SCENE, false)
		else:
			# Offline und kein Auto-Login -> Fehlermeldung anzeigen und BLEIBEN
			print("OFFLINE & KEIN HOLD -> Fehler anzeigen")
			_show_offline_message("Verbindungsfehler (Offline)")

# --- HILFSFUNKTION: Liest die Datei aus ---
func load_encrypted_hold_status() -> Dictionary:
	# Standard-Rückgabe, falls nichts da ist
	var result = {"exists": false, "hold": false}
	
	if not FileAccess.file_exists(SAVE_PATH):
		return result
		
	# Datei verschlüsselt öffnen
	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENC_KEY)
	if file == null:
		printerr("Fehler beim Lesen der verschlüsselten Datei (Passwort falsch?)")
		return result
		
	var content = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(content)
	
	if error == OK:
		var data = json.data
		# Prüfen ob "hold" im JSON true ist
		if data.has("hold") and data["hold"] == true:
			result["exists"] = true
			result["hold"] = true
		elif data.has("hold") and data["hold"] == false:
			result["exists"] = true
			result["hold"] = false
			
	return result

func _show_offline_message(msg: String) -> void:
	loadinginfo.text = msg
	loadinginfo.modulate = Color.RED
	loadingbar.value = 0
	# Optional: Button einblenden zum erneuten Versuchen
