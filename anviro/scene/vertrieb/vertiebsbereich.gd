extends MainTemplate

# --- UI REFERENZEN (Pfade aus deiner Szene) ---
@onready var kunden_panel = $KundenTemplate/KundenTemplate
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

@onready var btn_speichern = $KundenSpeichern

# --- STATUS VARIABLEN ---
var is_edit_mode: bool = false
var edit_customer_id: int = -1

func _ready() -> void:
	super._ready()
	
	# Signale verbinden
	if not ApiCustomers.customer_created.is_connected(_on_action_completed):
		ApiCustomers.customer_created.connect(_on_action_completed)
	if not ApiCustomers.customer_updated.is_connected(_on_action_completed):
		ApiCustomers.customer_updated.connect(_on_action_completed)
	
	# Button verbinden
	btn_speichern.pressed.connect(_on_speichern_pressed)
	
	# Prüfen: Sind wir im Edit-Modus?
	if Global.customer_to_edit.size() > 0:
		print("Vertrieb: Edit-Modus aktiviert")
		_setup_edit_mode()
	else:
		print("Vertrieb: Erstell-Modus")
		is_edit_mode = false
		btn_speichern.text = "Kunde speichern"

func _setup_edit_mode() -> void:
	is_edit_mode = true
	var data = Global.customer_to_edit
	edit_customer_id = int(data.get("id"))
	
	# Felder füllen
	inp_firma.text = str(data.get("nachname", ""))
	inp_ap.text = str(data.get("vorname", ""))
	inp_kdnr.text = str(data.get("kundennummer", ""))
	
	# Null-Checks für optionale Felder
	var s = data.get("strasse"); inp_strasse.text = str(s) if s != null else ""
	var h = data.get("hausnummer"); inp_hausnr.text = str(h) if h != null else ""
	var p = data.get("plz"); inp_plz.text = str(p) if p != null else ""
	var c = data.get("stadt"); inp_stadt.text = str(c) if c != null else ""
	var e = data.get("email"); inp_email.text = str(e) if e != null else ""
	var t = data.get("telefon"); inp_tel.text = str(t) if t != null else ""
	var m = data.get("mobile"); inp_mobile.text = str(m) if m != null else ""
	
	# Button Text anpassen
	btn_speichern.text = "Änderungen speichern"

# Wird aufgerufen, wenn die Szene verlassen wird
func _exit_tree():
	# WICHTIG: Global resetten, damit man beim nächsten Mal nicht wieder im Edit-Modus landet
	Global.customer_to_edit = {}

func _on_speichern_pressed() -> void:
	# Daten sammeln
	var data = {
		"kundennummer": inp_kdnr.text,
		"vorname": inp_ap.text,      # AP als Vorname
		"nachname": inp_firma.text,  # Firma als Nachname
		"strasse": inp_strasse.text,
		"hausnummer": inp_hausnr.text,
		"plz": inp_plz.text,
		"stadt": inp_stadt.text,
		"email": inp_email.text if inp_email.text != "" else null,
		"telefon": inp_tel.text if inp_tel.text != "" else null,
		"mobile": inp_mobile.text if inp_mobile.text != "" else null
	}
	
	if is_edit_mode:
		print("Sende Update an ID: ", edit_customer_id)
		ApiCustomers.update_customer(current_token, edit_customer_id, data)
	else:
		print("Sende Erstellung...")
		ApiCustomers.create_customer(current_token, data)

func _on_action_completed(success: bool, msg: String) -> void:
	print("Server Antwort: ", msg)
	if success:
		# Optional: Zurück zur Übersicht wechseln
		ChangeScene.switch_scene("res://scene/kunden/kundenverwaltung.tscn")
		pass
