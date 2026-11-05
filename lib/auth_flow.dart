import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'product_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({required this.authService, super.key});

  final AuthOperations authService;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: authService.authStateChanges,
    initialData: authService.currentUser,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AuthErrorPage(message: _friendlyAuthError(snapshot.error));
      }
      if (!snapshot.hasData &&
          snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      return user == null
          ? AuthPage(authService: authService)
          : ProfilePage(authService: authService, user: user);
    },
  );
}

class AuthPage extends StatefulWidget {
  const AuthPage({required this.authService, super.key});
  final AuthOperations authService;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.authService.register(
          email: _email.text,
          password: _password.text,
        );
      } else {
        await widget.authService.signIn(
          email: _email.text,
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    } catch (error) {
      if (mounted) setState(() => _error = _friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Firebase Auth Activity 13')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _register ? 'Create account' : 'Sign in',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => !_isValidEmail(value ?? '')
                      ? 'Enter a valid email address.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: true,
                  autofillHints: [
                    _register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => (value?.length ?? 0) < 6
                      ? 'Password must be at least 6 characters.'
                      : null,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const CircularProgressIndicator()
                      : Text(_register ? 'Register' : 'Sign in'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _register = !_register;
                          _error = null;
                        }),
                  child: Text(
                    _register
                        ? 'Already registered? Sign in'
                        : 'Need an account? Register',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({required this.authService, required this.user, super.key});
  final AuthOperations authService;
  final User user;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _signingOut = false;

  Future<void> _changePassword(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _PasswordUpdateDialog(authService: widget.authService),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profile')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle, size: 72),
            const SizedBox(height: 12),
            Text(
              'Signed in as',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SelectableText(
              widget.user.email ?? 'Email unavailable',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _signingOut ? null : () => _changePassword(context),
              icon: const Icon(Icons.password),
              label: const Text('Update password'),
            ),
            TextButton.icon(
              onPressed: _signingOut
                  ? null
                  : () async {
                      setState(() => _signingOut = true);
                      try {
                        await widget.authService.signOut();
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_friendlyAuthError(error))),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _signingOut = false);
                      }
                    },
              icon: const Icon(Icons.logout),
              label: _signingOut
                  ? const CircularProgressIndicator()
                  : const Text('Sign out'),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: _signingOut
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ProductManagerGate(authService: widget.authService),
                      ),
                    ),
              icon: const Icon(Icons.inventory_2),
              label: const Text('Open product manager'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PasswordUpdateDialog extends StatefulWidget {
  const _PasswordUpdateDialog({required this.authService});
  final AuthOperations authService;

  @override
  State<_PasswordUpdateDialog> createState() => _PasswordUpdateDialogState();
}

class _PasswordUpdateDialogState extends State<_PasswordUpdateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _currentPassword = TextEditingController();
  bool _recentLoginNeeded = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _newPassword.dispose();
    _currentPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_recentLoginNeeded) {
        await widget.authService.reauthenticateAndUpdatePassword(
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
        );
      } else {
        await widget.authService.updatePassword(_newPassword.text);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password updated.')));
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        if (exception is FirebaseAuthException &&
            exception.code == 'requires-recent-login') {
          _recentLoginNeeded = true;
          _error = 'Please confirm your current password to continue.';
        } else {
          _error = _friendlyAuthError(exception);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Update password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_recentLoginNeeded)
              TextFormField(
                controller: _currentPassword,
                enabled: !_saving,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Enter your current password.'
                    : null,
              ),
            TextFormField(
              controller: _newPassword,
              enabled: !_saving,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (value) => (value?.length ?? 0) < 6
                  ? 'Use at least 6 characters.'
                  : null,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const CircularProgressIndicator()
              : const Text('Update'),
        ),
      ],
    ),
  );
}

/// Re-checks auth state while the legacy Firestore screen is on the route stack.
class ProductManagerGate extends StatelessWidget {
  const ProductManagerGate({required this.authService, super.key});

  final AuthOperations authService;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: authService.authStateChanges,
    initialData: authService.currentUser,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _AuthErrorPage(message: _friendlyAuthError(snapshot.error));
      }
      if (!snapshot.hasData &&
          snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.data == null) {
        return AuthPage(authService: authService);
      }
      return const ProductPage();
    },
  );
}

class _AuthErrorPage extends StatelessWidget {
  const _AuthErrorPage({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Authentication error: $message',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

String _friendlyAuthError(Object? error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'operation-not-allowed':
        return 'Email and password sign-in is not enabled in Firebase yet.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a bit and try again.';
      case 'requires-recent-login':
        return 'Sign in again before changing your password.';
    }
  }
  return 'Could not complete the request. Please try again.';
}

bool _isValidEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
