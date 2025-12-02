import traceback
from datetime import datetime, timezone, timedelta
import uuid

from fastapi import APIRouter, Depends, HTTPException, Request, Header
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError

from app.db.session import get_db
from app.models.user import User
from app.models.user_login import UserLogin
from app.models.user_device import UserDevice
from app.schemas.auth import RegisterRequest, LoginRequest
from app.core.security import hash_password, verify_password

router = APIRouter(tags=["Users"])

# --- HILFSFUNKTION: Token Validierung für Godot ---
def get_current_user_from_token(
    authorization: str = Header(None), 
    db: Session = Depends(get_db)
):
    if not authorization:
        raise HTTPException(status_code=401, detail="Fehlender Auth Header")
    
    token = authorization.replace("Bearer ", "")
    
    # Token muss existieren UND aktiv sein
    login_entry = db.query(UserLogin).filter(
        UserLogin.token == token,
        UserLogin.is_active == True
    ).first()
    
    if not login_entry:
        raise HTTPException(status_code=401, detail="Token ungültig oder abgelaufen")
        
    return login_entry.user


@router.post("/register")
def register_user(payload: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.username == payload.benutzername).first():
        return JSONResponse(status_code=409, content={"msg": "Benutzername existiert bereits."})

    if db.query(User).filter(User.email == payload.email).first():
        return JSONResponse(status_code=409, content={"msg": "E-Mail-Adresse ist bereits registriert."})

    if payload.mobilnummer and db.query(User).filter(User.mobile_number == payload.mobilnummer).first():
        return JSONResponse(status_code=409, content={"msg": "Mobilnummer ist bereits registriert."})

    user = User(
        salutation_id=payload.salutation_id,
        first_name=payload.vorname,
        last_name=payload.nachname,
        username=payload.benutzername,
        email=payload.email,
        mobile_number=payload.mobilnummer,
        postal_code=payload.postleitzahl,
        city=payload.stadt,
        house_number=payload.hausnr,
        street=payload.strasse,
        password_hash=hash_password(payload.passwort),
        role_id=payload.role_id,
    )

    try:
        db.add(user)
        db.commit()
        db.refresh(user)
    except IntegrityError:
        db.rollback()
        return JSONResponse(status_code=409, content={"msg": "Datenbank-Konflikt bei der Registrierung."})
    except Exception as e:
        db.rollback()
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Interner Serverfehler: {e}")

    return JSONResponse(
        status_code=201,
        content={
            "status": "Erfolgreich",
            "msg": f"Benutzer '{user.username}' erfolgreich registriert.",
            "user_id": user.id,
        },
    )


@router.post("/login")
def login_user(
    payload: LoginRequest,
    request: Request,
    db: Session = Depends(get_db),
):
    # 1. User suchen
    user = db.query(User).filter(User.email == payload.email).first()

    if not user:
        return JSONResponse(status_code=404, content={"msg": "E-Mail wurde nicht gefunden."})

    # 2. Passwort prüfen
    if not verify_password(payload.passwort, user.password_hash):
        return JSONResponse(status_code=401, content={"msg": "Falsches Passwort."})

    # 3. Token generieren (Unique machen)
    token = f"TOKEN-{user.id}-{uuid.uuid4()}"

    # --- TEIL A: Login Historie (UserLogins) ---
    # Das wird IMMER neu geschrieben (Audit Log)
    client_ip = request.client.host if request.client else None
    user_agent = request.headers.get("user-agent", "")

    login_entry = UserLogin(
        user_id=user.id,
        token=token,
        is_active=True,
        ip_address=client_ip,
        user_agent=user_agent,
        hold_login=payload.hold_login,
        login_at=datetime.now(timezone.utc),
    )
    db.add(login_entry)

    # --- TEIL B: Geräte Management (UserDevice) ---
    # Hier prüfen wir, ob wir das Gerät schon kennen
    
    # Werte aus Payload holen oder Fallback nutzen
    current_device_id = payload.device_id
    current_device_name = payload.device_name or "Unknown Device"
    current_platform = payload.platform or "unknown"

    # Fallback: Wenn Godot keine ID schickt, generieren wir eine temporäre
    if not current_device_id:
        current_device_id = str(uuid.uuid4())

    # Suche in DB nach existierendem Gerät für diesen User
    existing_device = db.query(UserDevice).filter(
        UserDevice.user_id == user.id,
        # Hinweis: Falls in der DB device_uuid als UUID-Typ gespeichert ist, wandelt SQLAlchemy das oft automatisch um.
        # Falls es Probleme gibt, müsste man hier uuid.UUID(current_device_id) nutzen.
        UserDevice.device_uuid == current_device_id 
    ).first()

    if existing_device:
        # UPDATE: Gerät bekannt -> Zeitstempel aktualisieren
        existing_device.last_login_at = datetime.now(timezone.utc)
        existing_device.trusted_until = datetime.now(timezone.utc) + timedelta(days=30)
        
        # Namen aktualisieren falls vorhanden
        if payload.device_name:
            existing_device.device_name = payload.device_name
        if payload.platform:
            existing_device.platform = payload.platform
            
    else:
        # INSERT: Gerät unbekannt -> Neu anlegen
        new_device = UserDevice(
            user_id=user.id,
            device_uuid=current_device_id,
            device_name=current_device_name,
            platform=current_platform,
            last_login_at=datetime.now(timezone.utc),
            trusted_until=datetime.now(timezone.utc) + timedelta(days=30),
        )
        db.add(new_device)

    try:
        db.commit()
    except Exception as e:
        db.rollback()
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Fehler beim Speichern: {e}")

    return JSONResponse(
        status_code=200,
        content={
            "status": "Erfolgreich",
            "msg": "Login erfolgreich.",
            "user_id": user.id,
            "token": token,
        },
    )


@router.post("/logout")
def logout(
    authorization: str = Header(None), 
    db: Session = Depends(get_db)
):
    if not authorization:
         raise HTTPException(status_code=401, detail="Nicht eingeloggt")

    token = authorization.replace("Bearer ", "")
    
    # Token suchen und deaktivieren
    login_entry = db.query(UserLogin).filter(UserLogin.token == token).first()
    
    if login_entry:
        login_entry.is_active = False
        db.commit()
        return {"msg": "Erfolgreich ausgeloggt"}
    
    return {"msg": "Token nicht gefunden oder bereits ausgeloggt"}

# 2. /users/me anpassen (role_id hinzufügen)
@router.get("/users/me")
def read_users_me(current_user: User = Depends(get_current_user_from_token)):
    return {
        "id": current_user.id,
        "email": current_user.email,
        "username": current_user.username,
        "role_id": current_user.role_id, # <--- NEU: Damit wir die Rolle anzeigen können
        "status": "valid"
    }