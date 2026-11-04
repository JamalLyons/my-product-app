# Firebase setup (Android)

This app uses the Android Firebase default app. No Dart `firebase_options.dart` is required.

1. Create a Firebase project in the Firebase Console.
2. Add an **Android** app with package name `com.example.my_product_app` (the current `applicationId` in `android/app/build.gradle.kts`).
3. Download the app's `google-services.json` and place it at `android/app/google-services.json`.
4. In Firebase Console, create the Cloud Firestore database (the app expects the `products` collection).
5. From this directory run `flutter pub get`, then `flutter run`.

The Google Services Gradle plugin is already configured in the Android project. If you change the Android package name, register that exact package in Firebase and download a matching JSON file. Firebase project creation and credential download require your Firebase account, so those values cannot be generated in this workspace.
