from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), nullable=False, unique=True, index=True)
    phone = Column(String(20), nullable=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(20), nullable=False)
    status = Column(String(20), nullable=False, default="pending")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=True, onupdate=datetime.utcnow)

    transporter_profile = relationship(
        "TransporterProfile",
        back_populates="user",
        uselist=False,
    )


class TransporterProfile(Base):
    __tablename__ = "transporter_profiles"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    company_name = Column(String(200), nullable=False)
    company_email = Column(String(255), nullable=False)
    whatsapp_phone = Column(String(20), nullable=False)
    gst_number = Column(String(15), nullable=False)
    transport_id = Column(String(50), nullable=False)

    user = relationship("User", back_populates="transporter_profile")