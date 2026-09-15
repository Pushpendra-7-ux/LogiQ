from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models.user import User, TransporterProfile
from schemas.user import RegisterRequest, LoginRequest, TokenResponse, UserWithProfileResponse, TransporterProfileResponse
from middleware.auth_middleware import get_current_user
from utils.security import create_access_token, verify_password, hash_password

router = APIRouter(prefix="/auth", tags=["Authentication"])

@router.post("/register", status_code=status.HTTP_201_CREATED)
def register(data: RegisterRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == data.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    user = User(
        name=data.name,
        email=data.email,
        phone=data.phone,
        password_hash=hash_password(data.password),
        role=data.role,
        status="pending" if data.role != "admin" else "approved"
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    if data.role == "transporter":
        profile = TransporterProfile(
            user_id=user.id,
            company_name=data.company_name or data.name,
            company_email=data.company_email or data.email,
            whatsapp_phone=data.whatsapp_phone or data.phone or "",
            gst_number=data.gst_number or "PENDING",
            transport_id=data.transport_id or "PENDING"
        )
        db.add(profile)
        db.commit()

    return {"message": "Registration successful. Awaiting admin approval.", "user_id": user.id, "status": user.status}

@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")
    if user.status != "approved":
        if user.status == "pending":
            raise HTTPException(status_code=403, detail="Your account is pending admin approval.")
        raise HTTPException(status_code=403, detail="Your account has been rejected.")
    
    token = create_access_token(data={"sub": str(user.id), "role": user.role})
    profile_data = None
    if user.transporter_profile:
        tp = user.transporter_profile
        profile_data = TransporterProfileResponse(
            company_name=tp.company_name,
            company_email=tp.company_email,
            whatsapp_phone=tp.whatsapp_phone,
            gst_number=tp.gst_number,
            transport_id=tp.transport_id
        )
    
    user_resp = UserWithProfileResponse(
        id=user.id,
        name=user.name,
        email=user.email,
        phone=user.phone,
        role=user.role,
        status=user.status,
        created_at=user.created_at,
        transporter_profile=profile_data
    )
    return TokenResponse(access_token=token, token_type="bearer", user=user_resp)

@router.get("/me", response_model=UserWithProfileResponse)
def get_me(current_user: User = Depends(get_current_user)):
    profile_data = None
    if current_user.transporter_profile:
        tp = current_user.transporter_profile
        profile_data = TransporterProfileResponse(
            company_name=tp.company_name,
            company_email=tp.company_email,
            whatsapp_phone=tp.whatsapp_phone,
            gst_number=tp.gst_number,
            transport_id=tp.transport_id
        )
    return UserWithProfileResponse(
        id=current_user.id,
        name=current_user.name,
        email=current_user.email,
        phone=current_user.phone,
        role=current_user.role,
        status=current_user.status,
        created_at=current_user.created_at,
        transporter_profile=profile_data
    )
