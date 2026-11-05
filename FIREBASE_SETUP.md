# Firebase setup

The app initializes Firebase with `lib/firebase_options.dart`. Android also
uses the Google Services Gradle plugin and `android/app/google-services.json`.
The configured Firebase project is `my-product-app-e359e`; the Android package
name is `com.example.my_product_app`.

## Current project status

- Firebase Authentication is initialized for the project.
- **Email/Password** sign-in is enabled in Firebase Console.
- Cloud Firestore is enabled for the carried-forward product manager.
- The local workspace has both generated Firebase configuration files. They
  are ignored by Git, so they must be created again when setting up a fresh
  checkout.

## Configure a fresh checkout

1. Install the Firebase CLI and FlutterFire CLI and sign in with an account that
   can access the Firebase project.
2. From the Flutter project root, run:

   ```sh
   flutterfire configure --project=my-product-app-e359e --platforms=android
   ```

3. Confirm the registered Android Firebase app uses package name
   `com.example.my_product_app`. The command should generate
   `lib/firebase_options.dart` and `android/app/google-services.json` for the
   same Firebase Android app.
4. In Firebase Console, open **Authentication → Sign-in method** and confirm
   **Email/Password** is enabled. It is enabled in the current project as of
   November 5, 2026.
5. Run `flutter pub get`, then launch the app on an Android device or emulator.

`firebase.json` stores FlutterFire project/app mapping. If you use another
Firebase project or change the Android package name, reconfigure Firebase and
download matching Android configuration. Additional platforms require adding
their Firebase apps and generating platform options.

## Firestore product manager

The carried-forward product manager uses the `products` collection. Firebase
Authentication does not automatically secure Firestore data. Review and deploy
Firestore Security Rules that match your data model before using real data; the
auth assignment's signed-in UI routing is not a substitute for server-side
authorization. Firestore is not required for the authentication flow itself.
