# Autumn Product Manager

A Flutter product catalogue backed by Cloud Firestore. It supports creating,
viewing, editing, and deleting products, plus live updates, case-insensitive
name search, inclusive minimum/maximum price filters, and Reset.

## Product data

The app uses the Firestore `products` collection. Each valid document must have:

- `name`: a nonempty string after trimming.
- `price`: a finite, nonnegative Firestore number. A price of zero is valid.

Malformed existing records are shown with their document ID and can be deleted
from the app. The app does not silently treat a malformed record as a valid
product.

## Android setup and run

See [FIREBASE_SETUP.md](FIREBASE_SETUP.md) for Firebase project configuration,
FlutterFire setup, and the assignment fixture workflow. The generated
`lib/firebase_options.dart` and Android Firebase configuration are specific to
your Firebase project and are intentionally ignored by Git. Do not commit
service-account keys or tokens.

After configuring Firebase:

```sh
flutter pub get
flutter analyze
flutter run -d <ANDROID_DEVICE_ID>
```

The complete list of account, device, evidence, and report tasks is in
[`user-checklist.md`](user-checklist.md). The app code is kept in
`lib/main.dart` for the assignment's main-Dart-file submission option.
