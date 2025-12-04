extends Node

# Basis-URL deines Backends
const BASE_URL := "http://127.0.0.1:8000"
const ENDPOINT_CUSTOMERS := "/customers/"

# Signale für die UI
signal customers_loaded(success: bool, data: Array)
signal customer_created(success: bool, message: String)
signal customer_updated(success: bool, message: String)
signal customer_deleted(success: bool, message: String)

var _http: HTTPRequest
var _busy: bool = false
var _current_task: String = ""

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

# --- 1. ALLE LADEN (GET) ---
func fetch_all_customers(token: String) -> void:
	if _busy: return
	_busy = true
	_current_task = "fetch_all"
	
	var url = BASE_URL + ENDPOINT_CUSTOMERS
	var headers = ["Authorization: Bearer " + token]
	
	print("ApiCustomers: Lade alle Kunden...")
	_http.request(url, headers, HTTPClient.METHOD_GET)

# --- 2. NEU ERSTELLEN (POST) ---
func create_customer(token: String, customer_data: Dictionary) -> void:
	if _busy: return
	_busy = true
	_current_task = "create"
	
	var url = BASE_URL + ENDPOINT_CUSTOMERS
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + token]
	var body = JSON.stringify(customer_data)
	
	print("ApiCustomers: Erstelle Kunde...")
	_http.request(url, headers, HTTPClient.METHOD_POST, body)

# --- 3. UPDATEN (PUT) ---
func update_customer(token: String, customer_id: int, customer_data: Dictionary) -> void:
	if _busy: return
	_busy = true
	_current_task = "update"
	
	# ID wird an die URL angehängt
	var url = BASE_URL + ENDPOINT_CUSTOMERS + str(customer_id)
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + token]
	var body = JSON.stringify(customer_data)
	
	print("ApiCustomers: Update Kunde ID ", customer_id)
	_http.request(url, headers, HTTPClient.METHOD_PUT, body)

# --- 4. LÖSCHEN (DELETE) ---
func delete_customer(token: String, customer_id: int) -> void:
	if _busy: return
	_busy = true
	_current_task = "delete"
	
	var url = BASE_URL + ENDPOINT_CUSTOMERS + str(customer_id)
	var headers = ["Authorization: Bearer " + token]
	
	print("ApiCustomers: Lösche Kunde ID ", customer_id)
	_http.request(url, headers, HTTPClient.METHOD_DELETE)

# --- ANTWORT VERARBEITEN ---
func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	var text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(text)
	
	var data = null
	if parse_result == OK:
		data = json.data
	
	# Debug-Ausgabe bei Fehlern
	if response_code >= 400:
		print("API Fehler (", response_code, "): ", text)

	match _current_task:
		"fetch_all":
			if response_code == 200 and typeof(data) == TYPE_ARRAY:
				customers_loaded.emit(true, data)
			else:
				customers_loaded.emit(false, [])
		
		"create":
			var success = response_code == 200 or response_code == 201
			var msg = "Kunde erfolgreich angelegt."
			if not success and typeof(data) == TYPE_DICTIONARY:
				msg = data.get("detail", "Fehler beim Anlegen.")
			customer_created.emit(success, msg)
			
		"update":
			var success = response_code == 200
			var msg = "Änderungen gespeichert."
			if not success and typeof(data) == TYPE_DICTIONARY:
				msg = data.get("detail", "Fehler beim Speichern.")
			customer_updated.emit(success, msg)
			
		"delete":
			var success = response_code == 200
			var msg = "Kunde gelöscht."
			if not success and typeof(data) == TYPE_DICTIONARY:
				msg = data.get("detail", "Fehler beim Löschen.")
			customer_deleted.emit(success, msg)
			
	_current_task = ""
