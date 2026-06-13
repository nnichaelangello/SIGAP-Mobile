# SIGAP Mobile - Flutter Frontend

## 📱 Setup

### Prerequisites:
- Flutter SDK 3.x
- Android Studio / Xcode
- Firebase account

### Installation:
```bash
flutter pub get
flutter run
```

---

## 📁 Structure

```
lib/
├── main.dart              # Entry point
├── core/                  # Core utilities
│   ├── config/           # Firebase config
│   └── constants/        # App constants
├── services/             # Business logic
│   ├── firebase_service.dart
│   └── api_service.dart
├── providers/            # State management
└── features/             # Feature modules
    ├── auth/
    ├── panic/
    └── nearby/
```

---

## 🔥 Firebase Setup

1. Create Firebase project
2. Download `google-services.json` (Android)
3. Download `GoogleService-Info.plist` (iOS)
4. Place in respective folders

---

## 🚀 Build

### Android:
```bash
flutter build apk --release
```

### iOS:
```bash
flutter build ios --release
```

---

**Status:** 🚧 Setup Phase
