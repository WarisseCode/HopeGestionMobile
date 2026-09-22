import '../../../core/network/api_exception.dart';
import 'app_user.dart';

/// Résultat de `AuthRepository.login`.
///
/// Distinct de `AuthState` : un échec de connexion (identifiants invalides,
/// réseau...) est une erreur locale au formulaire, pas un changement de
/// l'état d'authentification global (qui reste `unauthenticated`). Seuls
/// [LoginSuccess] et [LoginUnsupportedRole] correspondent à un changement de
/// `AuthState` (géré par `AuthRepository` elle-même).
sealed class LoginResult {
  const LoginResult();
}

class LoginSuccess extends LoginResult {
  const LoginSuccess(this.user);

  final AppUser user;
}

/// Couvre les deux cas 401 de `POST /auth/mobile/login` (identifiants
/// invalides, compte inactif/suspendu) : le backend renvoie déjà un
/// [message] différent et précis pour chacun (voir `AuthService.login`) —
/// pas besoin d'un second type pour les distinguer, juste de l'afficher.
class LoginInvalidCredentials extends LoginResult {
  const LoginInvalidCredentials(this.message);

  final String message;
}

/// 403 avec `{ isVerified: false }` : le compte existe et le mot de passe
/// est correct, mais l'email n'a pas encore été vérifié par OTP. Porte
/// l'email pour permettre à l'UI d'enchaîner directement sur la saisie du
/// code (`AuthRepository.verifyEmail`).
class LoginEmailNotVerified extends LoginResult {
  const LoginEmailNotVerified(this.email);

  final String email;
}

/// Identifiants valides mais rôle non autorisé en v1 (voir
/// `AuthRepository._isRoleAllowed`). Le token a déjà été révoqué côté
/// serveur et n'a jamais été enregistré localement.
class LoginUnsupportedRole extends LoginResult {
  const LoginUnsupportedRole();
}

/// Tout le reste (429, réseau, timeout, 5xx, validation...) : [message] est
/// déjà le message localisé d'`ApiException`, [type] est fourni en plus
/// pour qu'un écran puisse adapter son affichage (ex. bouton "réessayer"
/// pour `network`/`timeout`) sans reparser le message.
class LoginFailure extends LoginResult {
  const LoginFailure(this.message, this.type);

  final String message;
  final ApiExceptionType type;
}

/// Résultat de `AuthRepository.verifyEmail`.
sealed class VerifyEmailResult {
  const VerifyEmailResult();
}

class VerifyEmailSuccess extends VerifyEmailResult {
  const VerifyEmailSuccess(this.user);

  final AppUser user;
}

/// Échec de `POST /auth/verify-email` elle-même (code incorrect/expiré,
/// email déjà vérifié, utilisateur introuvable, réseau...).
class VerifyEmailFailure extends VerifyEmailResult {
  const VerifyEmailFailure(this.message, this.type);

  final String message;
  final ApiExceptionType type;
}

/// `POST /auth/verify-email` a réussi, mais le `POST /auth/mobile/login`
/// qui suit immédiatement (pour obtenir des tokens du canal mobile) a
/// échoué (ex. coupure réseau entre les deux appels). Porte le
/// [LoginResult] du second appel pour ne pas dupliquer sa logique
/// d'affichage.
class VerifyEmailLoginFailed extends VerifyEmailResult {
  const VerifyEmailLoginFailed(this.loginResult);

  final LoginResult loginResult;
}

/// Résultat de `AuthRepository.resendOtp`.
sealed class ResendOtpResult {
  const ResendOtpResult();
}

class ResendOtpSuccess extends ResendOtpResult {
  const ResendOtpSuccess();
}

class ResendOtpFailure extends ResendOtpResult {
  const ResendOtpFailure(this.message, this.type);

  final String message;
  final ApiExceptionType type;
}

/// Résultat de `AuthRepository.register`.
///
/// Ne recouvre jamais `AuthState` : l'inscription ne connecte pas
/// automatiquement (le compte créé est `is_verified: false` tant que l'OTP
/// n'a pas été validé via `verifyEmail`).
sealed class RegisterResult {
  const RegisterResult();
}

class RegisterSuccess extends RegisterResult {
  const RegisterSuccess();
}

/// 409 : email déjà utilisé par un autre compte (`AuthService.register`).
class RegisterEmailTaken extends RegisterResult {
  const RegisterEmailTaken(this.message);

  final String message;
}

/// 400 : validation refusée côté serveur (champ manquant, mot de passe trop
/// faible, téléphone invalide...). [fieldErrors] n'est rempli que pour les
/// règles express-validator de la route elle-même (email/longueur du mot de
/// passe) ; les validations plus fines faites dans `AuthService.register`
/// (téléphone, complexité du mot de passe, champs requis) ne renvoient
/// qu'un [message] global, pas de champ précis.
class RegisterValidationFailed extends RegisterResult {
  const RegisterValidationFailed(this.message, this.fieldErrors);

  final String message;
  final Map<String, String> fieldErrors;
}

class RegisterFailure extends RegisterResult {
  const RegisterFailure(this.message, this.type);

  final String message;
  final ApiExceptionType type;
}
