from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from websocket_manager import manager
from utils.security import decode_access_token

router = APIRouter(tags=["WebSocket"])

@router.websocket("/ws/auction/{tender_id}")
async def auction_websocket(websocket: WebSocket, tender_id: int, token: str = Query(...)):
    payload = decode_access_token(token)
    if not payload:
        await websocket.close(code=4001)
        return
    
    user_id = int(payload.get("sub", 0))
    if not user_id:
        await websocket.close(code=4001)
        return

    await manager.connect(tender_id, user_id, websocket)
    try:
        while True:
            data = await websocket.receive_text()
            # Handle client ping or messages
            if data == "ping":
                await websocket.send_text("pong")
    except WebSocketDisconnect:
        manager.disconnect(tender_id, user_id)
    except Exception:
        manager.disconnect(tender_id, user_id)
