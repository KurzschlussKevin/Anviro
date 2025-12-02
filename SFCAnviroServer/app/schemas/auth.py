from pydantic import BaseModel, EmailStr
from typing import Optional


class RegisterRequest(BaseModel):
    salutation_id: Optional[int] = None
    vorname: str
    nachname: str
    benutzername: str
    email: EmailStr
    mobilnummer: Optional[str] = None
    postleitzahl: Optional[str] = None
    stadt: Optional[str] = None
    hausnr: Optional[str] = None
    strasse: Optional[str] = None
    passwort: str
    role_id: int = 1  # Standard-Rolle


class LoginRequest(BaseModel):
    email: EmailStr
    passwort: str
    hold_login: bool = False
    
    # --- NEU: Felder für Geräte-Identifizierung ---
    # Optional, damit alte Clients nicht abstürzen, aber empfohlen für Godot
    device_id: Optional[str] = None   # Die UUID, die Godot generiert und speichert
    device_name: Optional[str] = None # z.B. "Max PC"
    platform: Optional[str] = None    # z.B. "Windows"