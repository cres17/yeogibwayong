# yeogibwayong

Pet-themed productivity app built with Flutter.

`yeogibwayong` helps users stay aware of app usage through a soft nudge experience instead of hard blocking. The app combines timers, pet growth, usage statistics, overlays, and notifications to make focus habits feel more playful.

## Features

- Pet-themed focus timer
- Android app usage tracking
- Usage statistics and session history
- Floating overlay pet for gentle reminders
- Local notifications
- Pet image assets and pet management screens
- Korean and English localization support
- Settings, onboarding, and permission guide flows

## Tech Stack

- Flutter / Dart
- Provider for state management
- SQLite via `sqflite`
- `shared_preferences` for local settings
- Android usage stats integration
- Background work with foreground/background services
- Overlay support with `flutter_overlay_window`
- Local notifications
- Charts with `fl_chart`
- AdMob banner integration

## Project Structure

```text
lib/
  app.dart
  main.dart
  core/
  data/
  l10n/
  overlay/
  providers/
  screens/
  services/
  widgets/
assets/
  images/
android/
test/
```

## Getting Started

Install Flutter, then run:

```bash
flutter pub get
flutter run
```

For Android usage tracking and overlay features, the app requires Android permissions such as usage access and draw-over-other-apps permission. Some features may need to be enabled manually in system settings.

## Development

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## Notes

This project is currently focused on Android. iOS support may require separate implementation for equivalent usage-tracking behavior.
