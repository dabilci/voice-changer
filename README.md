## Voice Changer (Flutter)

A cross-platform Flutter app to record audio, apply real-time or offline effects, manage files, and share results.

### Features
- Record audio (with microphone permission)
- Playback with waveform visualization
- Apply effects (e.g., speed/pitch, echo/reverb, etc.)
- Import/export, manage, and share files
- Google Mobile Ads integration

---

### Setup
Requirements:
- Flutter SDK (Dart sdk: `>=3.4.4 <4.0.0`)
- Android Studio / Xcode
- Platform SDKs and a device/emulator

Install & run:
```bash
flutter pub get
flutter run
```

Android microphone permission is handled automatically. For iOS, ensure `NSMicrophoneUsageDescription` exists in `Info.plist`.

### Build
- Android (APK): `flutter build apk --release`
- Android (App Bundle): `flutter build appbundle --release`
- iOS: `flutter build ios --release`
- Web: `flutter build web`

---

### Project Structure
- `lib/main.dart`: App entry point
- `lib/screens/`: Screens (`home_screen.dart`, `effects_screen.dart`, `files_screen.dart`)
- `lib/providers/`: State management (audio/effects providers)
- `lib/widgets/`: Reusable widgets (record button, player, waveform)
- `lib/utils/`: Helpers (theme, ads helper)

### Dependencies
- State & UI: `provider`, `cupertino_icons`
- Audio: `record`, `audioplayers`, `just_audio`, `audio_session`, `flutter_audio_waveforms`
- Permissions/Files: `permission_handler`, `path_provider`, `path`, `file_picker`
- Sharing/Ads: `share_plus`, `google_mobile_ads`
- Others: `intl`

For ads, update Ad Unit IDs in `lib/utils/ad_helper.dart` with your own.

### Notes
- Do NOT commit Android signing files (`key.properties`, `*.jks`). They are ignored by `.gitignore`.
- Build outputs (e.g., `build/`) and IDE artifacts are excluded.

 
