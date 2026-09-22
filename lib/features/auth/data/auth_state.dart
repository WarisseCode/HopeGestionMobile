import 'app_user.dart';

/// État d'authentification global de l'app, exposé par `AuthRepository`.
sealed class AuthState {
  const AuthState();
}

/// Vérification de session en cours au démarrage (`restoreSession`).
class AuthInitializing extends AuthState {
  const AuthInitializing();
}

/// Pas de session valide. [message] est affiché une fois par l'écran de
/// connexion quand il est non nul (ex. déconnexion pour session expirée) ;
/// il ne doit pas persister au-delà de sa lecture par l'UI.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.message});

  final String? message;
}

/// Session valide, rôle autorisé (v1 : `gestionnaire`/`manager`).
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final AppUser user;
}

/// Connexion réussie (ou session restaurée) mais rôle non pris en charge
/// par la v1 mobile (`admin`, `proprietaire`, `locataire`, `pending`, ou
/// tout rôle inconnu) : aucun token n'est conservé.
class AuthUnsupportedRole extends AuthState {
  const AuthUnsupportedRole();
}

/// Une session (tokens) existe localement, mais le serveur n'a pas pu être
/// contacté au démarrage (réseau, timeout, 5xx) — pas assez d'information
/// pour dire si le rôle est encore autorisé. Tokens conservés : voir
/// `AuthRepository.retry`.
class AuthOffline extends AuthState {
  const AuthOffline();
}
