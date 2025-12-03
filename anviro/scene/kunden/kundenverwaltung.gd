extends MainTemplate # Erbt von deinem MainTemplate (wichtig für Token!)

# Lade dein Template hier vor (Pfad zur .tscn Datei anpassen!)
const CUSTOMER_ROW_SCENE = preload("res://scene/kunden/customer_row.tscn")

# Container, wo die Liste rein soll (VBoxContainer innerhalb des ScrollContainers)
@onready var list_container: VBoxContainer = $Content/ScrollContainer/VBoxContainer
@onready var loading_label: Label = $Content/LoadingInfo # Optional

func _ready() -> void:
	super._ready() # WICHTIG: Token laden lassen
	
	# Signal der NEUEN Api verbinden
	if not ApiCustomers.customers_loaded.is_connected(_on_customers_loaded):
		ApiCustomers.customers_loaded.connect(_on_customers_loaded)
	
	# Starten
	_load_customers()

func _load_customers() -> void:
	# Warten bis Token da ist (aus MainTemplate Logic)
	if current_token == "":
		print("Warte auf Token...")
		await get_tree().create_timer(0.5).timeout
		if current_token == "":
			print("Kein Token, Abbruch.")
			return
	
	if loading_label: loading_label.show()
	
	# Alte Einträge löschen (damit Liste nicht doppelt wird bei Reload)
	for child in list_container.get_children():
		child.queue_free()
	
	# Aufruf der neuen API
	ApiCustomers.fetch_all_customers(current_token)

func _on_customers_loaded(success: bool, data: Array) -> void:
	if loading_label: loading_label.hide()
	
	if not success:
		print("Konnte Kunden nicht laden.")
		return
	
	print("Habe ", data.size(), " Kunden empfangen.")
	
	# Für jeden Kunden im Array...
	for customer_dict in data:
		# 1. Template duplizieren
		var new_row = CUSTOMER_ROW_SCENE.instantiate()
		
		# 2. Daten übergeben (ruft die Funktion in customer_row.gd auf)
		if new_row.has_method("set_data"):
			new_row.set_data(customer_dict)
		else:
			printerr("Fehler: Dein Template hat kein 'set_data' Skript!")
		
		# 3. Zur Liste hinzufügen
		list_container.add_child(new_row)
