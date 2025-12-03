from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.db.session import get_db
from app.models.customer import Customer
from app.schemas.customer import CustomerOut, CustomerCreate
from app.routers.users import get_current_user_from_token # Auth-Schutz!

router = APIRouter(
    prefix="/customers",
    tags=["Customers"]
)

# GET: Alle Kunden laden
@router.get("/", response_model=List[CustomerOut])
def get_all_customers(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_from_token) # Nur eingeloggte User!
):
    customers = db.query(Customer).all()
    return customers

# POST: Kunde anlegen (Für Testzwecke, später macht das der Vertrieb)
@router.post("/", response_model=CustomerOut)
def create_customer(
    customer: CustomerCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_from_token)
):
    # Check ob Kundennummer schon existiert
    if db.query(Customer).filter(Customer.kundennummer == customer.kundennummer).first():
        raise HTTPException(status_code=400, detail="Kundennummer existiert bereits")
    
    new_customer = Customer(**customer.model_dump())
    db.add(new_customer)
    db.commit()
    db.refresh(new_customer)
    return new_customer