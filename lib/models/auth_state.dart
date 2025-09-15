import 'user.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.token,
    this.errorMessage,
  });

  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        token = null,
        errorMessage = null;

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        token = null,
        errorMessage = null;

  const AuthState.authenticated({
    required User user,
    required String token,
  }) : status = AuthStatus.authenticated,
       user = user,
       token = token,
       errorMessage = null;

  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        token = null,
        errorMessage = null;

  const AuthState.error(String message)
      : status = AuthStatus.error,
        user = null,
        token = null,
        errorMessage = message;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null && token != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'AuthState(status: $status, user: $user, token: ${token != null ? '***' : null}, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthState &&
        other.status == status &&
        other.user == user &&
        other.token == token &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        user.hashCode ^
        token.hashCode ^
        errorMessage.hashCode;
  }
}
