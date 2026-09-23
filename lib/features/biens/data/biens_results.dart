import '../../../core/network/api_exception.dart';
import '../models/immeuble.dart';
import '../models/lot.dart';

sealed class ImmeublesListResult {
  const ImmeublesListResult();
}

class ImmeublesListSuccess extends ImmeublesListResult {
  const ImmeublesListSuccess(this.items);
  final List<Immeuble> items;
}

class ImmeublesListFailure extends ImmeublesListResult {
  const ImmeublesListFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class LotsListResult {
  const LotsListResult();
}

class LotsListSuccess extends LotsListResult {
  const LotsListSuccess(this.items);
  final List<Lot> items;
}

class LotsListFailure extends LotsListResult {
  const LotsListFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class CreateImmeubleResult {
  const CreateImmeubleResult();
}

class CreateImmeubleSuccess extends CreateImmeubleResult {
  const CreateImmeubleSuccess(this.id);
  final int id;
}

class CreateImmeubleValidationFailed extends CreateImmeubleResult {
  const CreateImmeubleValidationFailed(this.message, this.fieldErrors);
  final String message;
  final Map<String, String> fieldErrors;
}

class CreateImmeubleFailure extends CreateImmeubleResult {
  const CreateImmeubleFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class CreateLotResult {
  const CreateLotResult();
}

class CreateLotSuccess extends CreateLotResult {
  const CreateLotSuccess(this.id);
  final int id;
}

class CreateLotValidationFailed extends CreateLotResult {
  const CreateLotValidationFailed(this.message, this.fieldErrors);
  final String message;
  final Map<String, String> fieldErrors;
}

/// Immeuble introuvable/non autorisé (400, voir `POST /api/biens/lots` —
/// `targetBuildingId` non résolu) ou limite du plan d'abonnement atteinte
/// (403, `checkPropertyLimit` — [ApiExceptionType.forbidden], message déjà
/// exploitable directement, pas de variante dédiée nécessaire).
class CreateLotFailure extends CreateLotResult {
  const CreateLotFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class DeleteImmeubleResult {
  const DeleteImmeubleResult();
}

class DeleteImmeubleSuccess extends DeleteImmeubleResult {
  const DeleteImmeubleSuccess();
}

/// 409 : des lots sont encore rattachés à cet immeuble (voir
/// `DELETE /api/biens/immeubles/:id`) — doivent être supprimés d'abord.
class DeleteImmeubleHasLots extends DeleteImmeubleResult {
  const DeleteImmeubleHasLots(this.message);
  final String message;
}

class DeleteImmeubleFailure extends DeleteImmeubleResult {
  const DeleteImmeubleFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class DeleteLotResult {
  const DeleteLotResult();
}

class DeleteLotSuccess extends DeleteLotResult {
  const DeleteLotSuccess();
}

class DeleteLotFailure extends DeleteLotResult {
  const DeleteLotFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}
