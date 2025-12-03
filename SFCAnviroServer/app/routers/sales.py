from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.db.session import get_db
from app.models.sales import Sale, SalesItem
from app.schemas.sales import SaleCreate, SaleOut
from app.routers.users import get_current_user_from_token

router = APIRouter(prefix="/sales", tags=["Sales"])

@router.post("/", response_model=SaleOut)
def create_sale(
    sale_data: SaleCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user_from_token)
):
    # 1. Auftragskopf erstellen
    new_sale = Sale(
        customer_id=sale_data.customer_id,
        user_id=current_user.id
    )
    db.add(new_sale)
    db.commit()
    db.refresh(new_sale)
    
    # 2. Positionen hinzufügen
    for item in sale_data.items:
        new_item = SalesItem(
            sale_id=new_sale.id,
            **item.model_dump()
        )
        db.add(new_item)
    
    db.commit()
    db.refresh(new_sale)
    return new_sale