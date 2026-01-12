# Story 5.1: Dark Mode

## Description
Alternative dark color scheme.

## Acceptance Criteria
- [ ] Toggle in settings: Light, Dark, System
- [ ] Full theme support (all screens)
- [ ] Smooth transition animation
- [ ] Persist preference
- [ ] OLED-friendly true black option

## Technical Implementation

### Flutter Theme Configuration

```dart
// Theme configuration
final lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.green,
  scaffoldBackgroundColor: Colors.grey.shade50,
  cardColor: Colors.white,
  // ... more theme properties
);

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.green,
  scaffoldBackgroundColor: Color(0xFF121212),
  cardColor: Color(0xFF1E1E1E),
  // ... more theme properties
);

final oledDarkTheme = darkTheme.copyWith(
  scaffoldBackgroundColor: Colors.black,
  cardColor: Color(0xFF0A0A0A),
);

// Theme provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('theme_mode') ?? 'system';
    state = ThemeMode.values.firstWhere(
      (m) => m.name == savedMode,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}

// In app.dart
MaterialApp(
  themeMode: ref.watch(themeModeProvider),
  theme: lightTheme,
  darkTheme: darkTheme,
)
```

## Dependencies
- Foundational UI structure

## Estimated Effort
4 story points
