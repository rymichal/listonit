"""WebSocket connection manager for real-time list sync."""
from collections import defaultdict
from datetime import datetime
from typing import Dict, List, Optional

from fastapi import WebSocket


class ConnectionManager:
    """Manages WebSocket connections for real-time list synchronization."""

    def __init__(self):
        # Dict mapping list_id to list of WebSocket connections
        self.active_connections: Dict[str, List[WebSocket]] = defaultdict(list)
        # Dict mapping list_id to dict of user_id -> user data
        self.active_users: Dict[str, Dict[str, dict]] = defaultdict(dict)

    async def connect(self, websocket: WebSocket, list_id: str, user_id: str, user_name: str):
        """Accept a WebSocket connection and announce user presence."""
        await websocket.accept()
        self.active_connections[list_id].append(websocket)
        self.active_users[list_id][user_id] = {
            "user_id": user_id,
            "user_name": user_name,
            "connected_at": datetime.utcnow().isoformat(),
        }

        # Announce user joined to all other connections
        await self.broadcast(
            list_id,
            {
                "type": "user_joined",
                "user_id": user_id,
                "user_name": user_name,
                "timestamp": datetime.utcnow().isoformat(),
            },
            exclude=websocket,
        )

    async def disconnect(self, websocket: WebSocket, list_id: str, user_id: str):
        """Remove a WebSocket connection and announce user left."""
        if websocket in self.active_connections[list_id]:
            self.active_connections[list_id].remove(websocket)

        if user_id in self.active_users[list_id]:
            del self.active_users[list_id][user_id]

        # Announce user left to all remaining connections
        await self.broadcast(
            list_id,
            {
                "type": "user_left",
                "user_id": user_id,
                "timestamp": datetime.utcnow().isoformat(),
            },
        )

    async def broadcast(
        self, list_id: str, message: dict, exclude: Optional[WebSocket] = None
    ):
        """Broadcast a message to all connections for a specific list."""
        connections = self.active_connections[list_id]
        print(f"[WS] Broadcasting to list {list_id}: {len(connections)} connections, message type: {message.get('type')}")
        dead_connections = []

        for connection in connections:
            if connection != exclude:
                try:
                    await connection.send_json(message)
                    print(f"[WS] Sent to connection successfully")
                except Exception as e:
                    print(f"[WS] Failed to send: {e}")
                    # Mark connection as dead to remove later
                    dead_connections.append(connection)

        # Clean up dead connections
        for connection in dead_connections:
            await self.disconnect(connection, list_id, "")

    async def send_personal(self, websocket: WebSocket, message: dict):
        """Send a message to a specific connection."""
        try:
            await websocket.send_json(message)
        except Exception:
            pass

    def get_active_users(self, list_id: str) -> list:
        """Get list of active users for a specific list."""
        return list(self.active_users[list_id].values())


# Global connection manager instance
manager = ConnectionManager()
