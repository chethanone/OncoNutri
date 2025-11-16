# OncoNutri+ Flutter Frontend

A Flutter mobile application for personalized cancer nutrition recommendations.

## Features

- User authentication (login/signup)
- Patient profile management
- Personalized diet recommendations based on ML model
- Progress tracking and history
- Push notifications for meal reminders
- Multilingual support (English, Hindi, Spanish)
- Offline mode with local caching

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode for mobile development

### Installation

1. Install Flutter dependencies:
```bash
flutter pub get
```

2. Generate localization files:
```bash
flutter gen-l10n
```

3. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── routes/                   # App navigation routes
├── screens/                  # All UI screens
├── widgets/                  # Reusable UI components
├── models/                   # Data models
├── services/                 # API, notifications, caching
├── utils/                    # Helper functions, constants
└── l10n/                     # Internationalization files
```

## Dependencies

- **provider**: State management
- **http/dio**: API communication
- **shared_preferences**: Local storage
- **flutter_local_notifications**: Push notifications
- **intl**: Internationalization

## Configuration

Update the API base URL in `lib/utils/constants.dart`:
```dart
static const String apiBaseUrl = 'YOUR_API_URL';
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## License

This project is part of the OncoNutri+ healthcare application.
