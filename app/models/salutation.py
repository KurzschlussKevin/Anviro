from sqlalchemy import Column, SmallInteger, Text
from app.db.session import Base


class Salutation(Base):
    __tablename__ = "salutations"
    __table_args__ = {"schema": "anviro"}

    id = Column(SmallInteger, primary_key=True, index=True)
    name = Column(Text, nullable=False, unique=True)
