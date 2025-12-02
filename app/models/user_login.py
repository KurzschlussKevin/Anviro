from sqlalchemy import Column, BigInteger, Text, Boolean, ForeignKey, DateTime, String
from sqlalchemy.dialects.postgresql import INET
from sqlalchemy.orm import relationship # <--- WICHTIG für Verknüpfung
from datetime import datetime, timezone

from app.db.session import Base

class UserLogin(Base):
    __tablename__ = "user_logins"
    __table_args__ = {"schema": "anviro"}

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("anviro.users.id"), nullable=True)
    
    login_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    ip_address = Column(INET, nullable=True)
    user_agent = Column(Text, nullable=True)
    hold_login = Column(Boolean, nullable=False, default=False)

    # --- NEU HINZUGEFÜGT ---
    
    # Hier speichern wir das JWT Token (als String). 
    # index=True macht die Suche bei der Validierung extrem schnell.
    token = Column(String, index=True, nullable=True) 

    # Damit können wir Tokens ungültig machen, ohne den Datensatz zu löschen (Logout).
    is_active = Column(Boolean, nullable=False, default=True)

    # Optional: Rückverknüpfung zum User-Objekt, damit du z.B. login.user.email abrufen kannst
    user = relationship("User", back_populates="logins")