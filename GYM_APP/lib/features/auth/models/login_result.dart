/// Result of a login attempt.
///
/// [profileComplete] tells the caller where to navigate next: straight to
/// Home if the user already filled in age/weight/height/goal, or to the
/// mandatory profile-completion screen if not.
class LoginResult {
  const LoginResult({this.error, this.profileComplete = false});

  final String? error;
  final bool profileComplete;

  bool get success => error == null;
}
