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

# --- 1. ALLE KUNDEN LADEN (GET) ---
@router.get("/", response_model=List[CustomerOut])
def get_all_customers(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_from_token) # Nur eingeloggte User!
):
    customers = db.query(Customer).all()
    return customers

# --- 2. KUNDE ANLEGEN (POST) ---
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

# --- 3. KUNDE BEARBEITEN (PUT) ---
@router.put("/{customer_id}", response_model=CustomerOut)
def update_customer(
    customer_id: int,
    customer_data: CustomerCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_from_token)
):
    # Zu bearbeitenden Kunden suchen
    db_customer = db.query(Customer).filter(Customer.id == customer_id).first()
    
    if not db_customer:
        raise HTTPException(status_code=404, detail="Kunde nicht gefunden")
    
    # Prüfen, ob die neue Kundennummer schon von JEMAND ANDEREM verwendet wird
    existing_number = db.query(Customer).filter(
        Customer.kundennummer == customer_data.kundennummer,
        Customer.id != customer_id # Nicht wir selbst!
    ).first()
    
    if existing_number:
        raise HTTPException(status_code=400, detail="Diese Kundennummer ist bereits vergeben.")

    # Daten aktualisieren
    # Wir iterieren durch alle Felder im Schema und setzen sie im Datenbank-Objekt
    update_data = customer_data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_customer, key, value)

    db.commit()
    db.refresh(db_customer)
    return db_customer

# --- 4. KUNDE LÖSCHEN (DELETE) ---
@router.delete("/{customer_id}")
def delete_customer(
    customer_id: int,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_from_token)
):
    # Kunden suchen
    db_customer = db.query(Customer).filter(Customer.id == customer_id).first()
    
    if not db_customer:
        raise HTTPException(status_code=404, detail="Kunde nicht gefunden")
    
    # Löschen
    db.delete(db_customer)
    db.commit()
    
    return {"msg": "Kunde erfolgreich gelöscht", "id": customer_id}