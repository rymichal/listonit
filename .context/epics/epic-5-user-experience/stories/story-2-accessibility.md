# Story 5.2: Accessibility

## Description
Full accessibility support.

## Acceptance Criteria
- [ ] Screen reader labels on all interactive elements
- [ ] Minimum touch target 48x48dp
- [ ] High contrast mode option
- [ ] Reduce motion option
- [ ] Focus indicators visible
- [ ] Semantic ordering of elements
- [ ] Sufficient color contrast ratios (WCAG AA)

## Technical Implementation

### Flutter Implementation

```dart
// Semantic labels example
Semantics(
  label: 'Add item to shopping list',
  button: true,
  child: IconButton(
    icon: Icon(Icons.add),
    onPressed: _addItem,
  ),
)

// Touch target sizing
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: Icon(Icons.check),
    onPressed: _toggleCheck,
  ),
)

// High contrast support
class HighContrastTheme {
  static ThemeData get theme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      bodyLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
    ),
    // High contrast borders and indicators
  );
}

// Reduce motion support
class AccessibilityConfig {
  static bool get shouldReduceMotion {
    return MediaQuery.of(context).disableAnimations;
  }

  static Duration getAnimationDuration() {
    return shouldReduceMotion ? Duration.zero : Duration(milliseconds: 300);
  }
}
```

## Dependencies
- Foundational UI structure

## Estimated Effort
5 story points
