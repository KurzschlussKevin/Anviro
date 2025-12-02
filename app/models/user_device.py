from sqlalchemy import Column, BigInteger, Text, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime, timezone, timedelta
import uuid

from app.db.session import Base


class UserDevice(Base):
    __tablename__ = "user_devices"
    __table_args__ = {"schema": "anviro"}

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("anviro.users.id", ondelete="CASCADE"), nullable=False)
    device_uuid = Column(UUID(as_uuid=True), nullable=False, unique=True, default=uuid.uuid4)
    device_name = Column(Text, nullable=True)
    platform = Column(Text, nullable=True)
    last_login_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    trusted_until = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc) + timedelta(days=30))
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    revoked_at = Column(DateTime(timezone=True), nullable=True)
