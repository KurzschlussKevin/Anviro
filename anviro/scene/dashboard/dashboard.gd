extends MainTemplate # Erbt jetzt vom Template!

# Konstanten für Speicher
const SAVE_PATH = "user://user_profile.save"
const ENC_KEY = "DeinGeheimesPasswortHier"

# Spezifische UI Elemente für das Dashboard
@onready var label_username: Label = $Personalinfos/Username
@onready var label_rolle: Label = $Personalinfos/Rolle

func _ready() -> void:
	super._ready() # Ruft _ready vom MainTemplate auf (Navigation verbinden!)
	
	# Spezifische Dashboard-Logik: Daten laden
	ApiAuth.user_data_received.connect(_on_user_data_received)
	_load_local_user_data()

func _load_local_user_data() -> void:
	# ... (Dein Code zum Laden der Datei und Aufruf von ApiAuth.fetch_user_data) ...
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENC_KEY)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK:
				var token = json.data.get("token", "")
				ApiAuth.fetch_user_data(token)

func _on_user_data_received(success: bool, data: Dictionary) -> void:
	if success:
		label_username.text = str(data.get("username", "Gast"))
		# ... Rolle setzen ...
	else:
		_do_local_logout()
