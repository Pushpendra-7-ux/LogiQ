from datetime import datetime
from sqlalchemy import (
    Column,
    Date,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import relationship
from database import Base

class Tender(Base):
    __tablename__ = "tenders"

    id = Column(Integer, primary_key=True, index=True)
    creator_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    title = Column(String(200), nullable=False)
    pickup_location = Column(String(200), nullable=False)
    drop_location = Column(String(200), nullable=False)

    delivery_start = Column(Date, nullable=False)
    delivery_end = Column(Date, nullable=False)
    tender_closing_date = Column(DateTime, nullable=False)

    bidding_start_time = Column(DateTime, nullable=False)
    soft_end_time = Column(DateTime, nullable=False)
    hard_stop_time = Column(DateTime, nullable=False)

    price_difference = Column(Float, nullable=False, default=25.0)
    status = Column(String(30), nullable=False, default="DRAFT")

    created_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    updated_at = Column(DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    materials = relationship(
        "Material",
        back_populates="tender",
        cascade="all, delete-orphan",
    )

    participants = relationship(
        "TenderParticipant",
        back_populates="tender",
        cascade="all, delete-orphan",
    )

    auctions = relationship(
        "Auction",
        back_populates="tender",
        cascade="all, delete-orphan",
    )

class Material(Base):
    __tablename__ = "materials"

    id = Column(Integer, primary_key=True, index=True)
    tender_id = Column(Integer, ForeignKey("tenders.id"), nullable=False, index=True)

    hsn_code = Column(String(20), nullable=True)
    description = Column(String(200), nullable=False)

    quantity = Column(Float, nullable=False)
    unit = Column(String(20), nullable=False)
    remarks = Column(Text, nullable=True)

    tender = relationship("Tender", back_populates="materials")

class TenderParticipant(Base):
    __tablename__ = "tender_participants"
    __table_args__ = (
        UniqueConstraint("tender_id", "transporter_id", name="uq_tender_participant"),
    )

    id = Column(Integer, primary_key=True, index=True)
    tender_id = Column(Integer, ForeignKey("tenders.id"), nullable=False, index=True)
    transporter_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)

    invited_at = Column(DateTime, nullable=False, default=datetime.utcnow)
    status = Column(String(20), nullable=False, default="invited")

    tender = relationship("Tender", back_populates="participants")
    transporter = relationship("User")

    @property
    def transporter_name(self):
        if self.transporter:
            if hasattr(self.transporter, 'transporter_profile') and self.transporter.transporter_profile and self.transporter.transporter_profile.company_name:
                return self.transporter.transporter_profile.company_name
            return self.transporter.name
        return f"Transporter {self.transporter_id}"

TenderMaterial = Material
