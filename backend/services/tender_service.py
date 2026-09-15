from sqlalchemy.orm import Session, joinedload
from typing import List, Any, Dict
from datetime import datetime, timezone
from models.tender import Tender, TenderMaterial, TenderParticipant
from models.auction import Auction
from models.user import User
from schemas.tender import TenderCreate


REQUIRED_TENDER_FIELDS = [
    "title",
    "pickup_location",
    "drop_location",
    "bidding_start_time",
    "soft_end_time",
]

DRAFT = "DRAFT"
PUBLISHED = "PUBLISHED"
SCHEDULED = "SCHEDULED"


def _to_dict(data: Any) -> Dict[str, Any]:
    if data is None:
        return {}
    if isinstance(data, dict):
        return dict(data)
    if hasattr(data, "model_dump"):
        return data.model_dump(exclude_unset=True)
    if hasattr(data, "dict"):
        return data.dict(exclude_unset=True)
    return dict(data)


def _extract_materials(payload: Dict[str, Any]) -> List[Any]:
    return payload.pop("materials", []) or []


def _extract_participant_ids(payload: Dict[str, Any], raw: Any) -> List[int]:
    ids: List[int] = []
    candidates = []
    if "participant_ids" in payload:
        candidates = payload.pop("participant_ids", []) or []
    elif "transporter_ids" in payload:
        candidates = payload.pop("transporter_ids", []) or []
    elif "participants" in payload:
        candidates = payload.pop("participants", []) or []
    elif hasattr(raw, "participant_ids"):
        candidates = getattr(raw, "participant_ids") or []
    elif hasattr(raw, "participants"):
        candidates = getattr(raw, "participants") or []
    for item in candidates:
        if item is None:
            continue
        if isinstance(item, int):
            ids.append(item)
        elif isinstance(item, dict):
            tid = item.get("transporter_id", item.get("id", item.get("user_id")))
            if tid is not None:
                ids.append(int(tid))
        else:
            tid = getattr(item, "transporter_id", getattr(item, "id", getattr(item, "user_id", None)))
            if tid is not None:
                ids.append(int(tid))
    return ids


def _material_kwargs(item: Any) -> Dict[str, Any]:
    if isinstance(item, dict):
        return dict(item)
    if hasattr(item, "model_dump"):
        return item.model_dump()
    if hasattr(item, "dict"):
        return item.dict()
    return dict(item)


def _base_query(db: Session):
    return db.query(Tender).options(
        joinedload(Tender.materials),
        joinedload(Tender.participants),
    )


def create_tender(db: Session, creator_id: int, data: TenderCreate) -> Tender:
    payload = _to_dict(data)
    materials_data = _extract_materials(payload)
    participant_ids = _extract_participant_ids(payload, data)
    payload.pop("participants", None)
    payload.pop("transporter_ids", None)
    payload.pop("creator_id", None)
    payload.pop("id", None)
    if "status" not in payload or payload["status"] is None:
        payload["status"] = DRAFT
    tender = Tender(creator_id=creator_id, **payload)
    db.add(tender)
    db.flush()
    for item in materials_data:
        kwargs = _material_kwargs(item)
        kwargs.pop("id", None)
        kwargs.pop("tender_id", None)
        db.add(TenderMaterial(tender_id=tender.id, **kwargs))
    for tid in set(participant_ids):
        db.add(TenderParticipant(tender_id=tender.id, transporter_id=tid))
    db.commit()
    return get_tender_by_id(db, tender.id)


def update_tender(db: Session, tender_id: int, creator_id: int, data) -> Tender:
    tender = db.query(Tender).filter(Tender.id == tender_id).first()
    if not tender:
        raise LookupError(f"Tender {tender_id} not found")
    if tender.creator_id != creator_id:
        raise PermissionError("Only creator can update tender")
    if tender.status != DRAFT:
        raise ValueError("Only DRAFT tenders can be updated")
    payload = _to_dict(data)
    has_materials_key = any(k in payload or hasattr(data, k) for k in ["materials"])
    has_participants_key = any(k in payload or hasattr(data, k) for k in ["participants", "participant_ids", "transporter_ids"])
    materials_data = _extract_materials(payload) if "materials" in payload else (None if not has_materials_key else [])
    participant_ids = None
    if any(k in payload for k in ["participants", "participant_ids", "transporter_ids"]):
        participant_ids = _extract_participant_ids(payload, data)
    elif has_participants_key:
        participant_ids = _extract_participant_ids(payload, data)
    payload.pop("participants", None)
    payload.pop("participant_ids", None)
    payload.pop("transporter_ids", None)
    payload.pop("materials", None)
    payload.pop("id", None)
    payload.pop("creator_id", None)
    payload.pop("status", None)
    for key, value in payload.items():
        if hasattr(tender, key):
            setattr(tender, key, value)
    if materials_data is not None:
        db.query(TenderMaterial).filter(TenderMaterial.tender_id == tender.id).delete(synchronize_session=False)
        for item in materials_data:
            kwargs = _material_kwargs(item)
            kwargs.pop("id", None)
            kwargs.pop("tender_id", None)
            db.add(TenderMaterial(tender_id=tender.id, **kwargs))
    if participant_ids is not None:
        db.query(TenderParticipant).filter(TenderParticipant.tender_id == tender.id).delete(synchronize_session=False)
        for tid in set(participant_ids):
            db.add(TenderParticipant(tender_id=tender.id, transporter_id=tid))
    db.commit()
    return get_tender_by_id(db, tender.id)


def publish_tender(db: Session, tender_id: int, creator_id: int) -> Tender:
    tender = _base_query(db).filter(Tender.id == tender_id).first()
    if not tender:
        raise LookupError(f"Tender {tender_id} not found")
    if tender.creator_id != creator_id:
        raise PermissionError("Only creator can publish tender")
    if tender.status != DRAFT:
        raise ValueError("Only DRAFT tenders can be published")
    missing = [f for f in REQUIRED_TENDER_FIELDS if getattr(tender, f, None) in (None, "")]
    if missing:
        raise ValueError(f"Missing required fields for publish: {', '.join(missing)}")
    if not tender.materials or len(tender.materials) < 1:
        raise ValueError("At least 1 material is required to publish")
    if not tender.participants or len(tender.participants) < 1:
        raise ValueError("At least 1 participant is required to publish")
    if tender.bidding_start_time and tender.soft_end_time:
        if tender.soft_end_time <= tender.bidding_start_time:
            raise ValueError("soft_end_time must be after bidding_start_time")
    tender.status = PUBLISHED
    existing = db.query(Auction).filter(Auction.tender_id == tender.id).first()
    if not existing:
        auction = Auction(
            tender_id=tender.id,
            stage=1,
            status="SCHEDULED",
            start_time=tender.bidding_start_time,
            soft_end_time=tender.soft_end_time,
            hard_stop_time=tender.hard_stop_time,
            extension_minutes=5,
        )
        db.add(auction)
    db.commit()
    return get_tender_by_id(db, tender.id)


def get_tenders_for_user(db: Session, user_id: int) -> list:
    return (
        _base_query(db)
        .filter(Tender.creator_id == user_id)
        .order_by(Tender.id.desc())
        .all()
    )


def get_tenders_for_transporter(db: Session, transporter_id: int) -> list:
    return (
        _base_query(db)
        .join(TenderParticipant, TenderParticipant.tender_id == Tender.id)
        .filter(TenderParticipant.transporter_id == transporter_id)
        .filter(Tender.status != DRAFT)
        .order_by(Tender.id.desc())
        .all()
    )


def get_tender_by_id(db: Session, tender_id: int) -> Tender:
    tender = _base_query(db).filter(Tender.id == tender_id).first()
    if not tender:
        raise LookupError(f"Tender {tender_id} not found")
    return tender


def get_drafts(db: Session, user_id: int) -> list:
    return (
        _base_query(db)
        .filter(Tender.creator_id == user_id)
        .filter(Tender.status == DRAFT)
        .order_by(Tender.id.desc())
        .all()
    )


def get_approved_transporters(db: Session) -> list:
    return (
        db.query(User)
        .filter(User.role == "transporter")
        .filter(User.status == "approved")
        .order_by(User.id.asc())
        .all()
    )

def add_participant(db: Session, tender_id: int, transporter_id: int):
    existing = db.query(TenderParticipant).filter(
        TenderParticipant.tender_id == tender_id,
        TenderParticipant.transporter_id == transporter_id
    ).first()
    if not existing:
        p = TenderParticipant(tender_id=tender_id, transporter_id=transporter_id)
        db.add(p)
        db.commit()
        return p
    return existing
