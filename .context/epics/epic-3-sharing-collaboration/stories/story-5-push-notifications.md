# Story 3.5: Push Notifications

canceled

## Description
Users receive notifications when shared lists change.

## Acceptance Criteria
- [ ] Notification when: item added, item checked, member joined/left
- [ ] Notification shows: "[User] added [item] to [list]"
- [ ] Tap notification opens relevant list
- [ ] Per-list notification toggle
- [ ] Respect device "Do Not Disturb"
- [ ] Badge count on app icon

## Technical Implementation

### FastAPI Implementation

```python
@router.post("/send-notification")
async def send_notification(
    notification: NotificationData,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Send push notification to list members"""

    members = db.query(ListMember).filter(
        ListMember.list_id == notification.list_id,
        ListMember.notifications_enabled == True
    ).all()

    for member in members:
        user = db.query(User).filter(User.id == member.user_id).first()
        if user and user.fcm_token:
            background_tasks.add_task(
                send_fcm_notification,
                user.fcm_token,
                notification.title,
                notification.body,
                {"list_id": str(notification.list_id)}
            )
```

### Flutter Implementation

```dart
class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      String? token = await _messaging.getToken();
      // Send token to backend
      await _api.updateFcmToken(token!);

      // Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleNotification(message);
      });

      // Handle background notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _navigateToList(message.data['list_id']);
      });
    }
  }

  void _handleNotification(RemoteMessage message) {
    ScaffoldMessenger.of(_navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(message.notification?.body ?? ''),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _navigateToList(message.data['list_id']),
        ),
      ),
    );
  }
}
```

## Dependencies
- Story 3.4 (Real-Time Sync)

## Estimated Effort
5 story points
