# Story 5.3: Keep Screen On

## Description
Prevent screen timeout while shopping.

## Acceptance Criteria
- [ ] Toggle in settings (default off)
- [ ] Can also enable per-list via list menu
- [ ] Show indicator when active (subtle icon in app bar)
- [ ] Respect device battery saver mode
- [ ] Auto-disable after 30 min inactivity
- [ ] Disable when app backgrounded

## Technical Implementation

### Flutter Implementation

```dart
// Using wakelock package
class ScreenWakeService {
  bool _isEnabled = false;
  Timer? _inactivityTimer;

  Future<void> enable() async {
    if (await _shouldRespectBatterySaver()) return;

    await WakelockPlus.enable();
    _isEnabled = true;
    _resetInactivityTimer();
  }

  Future<void> disable() async {
    await WakelockPlus.disable();
    _isEnabled = false;
    _inactivityTimer?.cancel();
  }

  void onUserActivity() {
    if (_isEnabled) {
      _resetInactivityTimer();
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(minutes: 30), disable);
  }

  Future<bool> _shouldRespectBatterySaver() async {
    final batteryState = await Battery().batteryState;
    return batteryState == BatteryState.charging ? false :
           await Battery().batteryLevel < 20;
  }
}
```

## Dependencies
- Foundational UI structure

## Estimated Effort
2 story points
