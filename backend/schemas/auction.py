from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class AuctionStatusResponse(BaseModel):
    tender_id: int = Field(..., ge=1)
    stage: int = Field(..., ge=0)
    status: str = Field(..., min_length=1)
    start_time: datetime
    soft_end_time: datetime
    hard_stop_time: datetime
    remaining_seconds: float = Field(..., ge=0)
    server_time: datetime

    model_config = ConfigDict(from_attributes=True)