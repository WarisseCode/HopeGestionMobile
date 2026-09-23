import '../../../core/network/api_exception.dart';
import '../models/locataire.dart';
import '../models/owner.dart';

sealed class LocatairesListResult {
  const LocatairesListResult();
}

class LocatairesListSuccess extends LocatairesListResult {
  const LocatairesListSuccess(this.items);
  final List<Locataire> items;
}

class LocatairesListFailure extends LocatairesListResult {
  const LocatairesListFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class LocataireDetailResult {
  const LocataireDetailResult();
}

class LocataireDetailSuccess extends LocataireDetailResult {
  const LocataireDetailSuccess(this.locataire, this.baux, this.paiements);
  final Locataire locataire;
  final List<TenantLease> baux;
  final List<TenantPayment> paiements;
}

class LocataireDetailFailure extends LocataireDetailResult {
  const LocataireDetailFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class CreateLocataireResult {
  const CreateLocataireResult();
}

class CreateLocataireSuccess extends CreateLocataireResult {
  const CreateLocataireSuccess(this.id);
  final int id;
}

class CreateLocataireValidationFailed extends CreateLocataireResult {
  const CreateLocataireValidationFailed(this.message, this.fieldErrors);
  final String message;
  final Map<String, String> fieldErrors;
}

/// 409 : téléphone ou email déjà utilisé pour un autre locataire du même
/// propriétaire (voir `locataireRoutes.ts`, `POST /`).
class CreateLocataireDuplicate extends CreateLocataireResult {
  const CreateLocataireDuplicate(this.message);
  final String message;
}

class CreateLocataireFailure extends CreateLocataireResult {
  const CreateLocataireFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class UpdateLocataireResult {
  const UpdateLocataireResult();
}

class UpdateLocataireSuccess extends UpdateLocataireResult {
  const UpdateLocataireSuccess();
}

class UpdateLocataireValidationFailed extends UpdateLocataireResult {
  const UpdateLocataireValidationFailed(this.message, this.fieldErrors);
  final String message;
  final Map<String, String> fieldErrors;
}

class UpdateLocataireFailure extends UpdateLocataireResult {
  const UpdateLocataireFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class DeleteLocataireResult {
  const DeleteLocataireResult();
}

class DeleteLocataireSuccess extends DeleteLocataireResult {
  const DeleteLocataireSuccess();
}

class DeleteLocataireFailure extends DeleteLocataireResult {
  const DeleteLocataireFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class OwnersListResult {
  const OwnersListResult();
}

class OwnersListSuccess extends OwnersListResult {
  const OwnersListSuccess(this.owners);
  final List<Owner> owners;
}

class OwnersListFailure extends OwnersListResult {
  const OwnersListFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}
