from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Konfiguration und Datenbank
from app.core.config import settings
from app.db.session import engine, Base

# --- ROUTER IMPORTS ---
# Hier importieren wir alle API-Bereiche
from app.routers import users, customers, sales_router

# Modelle importieren, damit SQLAlchemy sie kennt und Tabellen erstellt
import app.models  # noqa: F401

# Tabellen in der Datenbank erstellen (falls noch nicht vorhanden)
Base.metadata.create_all(bind=engine)

# App Initialisierung
app = FastAPI(title="Anviro Backend")

# --- CORS KONFIGURATION ---
# Erlaubt Zugriff von Godot (oder Webbrowsern) auf die API
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- GLOBALER FEHLER-HANDLER ---
# Fängt unerwartete Abstürze ab und sendet sauberes JSON zurück
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"detail": f"Interner Serverfehler: {exc}"},
    )

# --- BASIS ENDPUNKTE ---

@app.get("/health")
def health_check():
    return {"status": "ok", "message": "Service is running"}

@app.get("/")
def read_root():
    return {
        "message": "Welcome to Anviro Backend API",
        "docs": "/docs",
        "health_check": "/health"
    }

# --- ROUTER EINBINDEN ---
# Hier schalten wir die verschiedenen API-Bereiche scharf
app.include_router(users.router)          # Login, Register, Logout
app.include_router(customers.router)      # Kundenverwaltung (GET)
app.include_router(sales_router.router)   # Vertrieb (Kunde anlegen + Auftrag)