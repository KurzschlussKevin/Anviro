from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Diese Imports setzen voraus, dass deine Ordnerstruktur (app/core/..., app/db/...) existiert
from app.core.config import settings
from app.db.session import engine, Base
from app.routers import users
from app.routers import users, customers

# Modelle importieren, damit SQLAlchemy sie kennt
import app.models  # noqa: F401

# Tabellen erstellen (falls sie noch nicht existieren)
Base.metadata.create_all(bind=engine)

# App Initialisierung
app = FastAPI(title="Anviro Backend")

# --- CORS KONFIGURATION ---
# Wichtig, falls du das Spiel später als Web-Build veröffentlichst
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- GLOBALER FEHLER-HANDLER ---
# Fängt Abstürze ab und gibt sauberes JSON zurück
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=500,
        content={"detail": f"Interner Serverfehler: {exc}"},
    )

# --- ENDPUNKTE ---

# 1. Health-Check
# Diesen Endpunkt ruft dein Godot Loading-Screen auf!
# URL: http://127.0.0.1:8000/health
@app.get("/health")
def health_check():
    return {"status": "ok", "message": "Service is running"}

# 2. Root (Startseite)
# Optional: Damit du im Browser bei http://127.0.0.1:8000/ keinen 404 Fehler bekommst
@app.get("/")
def read_root():
    return {
        "message": "Welcome to Anviro Backend API",
        "docs": "/docs",
        "health_check": "/health"
    }

# 3. Router einbinden
# Hier sind deine Login und Register Funktionen drin
app.include_router(users.router)
app.include_router(customers.router)