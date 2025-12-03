from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

class SalesItemBase(BaseModel):
    position_nr: Optional[str] = None
    bezeichnung: str
    gruppe: Optional[str] = None
    menge: float
    einzelpreis: float
    gesamt: float

class SalesItemCreate(SalesItemBase):
    pass

class SaleCreate(BaseModel):
    customer_id: int
    items: List[SalesItemCreate]

class SaleOut(BaseModel):
    id: int
    customer_id: int
    created_at: datetime
    items: List[SalesItemBase]

    class Config:
        from_attributes = True