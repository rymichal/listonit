"""WebSocket endpoints for real-time list synchronization."""
from fastapi import APIRouter, Query, WebSocketDisconnect, WebSocket, status
from sqlalchemy.orm import Session

from auth.security import decode_token
from database import get_db
from websocket_manager import manager

router = APIRouter()


@router.websocket("/ws/lists/{list_id}")
async def websocket_endpoint(websocket: WebSocket, list_id: str, token: str = Query(...)):
    """
    WebSocket endpoint for real-time list synchronization.

    Query Parameters:
        token: JWT token for authentication

    Connects user to a list's WebSocket channel for real-time updates.
    """
    # Verify authentication
    try:
        payload = decode_token(token)
        if payload is None:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
        user_id = payload.get("sub")
        if not user_id:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return
    except Exception:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    # TODO: Verify user has access to list
    # For now, we'll assume access is granted
    # In production, check list membership in database

    # Get user info from database for broadcasting
    db = next(get_db())
    from models.user import User

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    try:
        await manager.connect(websocket, list_id, user_id, user.name)

        while True:
            data = await websocket.receive_json()
            message_type = data.get("type")

            # Handle typing indicator
            if message_type == "typing":
                await manager.broadcast(
                    list_id,
                    {
                        "type": "user_typing",
                        "user_id": user_id,
                        "user_name": user.name,
                    },
                    exclude=websocket,
                )

            # Handle sync acknowledgment
            elif message_type == "sync_ack":
                # Client acknowledges receiving a sync message
                pass

    except WebSocketDisconnect:
        await manager.disconnect(websocket, list_id, user_id)
    except Exception as e:
        print(f"WebSocket error: {e}")
        await manager.disconnect(websocket, list_id, user_id)
