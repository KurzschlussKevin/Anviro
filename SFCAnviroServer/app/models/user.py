from sqlalchemy import (
    Column,
    BigInteger,
    SmallInteger,
    Text,
    DateTime,
    ForeignKey,
)
from sqlalchemy.orm import relationship  # <--- NEU: Wichtig für die Verknüpfung
from sqlalchemy.sql import func

from app.db.session import Base


class User(Base):
    __tablename__ = "users"
    __table_args__ = {"schema": "anviro"}

    id = Column(BigInteger, primary_key=True, index=True)

    salutation_id = Column(SmallInteger, ForeignKey("anviro.salutations.id"), nullable=True)
    role_id = Column(SmallInteger, ForeignKey("anviro.roles.id"), nullable=False)

    first_name = Column(Text, nullable=False)
    last_name = Column(Text, nullable=False)
    username = Column(Text, nullable=False, unique=True, index=True)
    email = Column(Text, nullable=False, unique=True, index=True)

    mobile_number = Column(Text, nullable=True)
    postal_code = Column(Text, nullable=True)
    city = Column(Text, nullable=True)
    house_number = Column(Text, nullable=True)
    street = Column(Text, nullable=True)

    password_hash = Column(Text, nullable=False)

    created_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    updated_at = Column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    
    logins = relationship("UserLogin", back_populates="user")