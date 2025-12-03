extends Node

const BASE_URL := "http://127.0.0.1:8000"
const ENDPOINT_SALES := "/sales/"

signal sale_created(success: bool, message: String)

var _http: HTTPRequest
var _busy: bool = false

func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

func create_sale(token: String, customer_id: int, items: Array) -> void:
	if _busy: return
	_busy = true
	
	var url = BASE_URL + ENDPOINT_SALES
	var headers = ["Content-Type: application/json", "Authorization: Bearer " + token]
	
	var body_data = {
		"customer_id": customer_id,
		"items": items
	}
	
	print("ApiSales: Sende Auftrag mit ", items.size(), " Positionen...")
	_http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body_data))

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_busy = false
	if response_code == 200 or response_code == 201:
		sale_created.emit(true, "Auftrag erfolgreich gespeichert!")
	else:
		print("Sales Error: ", response_code)
		sale_created.emit(false, "Fehler beim Speichern.")
