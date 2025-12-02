extends HSplitContainer
class_name register

@onready var anrede: OptionButton        = $authregister/Anrede
@onready var vorname: LineEdit          = $authregister/Vorname
@onready var nachname: LineEdit         = $authregister/Nachname
@onready var benutzername: LineEdit     = $authregister/Benutzername
@onready var email: LineEdit            = $authregister/Email
@onready var mobilenummer: LineEdit     = $authregister/Mobilenummer
@onready var postleitzahl: LineEdit     = $authregister/Postleitzahl
@onready var stadt: LineEdit            = $authregister/Stadt
@onready var hausnummer: LineEdit       = $authregister/Hausnummer
@onready var straßennamen: LineEdit     = $authregister/Straßennamen
@onready var passwort: LineEdit         = $authregister/Passwort
@onready var passwort_wiederholen: LineEdit = $authregister/Passwort_wiederholen


func _ready() -> void:
	# Mit dem Signal aus API.gd verbinden (nur einmal)
	if not ApiAuth.registration_completed.is_connected(_on_registration_completed):
		ApiAuth.registration_completed.connect(_on_registration_completed)


func _on_create_account_pressed() -> void:
	# 1. Grundvalidierung
	var pw := passwort.text
	var pw2 := passwort_wiederholen.text

	if pw == "" or pw2 == "":
		print("Registrierung: Passwort darf nicht leer sein.")
		return

	if pw != pw2:
		print("Registrierung: Passwörter stimmen nicht überein.")
		return

	if vorname.text.strip_edges() == "" or nachname.text.strip_edges() == "":
		print("Registrierung: Vorname und Nachname sind erforderlich.")
		return

	if benutzername.text.strip_edges() == "":
		print("Registrierung: Benutzername ist erforderlich.")
		return

	if email.text.strip_edges() == "":
		print("Registrierung: E-Mail ist erforderlich.")
		return

	# 2. Anrede -> salutation_id (hier einfach die ID des OptionButton)
	var salutation_id := anrede.get_selected_id()
	if salutation_id == -1:
		# Falls du noch nichts gesetzt hast: default 1
		salutation_id = 1

	# 3. Payload für die API zusammenbauen (Keys müssen zu deinem Backend passen!)
	var payload: Dictionary = {
		"salutation_id": salutation_id,
		"vorname": vorname.text.strip_edges(),
		"nachname": nachname.text.strip_edges(),
		"benutzername": benutzername.text.strip_edges(),
		"email": email.text.strip_edges(),
		"mobilnummer": mobilenummer.text.strip_edges(),
		"postleitzahl": postleitzahl.text.strip_edges(),
		"stadt": stadt.text.strip_edges(),
		"hausnr": hausnummer.text.strip_edges(),
		"strasse": straßennamen.text.strip_edges(),
		"passwort": pw,
		# Wenn dein Backend role_id hat, kannst du hier z. B. 1 als Standard-User setzen:
		"role_id": 1,
	}

	# 4. Request abfeuern
	print("Registrierung: Sende Daten an API…")
	ApiAuth.register_user(payload)


func _on_registration_completed(success: bool, message: String) -> void:
	# Callback vom API-Singleton, wenn die Antwort vom Server kommt
	if success:
		print("Registrierung erfolgreich: ", message)
		# Hier könntest du z. B. zur Login-Ansicht wechseln, Felder leeren etc.
		# Beispiel:
		# _clear_fields()
	else:
		print("Registrierung fehlgeschlagen: ", message)


func _clear_fields() -> void:
	vorname.text = ""
	nachname.text = ""
	benutzername.text = ""
	email.text = ""
	mobilenummer.text = ""
	postleitzahl.text = ""
	stadt.text = ""
	hausnummer.text = ""
	straßennamen.text = ""
	passwort.text = ""
	passwort_wiederholen.text = ""
	# Optional: Anrede zurücksetzen
	# anrede.selected = 0


func _on_login_pressed() -> void:
	self.visible = false
	$"../login".visible = true
