from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class RegisterRequest(BaseModel):
    name: str
    email: str
    phone: str | None = None
    password: str = Field(min_length=6)
    role: str
    company_name: str | None = None
    company_email: str | None = None
    whatsapp_phone: str | None = None
    gst_number: str | None = None
    transport_id: str | None = None

class LoginRequest(BaseModel):
    email: str
    password: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    phone: str | None = None
    role: str
    status: str
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class TransporterProfileResponse(BaseModel):
    company_name: str
    company_email: str
    whatsapp_phone: str
    gst_number: str
    transport_id: str
    model_config = ConfigDict(from_attributes=True)

class UserWithProfileResponse(UserResponse):
    transporter_profile: TransporterProfileResponse | None = None

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserWithProfileResponse

class MessageResponse(BaseModel):
    message: str
