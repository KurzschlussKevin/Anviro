extends Node

# Hier speichern wir den Kunden, der bearbeitet werden soll
var customer_to_edit: Dictionary = {}

# Hilfsfunktion zum Zurücksetzen
func clear_edit_customer():
	customer_to_edit = {}
