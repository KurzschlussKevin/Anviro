extends MainTemplate

# Verweis auf das Template, das DU schon in der Szene gebaut hast
# (Achte darauf, dass der Name im Szenenbaum exakt "KundenTemplate" ist)
@onready var template_node: Control = $ScrollContainer/GridContainer/KundenTemplate

# Der Container, wo die Kopien rein sollen (GridContainer in deinem Fall)
@onready var grid_container: GridContainer = $ScrollContainer/GridContainer


func _ready() -> void:
	super._ready()
	
	# 1. Das Original-Template verstecken, damit es nicht leer herumhängt
	if template_node:
		template_node.visible = false
	
	# API verbinden
	if not ApiCustomers.customers_loaded.is_connected(_on_customers_loaded):
		ApiCustomers.customers_loaded.connect(_on_customers_loaded)
	
	_load_customers()

func _load_customers() -> void:
	if current_token == "":
		await get_tree().create_timer(0.5).timeout
		if current_token == "": return
	
	# Alte Kopien löschen (aber NICHT das Original-Template!)
	for child in grid_container.get_children():
		if child != template_node: # Das Original behalten wir!
			child.queue_free()
	


func _on_customers_loaded(success: bool, data: Array) -> void:
	if not success: return
	
	print("Lade ", data.size(), " Kunden in das Grid.")
	
	for customer_data in data:
		# 1. WICHTIG: Das Template duplizieren
		var new_entry = template_node.duplicate()
		
		# 2. Dem Duplikat einen einzigartigen Namen geben (optional, aber sauber)
		# z.B. "Kunde_123"
		var kdnr = str(customer_data.get("kundennummer", "neu"))
		new_entry.name = "Kunde_" + kdnr
		
		# 3. Sichtbar machen (weil das Original ja versteckt ist)
		new_entry.visible = true
		
		# 4. Zum Grid hinzufügen
		grid_container.add_child(new_entry)
		
		# 5. Daten in die Felder schreiben
		# Da die Nodes im Duplikat exakt wie im Original heißen, finden wir sie per Pfad
		_fill_entry_data(new_entry, customer_data)

func _fill_entry_data(entry_node: Control, data: Dictionary) -> void:
	# Pfade basierend auf deiner Szene (KundenTemplate -> KundenTemplate (Panel) -> HBox...)
	# Achtung: Deine Struktur ist verschachtelt. Wir nutzen find_child oder direkte Pfade.
	
	# Beispiel: Kundenname -> LineEdit
	# Pfad im Editor: KundenTemplate/Kundenname/LineEdit
	var panel = entry_node.get_node("KundenTemplate") # Das innere Panel
	
	# Name (Firma)
	var lbl_firma = panel.get_node("Kundenname/LineEdit")
	lbl_firma.text = str(data.get("vorname", "")) + " " + str(data.get("nachname", ""))
	
	# Kundennummer
	var lbl_kdnr = panel.get_node("Kundennummer/LineEdit")
	lbl_kdnr.text = str(data.get("kundennummer", ""))
	
	# Stadt
	var lbl_stadt = panel.get_node("Kundenstadt/LineEdit")
	lbl_stadt.text = str(data.get("stadt", ""))
	
	# PLZ
	var lbl_plz = panel.get_node("Kundenplz/LineEdit")
	lbl_plz.text = str(data.get("plz", ""))
	
	# Status (ProgressBar & OptionButton)
	# Hier könntest du Logik einbauen, um den Status anzuzeigen
	var status_id = int(data.get("status_id", 1))
	var option_btn = panel.get_node("StatusOptionen")
	# OptionButton Indizes anpassen (0=Titel, 1=Offen...)
	if option_btn:
		option_btn.selected = status_id
