from datetime import datetime
from sqlalchemy import Column, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from database import Base

class Bid(Base):
    __tablename__ = "bids"

    id = Column(Integer, primary_key=True, index=True)
    auction_id = Column(Integer, ForeignKey("auctions.id"), nullable=False)
    transporter_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    stage = Column(Integer, nullable=False)
    amount = Column(Float, nullable=False)
    submitted_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    status = Column(String(20), default="valid", nullable=False)

    auction = relationship("Auction", back_populates="bids")
    transporter = relationship("User")

class AuctionResult(Base):
    __tablename__ = "auction_results"

    id = Column(Integer, primary_key=True, index=True)
    auction_id = Column(Integer, ForeignKey("auctions.id"), nullable=False)
    tender_id = Column(Integer, ForeignKey("tenders.id"), nullable=False)
    winner_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    winning_bid = Column(Float, nullable=False)
    stage = Column(Integer, nullable=False, default=2)
    finalized_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    auction = relationship("Auction")
    tender = relationship("Tender")
    winner = relationship("User")

    @property
    def winner_transporter_id(self):
        return self.winner_id

    @winner_transporter_id.setter
    def winner_transporter_id(self, val):
        self.winner_id = val

    @property
    def winning_amount(self):
        return self.winning_bid

    @winning_amount.setter
    def winning_amount(self, val):
        self.winning_bid = val

    @property
    def winning_bid_id(self):
        return getattr(self, '_winning_bid_id', None)

    @winning_bid_id.setter
    def winning_bid_id(self, val):
        self._winning_bid_id = val

    @property
    def decided_at(self):
        return self.finalized_at

    @decided_at.setter
    def decided_at(self, val):
        self.finalized_at = val
