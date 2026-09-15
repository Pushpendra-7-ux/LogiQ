from sqlalchemy.orm import Session
from fastapi import HTTPException, status
from models import User, TransporterProfile, Tender, Auction
from schemas import RegisterRequest
from utils.security import get_password_hash, verify_password


def register_user(db: Session, data: RegisterRequest) -> User:
    existing = db.query(User).filter(User.email == data.email).first()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")
    hashed = get_password_hash(data.password)
    role = getattr(data, "role", "user")
    user_status = "approved" if role == "admin" else "pending"
    user = User(
        email=data.email,
        hashed_password=hashed,
        role=role,
        status=user_status,
    )
    for field in ("name", "full_name", "username", "phone", "company_name", "address"):
        if hasattr(data, field) and hasattr(user, field):
            setattr(user, field, getattr(data, field))
    db.add(user)
    db.commit()
    db.refresh(user)
    if user.role == "transporter":
        profile = TransporterProfile(user_id=user.id)
        for field in ("company_name", "company", "phone", "address", "vehicle_number", "vehicle_type", "license_number"):
            if hasattr(data, field) and hasattr(profile, field):
                setattr(profile, field, getattr(data, field))
        db.add(profile)
        db.commit()
    return user


def authenticate_user(db: Session, email: str, password: str) -> User | None:
    user = db.query(User).filter(User.email == email).first()
    if not user:
        return None
    stored = getattr(user, "hashed_password", None)
    if stored is None:
        stored = getattr(user, "password_hash", None)
    if not stored or not verify_password(password, stored):
        return None
    return user


def get_pending_users(db: Session) -> tuple[list, list]:
    pending_users = db.query(User).filter(User.status == "pending", User.role != "transporter").all()
    pending_transporters = db.query(User).filter(User.status == "pending", User.role == "transporter").all()
    return pending_users, pending_transporters


def approve_user(db: Session, user_id: int) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    user.status = "approved"
    db.commit()
    db.refresh(user)
    return user


def reject_user(db: Session, user_id: int) -> User:
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    user.status = "rejected"
    db.commit()
    db.refresh(user)
    return user


def get_dashboard_stats(db: Session) -> dict:
    pending = db.query(User).filter(User.status == "pending").count()
    total_users = db.query(User).count()
    total_transporters = db.query(User).filter(User.role == "transporter").count()
    active_tenders = db.query(Tender).filter(Tender.status == "active").count()
    completed_auctions = db.query(Auction).filter(Auction.status == "completed").count()
    return {
        "pending": pending,
        "total_users": total_users,
        "total_transporters": total_transporters,
        "active_tenders": active_tenders,
        "completed_auctions": completed_auctions,
    }
