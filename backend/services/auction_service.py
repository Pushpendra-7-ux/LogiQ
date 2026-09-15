import os
from datetime import datetime, timedelta, timezone
from fastapi import HTTPException
from sqlalchemy.orm import Session

from models import User, Tender, Auction, Bid, Participant, AuctionResult


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _utcnow() -> datetime:
    return datetime.now(timezone.utc)


def _as_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _get_tender(db: Session, tender_id) -> Tender:
    tender = db.query(Tender).filter(Tender.id == tender_id).first()
    if not tender:
        raise HTTPException(status_code=404, detail="Tender not found")
    return tender


def _get_auction(db: Session, tender_id, stage: int) -> Auction:
    auction = (
        db.query(Auction)
        .filter(Auction.tender_id == tender_id, Auction.stage == stage)
        .first()
    )
    if not auction:
        raise HTTPException(
            status_code=404,
            detail=f"Stage {stage} auction not found for this tender",
        )
    return auction


def _valid_bids(db: Session, auction_id) -> list[Bid]:
    return (
        db.query(Bid)
        .filter(Bid.auction_id == auction_id, Bid.status == "valid")
        .all()
    )


# ---------------------------------------------------------------------------
# Stage 1 lifecycle
# ---------------------------------------------------------------------------

def start_stage1(db: Session, tender_id) -> Auction:
    tender = _get_tender(db, tender_id)

    if tender.status not in ("BIDDING_OPEN", "PUBLISHED", "READY"):
        raise HTTPException(
            status_code=400,
            detail=f"Cannot start Stage 1 auction from tender status '{tender.status}'",
        )

    auction = _get_auction(db, tender_id, stage=1)
    if auction.status not in ("SCHEDULED", "PENDING"):
        raise HTTPException(
            status_code=400,
            detail=f"Stage 1 auction is already '{auction.status}'",
        )

    now = _utcnow()
    auction.status = "LIVE"
    auction.started_at = now
    tender.status = "STAGE_1_LIVE"

    db.commit()
    db.refresh(auction)
    return auction


def get_auction_status(db: Session, tender_id) -> dict:
    tender = _get_tender(db, tender_id)

    stage = 1 if "STAGE_1" in (tender.status or "") else 2
    if tender.status in ("TOP_5_SELECTED", "STAGE_2_SCHEDULED"):
        stage = 2
    if tender.status in ("WINNER_FINALIZED", "COMPLETED"):
        stage = 2

    auction = _get_auction(db, tender_id, stage)
    now = _utcnow()
    soft_end = _as_utc(auction.soft_end_time)
    hard_stop = _as_utc(auction.hard_stop_time)

    if auction.status in ("LIVE", "EXTENDED"):
        remaining = max(0, int((soft_end - now).total_seconds()))
    else:
        remaining = 0

    if auction.stage == 1:
        current_l1 = get_current_l1(db, auction.id)
        price_difference = float(auction.price_difference or 0.0)
        minimum_valid_bid = (current_l1 - price_difference) if current_l1 is not None else None
    else:
        current_l1 = None
        minimum_valid_bid = None
        price_difference = None

    start_val = auction.start_time or auction.started_at or now
    start_str = start_val.isoformat() if hasattr(start_val, 'isoformat') else str(start_val)
    soft_str = auction.soft_end_time.isoformat() if hasattr(auction.soft_end_time, 'isoformat') else str(auction.soft_end_time)
    hard_str = auction.hard_stop_time.isoformat() if hasattr(auction.hard_stop_time, 'isoformat') else str(auction.hard_stop_time)

    return {
        "tender_id": tender_id,
        "stage": auction.stage,
        "status": auction.status,
        "tender_status": tender.status,
        "start_time": start_str,
        "started_at": start_str,
        "soft_end_time": soft_str,
        "hard_stop_time": hard_str,
        "remaining_seconds": remaining,
        "server_time": now.isoformat(),
        "current_l1": current_l1,
        "minimum_valid_bid": minimum_valid_bid,
        "price_difference": price_difference,
    }


# ---------------------------------------------------------------------------
# Ranking
# ---------------------------------------------------------------------------

def get_current_l1(db: Session, auction_id) -> float | None:
    bid = (
        db.query(Bid)
        .filter(Bid.auction_id == auction_id, Bid.status == "valid")
        .order_by(Bid.amount.asc(), Bid.submitted_at.asc())
        .first()
    )
    return float(bid.amount) if bid else None


def recalculate_ranking(db: Session, auction_id) -> list[dict]:
    bids = _valid_bids(db, auction_id)
    if not bids:
        return []

    latest_by_transporter: dict = {}
    for bid in bids:
        existing = latest_by_transporter.get(bid.transporter_id)
        if existing is None or bid.submitted_at > existing.submitted_at:
            latest_by_transporter[bid.transporter_id] = bid

    ranked = sorted(
        latest_by_transporter.values(),
        key=lambda b: (b.amount, b.submitted_at),
    )

    _auc = db.query(Auction).filter(Auction.id == auction_id).first()
    _t_id = _auc.tender_id if _auc else None
    participant_names = {
        p.transporter_id: p.transporter_name
        for p in db.query(Participant)
        .filter(Participant.tender_id == _t_id)
        .all()
    }

    result = []
    for idx, bid in enumerate(ranked, start=1):
        result.append(
            {
                "rank": f"L{idx}",
                "transporter_id": bid.transporter_id,
                "transporter_name": participant_names.get(
                    bid.transporter_id, bid.transporter_id
                ),
                "amount": float(bid.amount),
            }
        )
    return result


def check_soft_end(db: Session, auction: Auction, bid_time: datetime) -> bool:
    bid_time = _as_utc(bid_time)
    soft_end = _as_utc(auction.soft_end_time)
    hard_stop = _as_utc(auction.hard_stop_time)
    extension = timedelta(minutes=auction.extension_minutes or 0)

    if extension <= timedelta(0):
        return False

    if bid_time >= soft_end - extension and bid_time < soft_end:
        new_soft_end = soft_end + extension
        if new_soft_end > hard_stop:
            new_soft_end = hard_stop
        if new_soft_end > soft_end:
            auction.soft_end_time = new_soft_end
            auction.status = "EXTENDED"
            db.commit()
            return True
    return False


# ---------------------------------------------------------------------------
# Bid submission
# ---------------------------------------------------------------------------

def validate_and_submit_bid(
    db: Session, tender_id, transporter_id, amount, stage: int
) -> dict:
    tender = _get_tender(db, tender_id)
    auction = _get_auction(db, tender_id, stage)

    # 2. Auction must be live
    if auction.status not in ("LIVE", "EXTENDED"):
        raise HTTPException(
            status_code=400,
            detail=f"Auction is not active (current status: {auction.status})",
        )

    # 3. Time window check
    now = _utcnow()
    if now >= _as_utc(auction.soft_end_time):
        raise HTTPException(
            status_code=400,
            detail="Bidding window has closed for this auction",
        )

    # 4. Participant check
    participant = (
        db.query(Participant)
        .filter(
            Participant.tender_id == auction.tender_id,
            Participant.transporter_id == transporter_id,
        )
        .first()
    )
    if not participant:
        raise HTTPException(
            status_code=403,
            detail="You are not a participant in this auction",
        )

    # 5. Stage 2 eligibility
    if stage == 2 and participant.status != "stage2":
        raise HTTPException(
            status_code=403,
            detail="You are not eligible to bid in Stage 2",
        )

    # 6. Amount sanity
    try:
        amount = float(amount)
    except (TypeError, ValueError):
        raise HTTPException(status_code=400, detail="Invalid bid amount")
    if amount <= 0:
        raise HTTPException(
            status_code=400, detail="Bid amount must be greater than 0"
        )

    # 7. Stage 1 price rule
    if stage == 1:
        current_l1 = get_current_l1(db, auction.id)
        if current_l1 is not None:
            min_allowed = current_l1 - (auction.price_difference or 0)
            if amount > min_allowed:
                raise HTTPException(
                    status_code=400,
                    detail=(
                        f"Bid must be at most {min_allowed:.2f} "
                        f"(current L1 is {current_l1:.2f}, "
                        f"price difference is {auction.price_difference})"
                    ),
                )

    # 8. Save bid
    bid = Bid(
        auction_id=auction.id,
        transporter_id=transporter_id,
        amount=amount,
        status="valid",
        stage=stage,
        submitted_at=now,
    )
    db.add(bid)
    db.flush()

    extended = False
    ranking = []

    if stage == 1:
        # 9. Supersede previous bids by this transporter
        db.query(Bid).filter(
            Bid.auction_id == auction.id,
            Bid.transporter_id == transporter_id,
            Bid.id != bid.id,
            Bid.status == "valid",
        ).update({"status": "superseded"}, synchronize_session=False)

        ranking = recalculate_ranking(db, auction.id)
        extended = check_soft_end(db, auction, now)

    db.commit()
    db.refresh(bid)

    result = {
        "bid_id": bid.id,
        "tender_id": tender_id,
        "stage": stage,
        "transporter_id": transporter_id,
        "amount": amount,
        "submitted_at": bid.submitted_at,
        "status": bid.status,
        "soft_end_extended": extended,
        "soft_end_time": auction.soft_end_time,
    }
    if stage == 1:
        my_rank = next(
            (
                r for r in ranking
                if r["transporter_id"] == transporter_id
            ),
            None,
        )
        result["ranking"] = ranking
        result["your_rank"] = my_rank["rank"] if my_rank else None
        result["current_l1"] = ranking[0]["amount"] if ranking else amount

    return result


# ---------------------------------------------------------------------------
# Stage 1 completion
# ---------------------------------------------------------------------------

def complete_stage1(db: Session, tender_id) -> dict:
    tender = _get_tender(db, tender_id)
    auction = _get_auction(db, tender_id, stage=1)

    if auction.status not in ("LIVE", "EXTENDED"):
        raise HTTPException(
            status_code=400,
            detail=f"Stage 1 auction is not active (status: {auction.status})",
        )

    now = _utcnow()
    auction.status = "COMPLETED"
    auction.completed_at = now
    tender.status = "STAGE_1_COMPLETED"

    ranking = recalculate_ranking(db, auction.id)
    top5 = ranking[:5]
    top5_ids = {entry["transporter_id"] for entry in top5}

    participants = (
        db.query(Participant)
        .filter(Participant.tender_id == auction.tender_id)
        .all()
    )
    for p in participants:
        p.status = "stage2" if p.transporter_id in top5_ids else "eliminated"

    db.commit()

    tender.status = "TOP_5_SELECTED"

    stage2_auction = Auction(
        tender_id=tender_id,
        stage=2,
        status="SCHEDULED",
        start_time=now,
        soft_end_time=_as_utc(auction.soft_end_time) + timedelta(days=1),
        hard_stop_time=_as_utc(auction.hard_stop_time) + timedelta(days=1),
        extension_minutes=auction.extension_minutes,
    )
    db.add(stage2_auction)
    db.commit()
    db.refresh(stage2_auction)

    tender.status = "STAGE_2_SCHEDULED"
    db.commit()

    return {"top_5": top5, "stage2_auction_id": stage2_auction.id}


# ---------------------------------------------------------------------------
# Stage 2 lifecycle
# ---------------------------------------------------------------------------

def start_stage2(db: Session, tender_id) -> Auction:
    tender = _get_tender(db, tender_id)

    if tender.status not in ("STAGE_2_SCHEDULED", "STAGE_1_COMPLETED", "TOP_5_SELECTED"):
        raise HTTPException(
            status_code=400,
            detail=f"Cannot start Stage 2 from tender status '{tender.status}'",
        )

    auction = db.query(Auction).filter(Auction.tender_id == tender_id, Auction.stage == 2).first()
    if not auction:
        now = _utcnow()
        auction = Auction(
            tender_id=tender_id,
            stage=2,
            status="SCHEDULED",
            start_time=now,
            soft_end_time=now + timedelta(minutes=30),
            hard_stop_time=now + timedelta(hours=1),
            extension_minutes=5,
        )
        db.add(auction)
        db.commit()
        db.refresh(auction)

    auction.status = "LIVE"
    auction.start_time = _utcnow()
    tender.status = "STAGE_2_LIVE"

    db.commit()
    db.refresh(auction)
    return auction


def complete_stage2(db: Session, tender_id) -> dict:
    tender = _get_tender(db, tender_id)
    auction = _get_auction(db, tender_id, stage=2)

    if auction.status not in ("LIVE", "EXTENDED"):
        raise HTTPException(
            status_code=400,
            detail=f"Stage 2 auction is not active (status: {auction.status})",
        )

    bids = (
        db.query(Bid)
        .filter(Bid.auction_id == auction.id, Bid.status == "valid")
        .order_by(Bid.amount.asc(), Bid.submitted_at.asc())
        .all()
    )
    if not bids:
        raise HTTPException(
            status_code=400, detail="No valid bids were submitted in Stage 2"
        )

    winning_bid = bids[0]

    auction.status = "COMPLETED"
    auction.completed_at = _utcnow()
    tender.status = "STAGE_2_COMPLETED"

    result = AuctionResult(
        tender_id=tender_id,
        auction_id=auction.id,
        winning_bid_id=winning_bid.id,
        winner_transporter_id=winning_bid.transporter_id,
        winning_amount=winning_bid.amount,
        decided_at=_utcnow(),
    )
    db.add(result)
    db.commit()

    tender.status = "WINNER_FINALIZED"
    db.commit()

    tender.status = "COMPLETED"
    db.commit()

    winner_participant = (
        db.query(Participant)
        .filter(
            Participant.tender_id == auction.tender_id,
            Participant.transporter_id == winning_bid.transporter_id,
        )
        .first()
    )
    winner_user = db.query(User).filter(User.id == winning_bid.transporter_id).first()
    winner_name = (
        winner_participant.transporter_name
        if winner_participant and winner_participant.transporter_name
        else (winner_user.name if winner_user else str(winning_bid.transporter_id))
    )
    winner_company = (
        winner_user.transporter_profile.company_name
        if winner_user and winner_user.transporter_profile
        else winner_name
    )

    finalized_iso = result.finalized_at.isoformat() if hasattr(result.finalized_at, "isoformat") else str(result.finalized_at)

    return {
        "tender_id": tender_id,
        "result_id": result.id,
        "winner_id": winning_bid.transporter_id,
        "winner_transporter_id": winning_bid.transporter_id,
        "winner_name": winner_name,
        "winner_transporter_name": winner_name,
        "winner_company": winner_company,
        "winning_bid": float(winning_bid.amount),
        "winning_amount": float(winning_bid.amount),
        "stage": 2,
        "finalized_at": finalized_iso,
        "decided_at": finalized_iso,
        "submitted_at": winning_bid.submitted_at.isoformat() if hasattr(winning_bid.submitted_at, "isoformat") else str(winning_bid.submitted_at),
    }


# ---------------------------------------------------------------------------
# Results & rankings
# ---------------------------------------------------------------------------

def get_result(db: Session, tender_id) -> dict:
    _get_tender(db, tender_id)

    result = (
        db.query(AuctionResult)
        .filter(AuctionResult.tender_id == tender_id)
        .first()
    )
    if not result:
        raise HTTPException(
            status_code=404, detail="No result available for this tender yet"
        )

    winner_participant = (
        db.query(Participant)
        .filter(
            Participant.tender_id == tender_id,
            Participant.transporter_id == result.winner_transporter_id,
        )
        .first()
    )
    winner_user = db.query(User).filter(User.id == result.winner_transporter_id).first()
    winner_name = (
        winner_participant.transporter_name
        if winner_participant and winner_participant.transporter_name
        else (winner_user.name if winner_user else str(result.winner_transporter_id))
    )
    winner_company = (
        winner_user.transporter_profile.company_name
        if winner_user and winner_user.transporter_profile
        else winner_name
    )

    finalized_iso = result.finalized_at.isoformat() if hasattr(result.finalized_at, "isoformat") else str(result.finalized_at)

    return {
        "tender_id": tender_id,
        "result_id": result.id,
        "winner_id": result.winner_transporter_id,
        "winner_transporter_id": result.winner_transporter_id,
        "winner_name": winner_name,
        "winner_transporter_name": winner_name,
        "winner_company": winner_company,
        "winning_bid": float(result.winning_amount),
        "winning_amount": float(result.winning_amount),
        "stage": result.stage or 2,
        "finalized_at": finalized_iso,
        "decided_at": finalized_iso,
    }


def get_ranking_for_transporter(
    db: Session, tender_id, transporter_id
) -> dict:
    tender = _get_tender(db, tender_id)

    if "STAGE_2" in (tender.status or "") or tender.status in (
        "WINNER_FINALIZED", "COMPLETED"
    ):
        raise HTTPException(
            status_code=403,
            detail="Ranking is not available during the final auction.",
        )

    auction = _get_auction(db, tender_id, stage=1)

    participant = (
        db.query(Participant)
        .filter(
            Participant.tender_id == auction.tender_id,
            Participant.transporter_id == transporter_id,
        )
        .first()
    )
    if not participant:
        raise HTTPException(
            status_code=403,
            detail="You are not a participant in this auction",
        )

    ranking = recalculate_ranking(db, auction.id)

    my_rank = next(
        (
            r for r in ranking
            if r["transporter_id"] == transporter_id
        ),
        None,
    )

    valid_bids = _valid_bids(db, auction.id)
    minimum_valid_bid = (
        float(min(b.amount for b in valid_bids)) if valid_bids else None
    )

    return {
        "tender_id": tender_id,
        "stage": 1,
        "ranking": ranking,
        "your_rank": my_rank["rank"] if my_rank else None,
        "your_amount": my_rank["amount"] if my_rank else None,
        "current_l1": ranking[0]["amount"] if ranking else None,
        "minimum_valid_bid": minimum_valid_bid,
    }