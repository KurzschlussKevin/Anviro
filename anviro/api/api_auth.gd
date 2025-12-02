extends Node
class_name API

# Basis-URL deines FastAPI-Backends
const BASE_URL := "http://127.0.0.1:8000"

# Endpunkte
const ENDPOINT_REGISTER := "/register"
const ENDPOINT_LOGIN    := "/login"
const ENDPOINT_USER_ME  := "/users/me"
const ENDPOINT_LOGOUT   := "/logout"

# Pfad zum Speichern der Geräte-ID
const DEVICE_ID_FILE := "user://device.id"

# Signale
signal registration_completed(success: bool, message: String)
signal login_completed(success: bool, message: String, user_id: int, token: String)
signal user_data_received(success: bool, data: Dictionary)
signal logout_completed(success: bool)

var _http: HTTPRequest
var _current_endpoint: String = ""
var _busy: bool = false
var _device_id: String = ""


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	
	# Beim Start sofort die Geräte-ID laden oder neu erstellen
	_device_id = _get_or_create_device_id()
	print("API: Dieses Gerät hat die ID: ", _device_id)


# ==============================================================================
# 1. REGISTRIERUNG
# ==============================================================================

func register_user(user_data: Dictionary) -> void:
	if _busy:
		print("API: Anfrage läuft bereits, bitte warten.")
		return

	_busy = true
	_current_endpoint = ENDPOINT_REGISTER

	var url := BASE_URL + ENDPOINT_REGISTER
	var headers := ["Content-Type: application/json"]
	var body := JSON.stringify(user_data)

	print("API: Sende Registrierung an: ", url)

	var err := _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("API: HTTP-Anfragefehler (register) -> ", err)
		_busy = false
		registration_completed.emit(false, "Konnte Anfrage nicht senden.")


# ==============================================================================
# 2. LOGIN (MIT GERÄTE-ERKENNUNG)
# ==============================================================================

func login_user(email: String, passwort: String, hold_login: bool = false) -> void:
	if _busy:
		print("API: Anfrage läuft bereits, bitte warten.")
		return

	_busy = true
	_current_endpoint = ENDPOINT_LOGIN

	var url := BASE_URL + ENDPOINT_LOGIN
	var headers := ["Content-Type: application/json"]
	
	# Wir senden jetzt Geräte-Infos mit
	var body_data = {
		"email": email,
		"passwort": passwort,
		"hold_login": hold_login,
		"device_id": _device_id,           # Unsere feste UUID
		"device_name": _get_device_name(), # Z.B. "Mein PC"
		"platform": OS.get_name()          # Z.B. "Windows"
	}
	
	var body := JSON.stringify(body_data)

	print("API: Sende Login an: ", url, " mit DeviceID: ", _device_id)

	var err := _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("API: HTTP-Anfragefehler (login) -> ", err)
		_busy = false
		login_completed.emit(false, "Konnte Anfrage nicht senden.", 0, "")


# ==============================================================================
# 3. DASHBOARD FUNKTIONEN (NEU)
# ==============================================================================

func fetch_user_data(token: String) -> void:
	if _busy: return
	_busy = true
	_current_endpoint = ENDPOINT_USER_ME
	
	var url := BASE_URL + ENDPOINT_USER_ME
	var headers := ["Authorization: Bearer " + token]
	
	print("API: Hole User-Daten...")
	_http.request(url, headers, HTTPClient.METHOD_GET)


func logout_user(token: String) -> void:
	_busy = true # Kurz sperren, auch wenn wir das Ergebnis nicht zwingend brauchen
	_current_endpoint = ENDPOINT_LOGOUT
	
	var url := BASE_URL + ENDPOINT_LOGOUT
	var headers := ["Authorization: Bearer " + token]
	
	print("API: Sende Logout...")
	_http.request(url, headers, HTTPClient.METHOD_POST)


# ==============================================================================
# 4. HELPER: UUID & GERÄTE-INFOS
# ==============================================================================

func _get_or_create_device_id() -> String:
	# 1. Prüfen, ob wir schon eine ID haben
	if FileAccess.file_exists(DEVICE_ID_FILE):
		var file = FileAccess.open(DEVICE_ID_FILE, FileAccess.READ)
		var saved_id = file.get_as_text()
		if saved_id.length() > 10: 
			return saved_id
	
	# 2. Wenn nicht, generieren wir eine neue UUID v4
	var new_id = _generate_uuid_v4()
	
	# 3. Speichern für die Zukunft
	var file = FileAccess.open(DEVICE_ID_FILE, FileAccess.WRITE)
	file.store_string(new_id)
	file.close()
	
	return new_id

func _generate_uuid_v4() -> String:
	var crypto = Crypto.new()
	var b = crypto.generate_random_bytes(16)
	
	# Setze Version (4) und Variant (RFC 4122) Bits
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [
		b[0], b[1], b[2], b[3], b[4], b[5], b[6], b[7],
		b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]
	]

func _get_device_name() -> String:
	var model = OS.get_model_name()
	if model == "GenericDevice": 
		return OS.get_distribution_name() + " PC" 
	return model


# ==============================================================================
# 5. CALLBACK / RESPONSE HANDLING
# ==============================================================================

func _on_request_completed(
	result: int,
	response_code: int,
	headers: PackedStringArray,
	body: PackedByteArray
) -> void:
	_busy = false

	var text := body.get_string_from_utf8()
	var data: Dictionary = {}

	if text != "":
		var parsed = JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			data = parsed
		else:
			data = {"msg": "Ungültige Serverantwort."}
	else:
		# Bei Logout ist eine leere Antwort okay (wenn Status 200)
		data = {"msg": "Leere Serverantwort."}

	# Verteiler für die verschiedenen Anfragen
	match _current_endpoint:
		ENDPOINT_REGISTER:
			_handle_register_response(response_code, data)
		ENDPOINT_LOGIN:
			_handle_login_response(response_code, data)
		ENDPOINT_USER_ME:
			var success = response_code == 200
			user_data_received.emit(success, data)
		ENDPOINT_LOGOUT:
			# Beim Logout ist uns der Body fast egal, solange der Code 200 ist
			logout_completed.emit(response_code == 200)
		_:
			print("API: Unbekannter Endpoint in Antwort: ", _current_endpoint)

	_current_endpoint = ""


func _handle_register_response(code: int, data: Dictionary) -> void:
	var success := code == 201
	var message := str(data.get("msg", "Unbekannter Fehler"))

	if success:
		print("REGISTRIERUNG ERFOLGREICH: ", message)
	else:
		print("REGISTRIERUNG FEHLGESCHLAGEN (", code, "): ", message)

	registration_completed.emit(success, message)


func _handle_login_response(code: int, data: Dictionary) -> void:
	var success := code == 200
	var message := str(data.get("msg", "Unbekannter Fehler"))
	var user_id := int(data.get("user_id", 0))
	var token := str(data.get("token", ""))

	if success:
		print("LOGIN ERFOLGREICH: ", message, " | user_id=", user_id)
	else:
		print("LOGIN FEHLGESCHLAGEN (", code, "): ", message)

	login_completed.emit(success, message, user_id, token)
