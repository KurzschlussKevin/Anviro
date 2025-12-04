extends MainTemplate

@onready var template_node: Control = $ScrollContainer/GridContainer/KundenTemplate
@onready var grid_container: GridContainer = $ScrollContainer/GridContainer

func _ready() -> void:
	super._ready()
	
	if template_node:
		template_node.visible = false
	
	# Signale verbinden
	if not ApiCustomers.customers_loaded.is_connected(_on_customers_loaded):
		ApiCustomers.customers_loaded.connect(_on_customers_loaded)
	if not ApiCustomers.customer_deleted.is_connected(_on_customer_deleted):
		ApiCustomers.customer_deleted.connect(_on_customer_deleted)
	
	# Warten auf Token falls nötig
	if current_token == "":
		await get_tree().create_timer(0.5).timeout
	
	if current_token != "":
		_load_customers()

func _load_customers() -> void:
	print("Kundenverwaltung: Lade Daten...")
	# Alte Einträge entfernen (außer Template)
	for child in grid_container.get_children():
		if child != template_node:
			child.queue_free()
	
	ApiCustomers.fetch_all_customers(current_token)

func _on_customers_loaded(success: bool, data: Array) -> void:
	if not success: return
	
	for customer_data in data:
		var new_entry = template_node.duplicate()
		new_entry.visible = true
		grid_container.add_child(new_entry)
		_fill_entry_data(new_entry, customer_data)

func _fill_entry_data(entry_node: Control, data: Dictionary) -> void:
	var panel = entry_node.get_node("KundenTemplate")
	
	# --- TEXTFELDER BEFÜLLEN ---
	var lbl_firma = panel.get_node("Kundenname/LineEdit")
	lbl_firma.text = str(data.get("nachname", ""))
	
	var lbl_ap = panel.get_node("KundenAPNamen/LineEdit")
	lbl_ap.text = str(data.get("vorname", ""))
	
	var lbl_kdnr = panel.get_node("Kundennummer/LineEdit")
	lbl_kdnr.text = str(data.get("kundennummer", ""))
	
	# Adresse & Kontakt (Null-Check, damit nicht "<null>" steht)
	var strasse = data.get("strasse"); panel.get_node("Kundenstrasse/LineEdit").text = str(strasse) if strasse != null else ""
	var hausnr = data.get("hausnummer"); panel.get_node("Kundenhausnummer/LineEdit").text = str(hausnr) if hausnr != null else ""
	var plz = data.get("plz"); panel.get_node("Kundenplz/LineEdit").text = str(plz) if plz != null else ""
	var stadt = data.get("stadt"); panel.get_node("Kundenstadt/LineEdit").text = str(stadt) if stadt != null else ""
	var email = data.get("email"); panel.get_node("KundenEmail/LineEdit").text = str(email) if email != null else ""
	var tel = data.get("telefon"); panel.get_node("KundenTelefon/LineEdit").text = str(tel) if tel != null else ""
	var mobil = data.get("mobile"); panel.get_node("KundenMobile/LineEdit").text = str(mobil) if mobil != null else ""

	# --- PROGRESSBAR AUF 0% SETZEN ---
	var progress = panel.get_node("Statusanzeige") # Name aus deiner Szene (ProgressBar)
	if progress:
		progress.value = 0
	
	# --- STATUS ---
	var status_id = int(data.get("status_id", 1))
	var option_btn = panel.get_node("StatusOptionen")
	if option_btn: option_btn.selected = status_id

	# --- BUTTONS VERBINDEN ---
	# "Settings" = Bearbeiten, "Delete" = Löschen (Namen laut deiner Szene)
	var btn_edit = panel.get_node("Settings") 
	var btn_delete = panel.get_node("Delete")
	
	# Datenbank-ID für Aktionen
	var c_id = int(data.get("id", -1))
	
	if btn_edit:
		if btn_edit.pressed.is_connected(_on_edit_pressed): btn_edit.pressed.disconnect(_on_edit_pressed)
		# Wir binden das ganze Daten-Dictionary an den Button-Klick
		btn_edit.pressed.connect(_on_edit_pressed.bind(data))
		
	if btn_delete:
		if btn_delete.pressed.is_connected(_on_delete_pressed): btn_delete.pressed.disconnect(_on_delete_pressed)
		# Wir binden die ID und den Node (zum Löschen aus UI)
		btn_delete.pressed.connect(_on_delete_pressed.bind(c_id, entry_node))

# --- BUTTON ACTIONS ---

func _on_edit_pressed(data: Dictionary) -> void:
	print("Gehe zu Vertrieb für Bearbeitung: ", data.get("kundennummer"))
	# Daten global speichern und Szene wechseln
	Global.customer_to_edit = data
	get_tree().change_scene_to_file("res://scene/vertrieb/vertiebsbereich.tscn")

func _on_delete_pressed(id: int, node_to_remove: Node) -> void:
	print("Lösche Kunde ID: ", id)
	ApiCustomers.delete_customer(current_token, id)
	# UI sofort entfernen (optional: erst nach Erfolg entfernen)
	node_to_remove.queue_free()

func _on_customer_deleted(success: bool, msg: String) -> void:
	print("Lösch-Status: ", msg)
	if not success:
		# Falls Fehler, Liste neu laden (gelöschter Eintrag kommt wieder)
		_load_customers()
