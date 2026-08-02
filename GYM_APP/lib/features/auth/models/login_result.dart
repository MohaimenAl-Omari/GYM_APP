class LoginResult {
  const LoginResult({
    this.error,
    this.profileComplete = false,
    this.canceled = false,
  });

  final String? error;
  final bool profileComplete;
  final bool canceled;

  bool get success => error == null && !canceled;
}

enum AuthStatus {
  loggedOut,
  needsProfile,
  home,
}
