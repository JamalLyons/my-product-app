import 'package:firebase_auth/firebase_auth.dart';

/// Authentication operations used by the UI.
abstract interface class AuthOperations {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<UserCredential> register({
    required String email,
    required String password,
  });
  Future<UserCredential> signIn({
    required String email,
    required String password,
  });
  Future<void> signOut();
  Future<void> updatePassword(String newPassword);
  Future<void> reauthenticateAndUpdatePassword({
    required String currentPassword,
    required String newPassword,
  });
}

/// Firebase Authentication implementation used by the app.
class AuthService implements AuthOperations {
  AuthService({FirebaseAuth? firebaseAuth})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      authStateChanges = (firebaseAuth ?? FirebaseAuth.instance)
          .authStateChanges();

  final FirebaseAuth _auth;

  /// A single app-lifetime stream that emits the current user and auth changes.
  @override
  final Stream<User?> authStateChanges;

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<UserCredential> register({
    required String email,
    required String password,
  }) => _auth.createUserWithEmailAndPassword(
    email: email.trim(),
    password: password,
  );

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before changing your password.');
    }
    await user.updatePassword(newPassword);
  }

  @override
  Future<void> reauthenticateAndUpdatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw StateError('A signed-in email account is required.');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
