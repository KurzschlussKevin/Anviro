from sqlalchemy import Column, BigInteger, Text, Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.db.session import Base

class Sale(Base):
    __tablename__ = "sales"
    __table_args__ = {"schema": "anviro"}

    id = Column(BigInteger, primary_key=True, index=True)
    customer_id = Column(BigInteger, ForeignKey("anviro.customers.id"), nullable=False)
    user_id = Column(BigInteger, ForeignKey("anviro.users.id"), nullable=False) # Wer hat verkauft?
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Verknüpfung zu den Positionen
    items = relationship("SalesItem", back_populates="sale", cascade="all, delete-orphan")

class SalesItem(Base):
    __tablename__ = "sales_items"
    __table_args__ = {"schema": "anviro"}

    id = Column(BigInteger, primary_key=True, index=True)
    sale_id = Column(BigInteger, ForeignKey("anviro.sales.id"), nullable=False)
    
    position_nr = Column(Text, nullable=True) # z.B. "001"
    bezeichnung = Column(Text, nullable=False)
    gruppe = Column(Text, nullable=True) # A, B, C...
    menge = Column(Float, default=0.0)
    einzelpreis = Column(Float, default=0.0)
    gesamt = Column(Float, default=0.0)
    
    sale = relationship("Sale", back_populates="items")