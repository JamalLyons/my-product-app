# Firebase Auth Activity 13

This Flutter app demonstrates Firebase email/password registration and sign-in,
auth-state routing, a signed-in profile, sign-out, and password updates. It also
retains the earlier Cloud Firestore product manager as a signed-in-only feature.

## Authentication behavior

- Registration and sign-in validate email format and the assignment's six-character password baseline.
- `AuthGate` listens to the stable stream in `AuthService` and selects the signed-out or signed-in screen.
- The profile displays the current Firebase email and provides sign-out and password update actions.
- Password updates handle Firebase's `requires-recent-login` response by asking for the current password, reauthenticating, and retrying.
- Firebase errors are mapped to user-facing messages. Passwords are not logged or stored.

## Firebase configuration

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for Firebase project, Android, and
fresh-checkout setup. The current project has Email/Password sign-in enabled in
Firebase Console. The generated `lib/firebase_options.dart` and Android
`google-services.json` are local project configuration and are ignored by Git.
Never commit service-account credentials, signing keys, or passwords.

## Run on Android

From the project root:

```sh
flutter pub get
flutter analyze
flutter run -d <ANDROID_DEVICE_ID>
```

To prepare the assignment APK:

```sh
flutter build apk --release
```

The standard output path is `build/app/outputs/flutter-apk/app-release.apk`.
Install and exercise that exact APK on an Android device or emulator before
submitting it.

## Code map

- `lib/auth_service.dart`: Firebase Authentication operations and reauthentication.
- `lib/main.dart`: app initialization, auth gate, sign-in/register UI, profile,
  and the carried-forward Firestore product manager.
- `test/widget_test.dart`: widget smoke test for Firebase configuration failure.

## Manual checks before submission

Capture your own results for registration, sign-in, invalid input or failed
sign-in, profile email, password update, sign-out and blocked profile access,
session restoration, and loading/error behavior. If recent-login recovery is
not triggered during testing, document the recovery test plan and code path
instead of claiming it passed. Combine captioned screenshots and your reflection
in one PDF or Word document as described in the assignment guide.
