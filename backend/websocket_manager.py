"""
websocket_manager.py — LogiQ FastAPI WebSocket Connection Manager
"""

import logging
from typing import Any

from fastapi import WebSocket

logger = logging.getLogger("logiq.websocket")


class ConnectionManager:
    """Manages active WebSocket connections grouped by tender and user."""

    def __init__(self) -> None:
        self.active_connections: dict[int, dict[int, WebSocket]] = {}

    async def connect(self, tender_id: int, user_id: int, websocket: WebSocket) -> None:
        """Accept a WebSocket connection and register it under the given tender/user."""
        await websocket.accept()

        if tender_id not in self.active_connections:
            self.active_connections[tender_id] = {}

        self.active_connections[tender_id][user_id] = websocket
        logger.info(
            "WebSocket connected | tender=%s user=%s active=%s",
            tender_id,
            user_id,
            len(self.active_connections[tender_id]),
        )

    def disconnect(self, tender_id: int, user_id: int) -> None:
        """Remove a WebSocket connection for a given tender/user."""
        if tender_id not in self.active_connections:
            return

        self.active_connections[tender_id].pop(user_id, None)

        if not self.active_connections[tender_id]:
            del self.active_connections[tender_id]

        logger.info("WebSocket disconnected | tender=%s user=%s", tender_id, user_id)

    async def broadcast_to_auction(self, tender_id: int, message: dict[str, Any]) -> None:
        """Send a JSON message to every connected user in a tender auction."""
        if tender_id not in self.active_connections:
            return

        for user_id, ws in list(self.active_connections[tender_id].items()):
            try:
                await ws.send_json(message)
            except Exception:
                logger.warning(
                    "Failed to broadcast | tender=%s user=%s",
                    tender_id,
                    user_id,
                    exc_info=True,
                )
                self.disconnect(tender_id, user_id)

    async def send_personal(self, tender_id: int, user_id: int, message: dict[str, Any]) -> None:
        """Send a JSON message to a single user within a tender."""
        if tender_id not in self.active_connections:
            return

        ws = self.active_connections[tender_id].get(user_id)
        if ws is None:
            return

        try:
            await ws.send_json(message)
        except Exception:
            logger.warning(
                "Failed to send personal message | tender=%s user=%s",
                tender_id,
                user_id,
                exc_info=True,
            )
            self.disconnect(tender_id, user_id)

    def get_connection_count(self, tender_id: int) -> int:
        """Return the number of active connections for a given tender."""
        if tender_id not in self.active_connections:
            return 0
        return len(self.active_connections[tender_id])

    def get_active_tenders(self) -> list[int]:
        """Return a list of tender IDs that currently have active connections."""
        return list(self.active_connections.keys())

    def cleanup_stale(self, tender_id: int) -> None:
        """Remove a tender entry if no connections remain."""
        if tender_id in self.active_connections and not self.active_connections[tender_id]:
            del self.active_connections[tender_id]


manager = ConnectionManager()