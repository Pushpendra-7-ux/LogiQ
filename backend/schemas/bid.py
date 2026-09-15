from datetime import datetime

from pydantic import BaseModel


class BidCreate(BaseModel):
    amount: float
    stage: int


class BidResponse(BaseModel):
    message: str
    bid_id: int
    amount: float
    your_rank: str | None = None
    current_l1: float | None = None


class RankingEntry(BaseModel):
    rank: str
    transporter_id: int
    transporter_name: str
    amount: float


class RankingResponse(BaseModel):
    rankings: list[RankingEntry]
    your_rank: str | None = None
    your_bid: float | None = None
    current_l1: float | None = None
    minimum_valid_bid: float | None = None
    remaining_seconds: float
    server_time: datetime


class ResultResponse(BaseModel):
    tender_id: int
    winner_name: str
    winner_company: str | None = None
    winning_bid: float
    stage: int
    finalized_at: datetime