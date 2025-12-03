extends Node

# Basis-URL (gleich wie bei ApiAuth)
const BASE_URL := "http://127.0.0.1:8000"
const ENDPOINT_CUSTOMERS := "/customers/"

# Signale
signal customers_loaded(success: bool, data: Array)
signal customer_created(success: bool, message: String)

var _http: HTTPRequest
var _busy: bool = false
var _current_task: String = ""

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

# --- FUNKTIONEN ---

func fetch_all_customers(token: String) -> void:
	if _busy: return
	_busy = true
	_current_task = "fetch_all"
	
	var url = BASE_URL + ENDPOINT_CUSTOMERS
	var headers = ["Authorization: Bearer " + token]
	
	print("ApiCustomers: Lade alle Kunden...")
	var error = _http.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		_busy = false
		customers_loaded.emit(false, [])

# Optional: Später zum Anlegen
func create_customer(token: String, customer_data: Dictionary) -> void:
	if _busy: return
	_busy = true
	_current_task = "create"
	
	var url = BASE_URL + ENDPOINT_CUSTOMERS
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + token]
	var body = JSON.stringify(customer_data)
	
	_http.request(url, headers, HTTPClient.METHOD_POST, body)

# --- ANTWORT VERARBEITEN ---

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	var text = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(text)
	
	var data = null
	if parse_result == OK:
		data = json.data
	
	match _current_task:
		"fetch_all":
			if response_code == 200 and typeof(data) == TYPE_ARRAY:
				customers_loaded.emit(true, data)
			else:
				print("ApiCustomers Fehler: ", response_code)
				customers_loaded.emit(false, [])
		
		"create":
			var success = response_code == 200 or response_code == 201
			var msg = "Erfolg"
			if typeof(data) == TYPE_DICTIONARY:
				msg = data.get("detail", "Unbekannter Fehler")
			customer_created.emit(success, msg)
			
	_current_task = ""
