from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class CustomerBase(BaseModel):
    kundennummer: str
    vorname: str
    nachname: str
    email: Optional[EmailStr] = None
    telefon: Optional[str] = None
    mobile: Optional[str] = None
    strasse: Optional[str] = None
    hausnummer: Optional[str] = None
    plz: Optional[str] = None
    stadt: Optional[str] = None
    status_id: int = 1

class CustomerCreate(CustomerBase):
    pass

class CustomerOut(CustomerBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True