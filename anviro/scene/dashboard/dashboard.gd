extends MainTemplate 
# Wir erben von MainTemplate. 
# Das bedeutet: Das Dashboard hat automatisch _ready(), _load_local_user_data() 
# und alle Buttons aus dem Template!

func _ready() -> void:
	# WICHTIG: Wir rufen super._ready() auf, damit das Template seinen Job macht
	super._ready()
	
	# Hier kannst du später dashboard-spezifische Dinge tun
	# z.B. "Lade Umsatzstatistiken"
	print("Dashboard ist bereit und hat Daten vom Template geerbt.")
