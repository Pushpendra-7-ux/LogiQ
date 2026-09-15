from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models.user import User
from schemas.bid import BidCreate, BidResponse
from middleware.auth_middleware import get_current_user
import services.auction_service as auction_service
from websocket_manager import manager

router = APIRouter(prefix="/auctions", tags=["Auctions"])

@router.post("/{tender_id}/start-stage1")
async def start_stage1(tender_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    auction = auction_service.start_stage1(db, tender_id)
    await manager.broadcast_to_auction(tender_id, {
        "type": "stage_1_started",
        "tender_id": tender_id,
        "message": "Stage 1 auction is now live!"
    })
    return {"message": "Stage 1 auction started.", "auction_id": auction.id}

@router.get("/{tender_id}/status")
def get_auction_status(tender_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    status_info = auction_service.get_auction_status(db, tender_id)
    return status_info

@router.post("/{tender_id}/bids")
async def submit_bid(tender_id: int, data: BidCreate, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if current_user.role != "transporter":
        raise HTTPException(status_code=403, detail="Only transporters can submit bids.")
    
    result = auction_service.validate_and_submit_bid(db, tender_id, current_user.id, data.amount, data.stage)
    
    if data.stage == 1:
        # Broadcast ranking update to all participants in Stage 1
        rankings = auction_service.recalculate_ranking(db, result.get("auction_id"))
        status_info = auction_service.get_auction_status(db, tender_id)
        await manager.broadcast_to_auction(tender_id, {
            "type": "ranking_update",
            "rankings": rankings,
            "current_l1": status_info.get("current_l1"),
            "minimum_valid_bid": status_info.get("minimum_valid_bid"),
            "timer": {
                "remaining_seconds": status_info.get("remaining_seconds"),
                "end_time": str(status_info.get("soft_end_time")),
                "server_time": str(status_info.get("server_time")),
            }
        })
        if result.get("extended"):
            await manager.broadcast_to_auction(tender_id, {
                "type": "auction_extended",
                "extension_minutes": 5,
                "message": "Auction extended by 5 minutes due to a late bid."
            })
    else:
        # STAGE 2: STRICT PRIVACY. Only send personal acknowledgement. Never broadcast.
        await manager.send_personal(tender_id, current_user.id, {
            "type": "bid_accepted",
            "your_bid": data.amount,
            "message": "Your confidential bid has been recorded."
        })
    
    return {
        "message": "Bid submitted successfully.",
        "bid_id": result.get("bid_id"),
        "amount": data.amount,
        "your_rank": result.get("your_rank"),
        "current_l1": result.get("current_l1")
    }

@router.get("/{tender_id}/ranking")
def get_ranking(tender_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return auction_service.get_ranking_for_transporter(db, tender_id, current_user.id)

@router.post("/{tender_id}/complete-stage1")
async def complete_stage1(tender_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    res = auction_service.complete_stage1(db, tender_id)
    await manager.broadcast_to_auction(tender_id, {
        "type": "stage_1_complete",
        "top_5": res.get("top_5", []),
        "message": "Stage 1 complete. Top 5 selected for final auction."
    })
    return res

@router.post("/{tender_id}/start-stage2")
async def start_stage2(tender_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    auction = auction_service.start_stage2(db, tender_id)
    await manager.broadcast_to_auction(tender_id, {
        "type": "stage_2_started",
        "tender_id": tender_id,
        "message": "Stage 2 Blind Auction is now LIVE!"
    })
    return {"message": "Stage 2 blind auction started.", "auction_id": auction.id}

@router.post("/{tender_id}/complete-stage2")
async def complete_stage2(tender_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    res = auction_service.complete_stage2(db, tender_id)
    await manager.broadcast_to_auction(tender_id, {
        "type": "winner_finalized",
        "winner_id": res.get("winner_id"),
        "winner_name": res.get("winner_name"),
        "winning_bid": res.get("winning_bid"),
        "tender_id": tender_id,
        "message": "Winner has been automatically finalized."
    })
    return res

@router.get("/{tender_id}/result")
def get_result(tender_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    return auction_service.get_result(db, tender_id)
