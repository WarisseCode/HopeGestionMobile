import '../../../core/network/api_exception.dart';
import '../models/alerte.dart';

sealed class AlertesListResult {
  const AlertesListResult();
}

class AlertesListSuccess extends AlertesListResult {
  const AlertesListSuccess(this.alertes, this.dismissedCount);
  final List<Alerte> alertes;

  /// Nombre d'alertes ignorées par l'utilisateur (`dismissedCount`).
  final int dismissedCount;
}

class AlertesListFailure extends AlertesListResult {
  const AlertesListFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class DismissAlerteResult {
  const DismissAlerteResult();
}

class DismissAlerteSuccess extends DismissAlerteResult {
  const DismissAlerteSuccess();
}

class DismissAlerteFailure extends DismissAlerteResult {
  const DismissAlerteFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}
