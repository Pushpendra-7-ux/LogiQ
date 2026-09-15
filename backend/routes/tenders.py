from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models.user import User
from models.tender import Tender
from schemas.tender import TenderCreate, TenderResponse, ParticipantsAdd
from middleware.auth_middleware import get_current_user, role_required
import services.tender_service as tender_service

router = APIRouter(prefix="/tenders", tags=["Tenders"])

@router.get("/drafts/list")
def get_drafts(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    tenders = tender_service.get_drafts(db, current_user.id)
    return {"tenders": tenders}

@router.get("/history/list")
def get_history(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role == "user":
        tenders = db.query(Tender).filter(Tender.creator_id == current_user.id, Tender.status.in_(["COMPLETED", "WINNER_FINALIZED"])).all()
    elif current_user.role == "transporter":
        tenders = tender_service.get_tenders_for_transporter(db, current_user.id)
        tenders = [t for t in tenders if t.status in ["COMPLETED", "WINNER_FINALIZED"]]
    else:
        tenders = db.query(Tender).filter(Tender.status.in_(["COMPLETED", "WINNER_FINALIZED"])).all()
    return {"tenders": tenders}

@router.get("/transporters/approved")
def get_approved_transporters(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    transporters = tender_service.get_approved_transporters(db)
    res = []
    for t in transporters:
        res.append({
            "id": t.id,
            "name": t.name,
            "email": t.email,
            "company_name": t.transporter_profile.company_name if t.transporter_profile else t.name,
            "gst_number": t.transporter_profile.gst_number if t.transporter_profile else "N/A",
            "transport_id": t.transporter_profile.transport_id if t.transporter_profile else "N/A",
        })
    return {"transporters": res}

@router.get("")
def get_tenders(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role == "user":
        tenders = tender_service.get_tenders_for_user(db, current_user.id)
    elif current_user.role == "transporter":
        tenders = tender_service.get_tenders_for_transporter(db, current_user.id)
    else:
        tenders = db.query(Tender).all()
    return {"tenders": tenders}

@router.post("", status_code=status.HTTP_201_CREATED)
def create_tender(data: TenderCreate, db: Session = Depends(get_db), current_user: User = Depends(role_required("user"))):
    tender = tender_service.create_tender(db, current_user.id, data)
    return tender

@router.get("/{tender_id}")
def get_tender(tender_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    tender = tender_service.get_tender_by_id(db, tender_id)
    if not tender:
        raise HTTPException(status_code=404, detail="Tender not found")
    return tender

@router.put("/{tender_id}")
def update_tender(tender_id: int, data: TenderCreate, db: Session = Depends(get_db), current_user: User = Depends(role_required("user"))):
    tender = tender_service.update_tender(db, tender_id, current_user.id, data)
    return tender

@router.post("/{tender_id}/publish")
def publish_tender(tender_id: int, db: Session = Depends(get_db), current_user: User = Depends(role_required("user"))):
    tender = tender_service.publish_tender(db, tender_id, current_user.id)
    return {"message": "Tender published successfully.", "tender_id": tender.id, "status": tender.status}

@router.post("/{tender_id}/participants")
def add_participants(tender_id: int, data: ParticipantsAdd, db: Session = Depends(get_db), current_user: User = Depends(role_required("user"))):
    tender = tender_service.get_tender_by_id(db, tender_id)
    if not tender or tender.creator_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this tender")
    for tid in data.transporter_ids:
        tender_service.add_participant(db, tender_id, tid)
    return {"message": "Participants added successfully"}

@router.get("/{tender_id}/participants")
def get_participants(tender_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    tender = tender_service.get_tender_by_id(db, tender_id)
    if not tender:
        raise HTTPException(status_code=404, detail="Tender not found")
    return {"participants": [p.transporter for p in tender.participants]}
