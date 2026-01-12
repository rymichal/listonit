# Story 3.4: Real-Time Sync

## Description
All list changes sync instantly across devices.

## Acceptance Criteria
- [ ] Item added by User A appears on User B's device in <1 second
- [ ] No manual refresh needed
- [ ] Offline changes sync on reconnect
- [ ] Conflict resolution: merge non-conflicting, last-write-wins for conflicts
- [ ] Visual indicator: "Syncing..." during update

## Technical Implementation

### FastAPI WebSocket Manager

```python
# WebSocket connection manager
class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[UUID, List[WebSocket]] = defaultdict(list)

    async def connect(self, websocket: WebSocket, list_id: UUID, user_id: UUID):
        await websocket.accept()
        self.active_connections[list_id].append(websocket)

        # Announce presence
        await self.broadcast(list_id, {
            "type": "user_joined",
            "user_id": str(user_id),
            "timestamp": datetime.utcnow().isoformat()
        }, exclude=websocket)

    async def disconnect(self, websocket: WebSocket, list_id: UUID, user_id: UUID):
        self.active_connections[list_id].remove(websocket)
        await self.broadcast(list_id, {
            "type": "user_left",
            "user_id": str(user_id)
        })

    async def broadcast(self, list_id: UUID, message: dict, exclude: WebSocket = None):
        for connection in self.active_connections[list_id]:
            if connection != exclude:
                await connection.send_json(message)

manager = ConnectionManager()

@router.websocket("/ws/lists/{list_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    list_id: UUID,
    token: str = Query(...)
):
    user = verify_ws_token(token)
    if not user or not has_list_access(user.id, list_id):
        await websocket.close(code=4003)
        return

    await manager.connect(websocket, list_id, user.id)

    try:
        while True:
            data = await websocket.receive_json()
            # Handle incoming messages (typing indicators, etc.)
            if data["type"] == "typing":
                await manager.broadcast(list_id, {
                    "type": "user_typing",
                    "user_id": str(user.id),
                    "user_name": user.name
                }, exclude=websocket)
    except WebSocketDisconnect:
        await manager.disconnect(websocket, list_id, user.id)
```

### Flutter WebSocket Client

```dart
class ListSyncService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  void connect(String listId, String token) {
    final uri = Uri.parse('wss://api.listonit.app/ws/lists/$listId?token=$token');
    _channel = WebSocketChannel.connect(uri);

    _subscription = _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);
        _handleMessage(data);
      },
      onDone: () => _reconnect(listId, token),
      onError: (e) => _reconnect(listId, token),
    );
  }

  void _handleMessage(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'item_added':
        ref.read(itemsProvider.notifier).addFromServer(Item.fromJson(data['item']));
        break;
      case 'item_updated':
        ref.read(itemsProvider.notifier).updateFromServer(Item.fromJson(data['item']));
        break;
      case 'item_checked':
        ref.read(itemsProvider.notifier).setChecked(data['item_id'], data['checked']);
        break;
      case 'user_typing':
        ref.read(typingUsersProvider.notifier).setTyping(data['user_id'], data['user_name']);
        break;
    }
  }

  void disconnect() {
    _subscription?.cancel();
    _channel?.sink.close();
  }
}
```

## Dependencies
- Story 2.1 (Add Item - Quick Mode)
- Story 3.1 (Share List via Email)

## Estimated Effort
8 story points
