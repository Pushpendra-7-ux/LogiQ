from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from database import get_db
from models.user import User, TransporterProfile
from models.tender import Tender
from models.auction import Auction
from middleware.auth_middleware import role_required

router = APIRouter(prefix="/admin", tags=["Admin"])

@router.get("/pending-users")
def get_pending_users(db: Session = Depends(get_db), current_user: User = Depends(role_required("admin"))):
    pending_users = db.query(User).filter(User.role == "user", User.status == "pending").all()
    pending_transporters = db.query(User).filter(User.role == "transporter", User.status == "pending").all()
    
    return {
        "pending_users": [
            {
                "id": u.id,
                "name": u.name,
                "email": u.email,
                "phone": u.phone,
                "role": u.role,
                "status": u.status,
                "created_at": u.created_at.isoformat() if u.created_at else None
            }
            for u in pending_users
        ],
        "pending_transporters": [
            {
                "id": t.id,
                "name": t.name,
                "company_name": t.transporter_profile.company_name if t.transporter_profile else t.name,
                "email": t.email,
                "phone": t.phone,
                "gst_number": t.transporter_profile.gst_number if t.transporter_profile else "N/A",
                "transport_id": t.transporter_profile.transport_id if t.transporter_profile else "N/A",
                "role": t.role,
                "status": t.status,
                "created_at": t.created_at.isoformat() if t.created_at else None
            }
            for t in pending_transporters
        ]
    }

@router.post("/approve/{user_id}")
def approve_user(user_id: int, db: Session = Depends(get_db), current_user: User = Depends(role_required("admin"))):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.status = "approved"
    db.commit()
    return {"message": f"User {user.email} approved successfully", "user_id": user.id, "status": "approved"}

@router.post("/reject/{user_id}")
def reject_user(user_id: int, db: Session = Depends(get_db), current_user: User = Depends(role_required("admin"))):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.status = "rejected"
    db.commit()
    return {"message": f"User {user.email} rejected", "user_id": user.id, "status": "rejected"}

@router.get("/dashboard")
def get_dashboard_stats(db: Session = Depends(get_db), current_user: User = Depends(role_required("admin"))):
    total_users = db.query(func.count(User.id)).filter(User.role == "user").scalar() or 0
    total_transporters = db.query(func.count(User.id)).filter(User.role == "transporter").scalar() or 0
    pending_count = db.query(func.count(User.id)).filter(User.status == "pending").scalar() or 0
    active_tenders = db.query(func.count(Tender.id)).filter(Tender.status.like("%LIVE%")).scalar() or 0
    completed_auctions = db.query(func.count(Auction.id)).filter(Auction.status == "COMPLETED").scalar() or 0

    return {
        "total_users": total_users,
        "total_transporters": total_transporters,
        "pending_count": pending_count,
        "active_tenders": active_tenders,
        "completed_auctions": completed_auctions
    }

@router.get("/users")
def get_all_users(db: Session = Depends(get_db), current_user: User = Depends(role_required("admin"))):
    users = db.query(User).filter(User.role == "user").all()
    return users

@router.get("/transporters")
def get_all_transporters(db: Session = Depends(get_db), current_user: User = Depends(role_required("admin"))):
    transporters = db.query(User).filter(User.role == "transporter").all()
    return transporters

@router.get("/tenders")
def get_all_tenders(db: Session = Depends(get_db), current_user: User = Depends(role_required("admin"))):
    return db.query(Tender).all()
