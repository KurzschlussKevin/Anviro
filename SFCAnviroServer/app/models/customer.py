from sqlalchemy import Column, BigInteger, Text, Integer, DateTime, ForeignKey
from sqlalchemy.sql import func
from app.db.session import Base

class Customer(Base):
    __tablename__ = "customers"
    __table_args__ = {"schema": "anviro"}

    id = Column(BigInteger, primary_key=True, index=True)
    
    # Basisdaten
    kundennummer = Column(Text, unique=True, index=True, nullable=False)
    vorname = Column(Text, nullable=False)
    nachname = Column(Text, nullable=False)
    email = Column(Text, nullable=True)
    telefon = Column(Text, nullable=True)
    
    # Adresse
    strasse = Column(Text, nullable=True)
    hausnummer = Column(Text, nullable=True)
    plz = Column(Text, nullable=True)
    stadt = Column(Text, nullable=True)
    
    # Status (1=Aktiv, 2=Gesperrt, etc.) - FK zu status Tabelle optional
    status_id = Column(Integer, default=1) 

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())