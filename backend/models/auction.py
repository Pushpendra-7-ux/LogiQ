from datetime import datetime
from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from database import Base

class Auction(Base):
    __tablename__ = "auctions"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    tender_id = Column(Integer, ForeignKey("tenders.id"), nullable=False)
    stage = Column(Integer, nullable=False)
    status = Column(String(20), nullable=False, default="SCHEDULED")
    start_time = Column(DateTime, nullable=False)
    soft_end_time = Column(DateTime, nullable=False)
    hard_stop_time = Column(DateTime, nullable=False)
    extension_minutes = Column(Integer, nullable=False, default=5)
    created_at = Column(DateTime, default=datetime.utcnow)

    tender = relationship("Tender", back_populates="auctions")
    bids = relationship("Bid", back_populates="auction")

    @property
    def started_at(self):
        return self.start_time

    @started_at.setter
    def started_at(self, val):
        if val is not None:
            self.start_time = val

    @property
    def price_difference(self):
        return self.tender.price_difference if self.tender else 25.0

    @price_difference.setter
    def price_difference(self, val):
        pass

    @property
    def completed_at(self):
        return getattr(self, '_completed_at', None)

    @completed_at.setter
    def completed_at(self, val):
        self._completed_at = val
