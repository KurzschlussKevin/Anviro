extends MainTemplate

# Verweis auf das Template, das DU schon in der Szene gebaut hast
# (Achte darauf, dass der Name im Szenenbaum exakt "KundenTemplate" ist)
@onready var template_node: Control = $ScrollContainer/GridContainer/KundenTemplate

# Der Container, wo die Kopien rein sollen (GridContainer in deinem Fall)
@onready var grid_container: GridContainer = $ScrollContainer/GridContainer


func _ready() -> void:
	# 1. MainTemplate Logik ausführen (lädt Token im Hintergrund)
	super._ready()
	
	# 2. Das Original-Template verstecken, damit es nicht leer herumhängt
	if template_node:
		template_node.visible = false
	
	# 3. API Signale verbinden
	if not ApiCustomers.customers_loaded.is_connected(_on_customers_loaded):
		ApiCustomers.customers_loaded.connect(_on_customers_loaded)
	
	# 4. Prüfen, ob wir schon ein Token haben
	if current_token == "":
		print("Kundenverwaltung: Token noch nicht da, warte kurz...")
		# Wir warten aktiv bis zu 1 Sekunde oder bis das Token gesetzt wird
		await get_tree().create_timer(1.0).timeout
		
		# Erneuter Check nach Wartezeit (MainTemplate sollte es jetzt geladen haben)
		if current_token != "":
			_load_customers()
		else:
			printerr("Kundenverwaltung FEHLER: Auch nach Wartezeit kein Token gefunden!")
	else:
		# Token war sofort da -> direkt laden
		_load_customers()


func _load_customers() -> void:
	print("Kundenverwaltung: Lade Kunden vom Server...")
	
	# Alte Kopien löschen (aber NICHT das Original-Template!)
	for child in grid_container.get_children():
		if child != template_node: 
			child.queue_free()
	
	# Anfrage an Backend senden
	ApiCustomers.fetch_all_customers(current_token)


func _on_customers_loaded(success: bool, data: Array) -> void:
	if not success: 
		print("Kundenverwaltung: Laden fehlgeschlagen oder Liste leer.")
		return
	
	print("Lade ", data.size(), " Kunden in das Grid.")
	
	for customer_data in data:
		# 1. Template duplizieren
		var new_entry = template_node.duplicate()
		
		# 2. Dem Duplikat einen einzigartigen Namen geben
		var kdnr = str(customer_data.get("kundennummer", "neu"))
		new_entry.name = "Kunde_" + kdnr
		
		# 3. Sichtbar machen
		new_entry.visible = true
		
		# 4. Zum Grid hinzufügen
		grid_container.add_child(new_entry)
		
		# 5. Daten in die Felder schreiben
		_fill_entry_data(new_entry, customer_data)


func _fill_entry_data(entry_node: Control, data: Dictionary) -> void:
	# Pfad zum inneren Panel
	# Struktur: PanelContainer (entry_node) -> Panel (KundenTemplate) -> HBoxContainer -> LineEdit
	var panel = entry_node.get_node("KundenTemplate") 
	
	# --- 1. FIRMA & ANSPRECHPARTNER ---
	# "nachname" = Firma, "vorname" = Ansprechpartner
	var lbl_firma = panel.get_node("Kundenname/LineEdit")
	lbl_firma.text = str(data.get("nachname", "")) 
	
	var lbl_ap = panel.get_node("KundenAPNamen/LineEdit")
	lbl_ap.text = str(data.get("vorname", "")) 
	
	# --- 2. BASISDATEN ---
	var lbl_kdnr = panel.get_node("Kundennummer/LineEdit")
	lbl_kdnr.text = str(data.get("kundennummer", ""))
	
	# --- 3. ADRESSE ---
	var lbl_strasse = panel.get_node("Kundenstrasse/LineEdit")
	lbl_strasse.text = str(data.get("strasse", ""))
	
	var lbl_hausnr = panel.get_node("Kundenhausnummer/LineEdit")
	lbl_hausnr.text = str(data.get("hausnummer", ""))
	
	var lbl_plz = panel.get_node("Kundenplz/LineEdit")
	lbl_plz.text = str(data.get("plz", ""))
	
	var lbl_stadt = panel.get_node("Kundenstadt/LineEdit")
	lbl_stadt.text = str(data.get("stadt", ""))
	
	# --- 4. KONTAKT ---
	var lbl_email = panel.get_node("KundenEmail/LineEdit")
	var email_val = data.get("email")
	lbl_email.text = email_val if email_val != null else ""
	
	var lbl_tel = panel.get_node("KundenTelefon/LineEdit")
	var tel_val = data.get("telefon")
	lbl_tel.text = tel_val if tel_val != null else ""
	
	# Mobilnummer (benötigt Update in Backend customer.py!)
	var lbl_mobile = panel.get_node("KundenMobile/LineEdit")
	var mobile_val = data.get("mobile")
	lbl_mobile.text = mobile_val if mobile_val != null else ""
	
	# --- 5. STATUS ---
	var status_id = int(data.get("status_id", 1))
	var option_btn = panel.get_node("StatusOptionen")
	if option_btn:
		option_btn.selected = status_id
