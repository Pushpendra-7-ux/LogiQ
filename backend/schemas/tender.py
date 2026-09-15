from datetime import date, datetime

from pydantic import BaseModel, ConfigDict


class MaterialCreate(BaseModel):
    hsn_code: str | None = None
    description: str
    quantity: float
    unit: str
    remarks: str | None = None


class MaterialResponse(MaterialCreate):
    id: int
    tender_id: int

    model_config = ConfigDict(from_attributes=True)


class TenderCreate(BaseModel):
    title: str
    pickup_location: str
    drop_location: str
    delivery_start: date
    delivery_end: date
    tender_closing_date: datetime
    bidding_start_time: datetime
    soft_end_time: datetime
    hard_stop_time: datetime
    price_difference: float = 25.0
    materials: list[MaterialCreate] = []
    participant_ids: list[int] = []
    status: str = "DRAFT"


class TenderResponse(BaseModel):
    id: int
    creator_id: int
    title: str
    pickup_location: str
    drop_location: str
    delivery_start: date
    delivery_end: date
    tender_closing_date: datetime
    bidding_start_time: datetime
    soft_end_time: datetime
    hard_stop_time: datetime
    price_difference: float
    status: str
    materials: list[MaterialResponse] = []
    participant_count: int = 0
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ParticipantsAdd(BaseModel):
    transporter_ids: list[int]