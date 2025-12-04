extends MainTemplate

# --- KUNDEN FELDER ---
@onready var kunden_panel = $KundenTemplate/KundenTemplate
# Pfade basierend auf deiner Szene:
@onready var inp_firma = kunden_panel.get_node("Kundenname/LineEdit")
@onready var inp_kdnr = kunden_panel.get_node("Kundennummer/LineEdit")
@onready var inp_plz = kunden_panel.get_node("Kundenplz/LineEdit")
@onready var inp_stadt = kunden_panel.get_node("Kundenstadt/LineEdit")
@onready var inp_strasse = kunden_panel.get_node("Kundenstrasse/LineEdit")
@onready var inp_hausnr = kunden_panel.get_node("Kundenhausnummer/LineEdit")
@onready var inp_email = kunden_panel.get_node("KundenEmail/LineEdit")
@onready var inp_tel = kunden_panel.get_node("KundenTelefon/LineEdit")
@onready var inp_mobile = kunden_panel.get_node("KundenMobile/LineEdit")
@onready var inp_ap = kunden_panel.get_node("KundenAPNamen/LineEdit")

# --- POSITIONS LISTE ---
@onready var positions_container = $PanelContainer/VSplitContainer/ScrollContainer/VBoxContainer
@onready var position_template = positions_container.get_node("PositionTemplate")

# --- ID TRACKING ---
var created_customer_id: int = -1 # Merkt sich die ID, wenn Kunde gespeichert wurde

func _ready() -> void:
	super._ready()
	
	# Template verstecken
	if position_template:
		position_template.visible = false
	
	# Signale verbinden
	if not ApiCustomers.customer_created.is_connected(_on_customer_created):
		ApiCustomers.customer_created.connect(_on_customer_created)
	
	if not ApiSales.sale_created.is_connected(_on_sale_created):
		ApiSales.sale_created.connect(_on_sale_created)
		
	# Buttons verbinden (Pfade aus deiner Szene)
	var btn_save_kunde = kunden_panel.get_node("KundenSpeichern")
	btn_save_kunde.pressed.connect(_on_kunden_speichern_pressed)
	
	var btn_new_pos = get_node("NeuePosition") # Button unten
	btn_new_pos.pressed.connect(_on_neue_position_pressed)
	
	var btn_save_sale = get_node("KundenSpeichern") # Button unten "Speichern" (Vorsicht: Namenskonflikt?)
	# Ich nehme an, der untere Button heißt "KundenSpeichern" im Editor laut deinem Dump (Index 5).
	# Besser wäre, ihn "AuftragSpeichern" zu nennen.
	btn_save_sale.pressed.connect(_on_auftrag_speichern_pressed)

# --- 1. KUNDE SPEICHERN ---
func _on_kunden_speichern_pressed() -> void:
	var data = {
		"kundennummer": inp_kdnr.text,
		"vorname": inp_ap.text,
		"nachname": inp_firma.text,
		"stadt": inp_stadt.text,
		"plz": inp_plz.text,
		"strasse": inp_strasse.text,
		"hausnr": inp_hausnr.text,
		"email": inp_email.text if inp_email.text != "" else null,
		"telefon": inp_tel.text if inp_tel.text != "" else null,
		"mobile": inp_mobile.text if inp_mobile.text != "" else null
	}
	
	ApiCustomers.create_customer(current_token, data)

func _on_customer_created(success: bool, msg: String) -> void:
	if success:
		print("Kunde angelegt! (ID müsste vom Backend zurückkommen)")
		# Hinweis: Um die ID zu bekommen, müsste ApiCustomers angepasst werden,
		# um die Antwort-ID zurückzugeben (nicht nur success).
		# Für jetzt simulieren wir es oder du musst die API erweitern.
		created_customer_id = 1 # Dummy, bis API update
		print("Kunden-ID für Auftrag gesetzt.")
	else:
		print("Fehler Kunde: ", msg)

# --- 2. POSITIONEN HINZUFÜGEN ---
func _on_neue_position_pressed() -> void:
	var new_row = position_template.duplicate()
	new_row.visible = true
	# Optional: Felder leeren
	new_row.get_node("Bezeichnung").text = ""
	new_row.get_node("Menge").text = ""
	new_row.get_node("Einzelpreis").text = ""
	new_row.get_node("Gesamt").text = ""
	
	# Signal verbinden, um "Gesamt" automatisch zu berechnen?
	# new_row.get_node("Menge").text_changed.connect(...) 
	
	positions_container.add_child(new_row)

# --- 3. AUFTRAG SPEICHERN ---
func _on_auftrag_speichern_pressed() -> void:
	if created_customer_id == -1:
		print("Bitte erst den Kunden speichern!")
		return
		
	var items_list = []
	
	# Durch alle Zeilen loopen (außer das versteckte Template)
	for child in positions_container.get_children():
		if child == position_template or not child.visible:
			continue
			
		var pos_data = {
			"position_nr": child.get_node("Position").text,
			"bezeichnung": child.get_node("Bezeichnung").text,
			"gruppe": child.get_node("Gruppe").get_item_text(child.get_node("Gruppe").selected),
			"menge": float(child.get_node("Menge").text),
			"einzelpreis": float(child.get_node("Einzelpreis").text),
			"gesamt": float(child.get_node("Gesamt").text)
		}
		items_list.append(pos_data)
	
	if items_list.is_empty():
		print("Keine Positionen eingetragen.")
		return

	ApiSales.create_sale(current_token, created_customer_id, items_list)

func _on_sale_created(success: bool, msg: String) -> void:
	print("Auftrag Status: ", msg)
	if success:
		# Alles leeren oder Szene neu laden
		pass
