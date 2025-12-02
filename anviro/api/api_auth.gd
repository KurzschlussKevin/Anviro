# res://scripts/api.gd (Beispielpfad)
extends Node
class_name API

# Basis-URL deines FastAPI-Backends
const BASE_URL := "http://127.0.0.1:8000"

# Endpunkte
const ENDPOINT_REGISTER := "/register"
const ENDPOINT_LOGIN    := "/login"

# Signale
signal registration_completed(success: bool, message: String)
signal login_completed(success: bool, message: String, user_id: int, token: String)

var _http: HTTPRequest
var _current_endpoint: String = ""
var _busy: bool = false


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)


# ==============================================================================
# 1. REGISTRIERUNG
# ==============================================================================

func register_user(user_data: Dictionary) -> void:
	# Erwartet z.B.:
	# {
	#   "salutation_id": 1,
	#   "vorname": "Max",
	#   "nachname": "Mustermann",
	#   "benutzername": "maxi",
	#   "email": "max@example.com",
	#   "mobilnummer": "0123456789",
	#   "postleitzahl": "12345",
	#   "stadt": "Berlin",
	#   "hausnr": "1a",
	#   "strasse": "Hauptstraße",
	#   "passwort": "geheim123",
	#   "role_id": 1
	# }

	if _busy:
		print("API: Anfrage läuft bereits, bitte warten.")
		return

	_busy = true
	_current_endpoint = ENDPOINT_REGISTER

	var url := BASE_URL + ENDPOINT_REGISTER
	var headers := ["Content-Type: application/json"]
	var body := JSON.stringify(user_data)

	print("API: Sende Registrierung an: ", url, " body=", body)

	var err := _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("API: HTTP-Anfragefehler (register) -> ", err)
		_busy = false
		registration_completed.emit(false, "Konnte Anfrage nicht senden.")


# ==============================================================================
# 2. LOGIN
# ==============================================================================

func login_user(email: String, passwort: String, hold_login: bool = false) -> void:
	# Backend erwartet:
	# { "email": "…", "passwort": "…", "hold_login": true/false }

	if _busy:
		print("API: Anfrage läuft bereits, bitte warten.")
		return

	_busy = true
	_current_endpoint = ENDPOINT_LOGIN

	var url := BASE_URL + ENDPOINT_LOGIN
	var headers := ["Content-Type: application/json"]
	var body := JSON.stringify({
		"email": email,
		"passwort": passwort,
		"hold_login": hold_login,
	})

	print("API: Sende Login an: ", url, " body=", body)

	var err := _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		print("API: HTTP-Anfragefehler (login) -> ", err)
		_busy = false
		login_completed.emit(false, "Konnte Anfrage nicht senden.", 0, "")


# ==============================================================================
# 3. CALLBACK / RESPONSE HANDLING
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
		data = {"msg": "Leere Serverantwort."}

	match _current_endpoint:
		ENDPOINT_REGISTER:
			_handle_register_response(response_code, data)
		ENDPOINT_LOGIN:
			_handle_login_response(response_code, data)
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
