import '../../../core/network/api_exception.dart';
import '../models/document.dart';

sealed class DocumentsListResult {
  const DocumentsListResult();
}

class DocumentsListSuccess extends DocumentsListResult {
  const DocumentsListSuccess(this.items);
  final List<Document> items;
}

class DocumentsListFailure extends DocumentsListResult {
  const DocumentsListFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}

sealed class QuittancesManuellesResult {
  const QuittancesManuellesResult();
}

class QuittancesManuellesSuccess extends QuittancesManuellesResult {
  const QuittancesManuellesSuccess(this.items);
  final List<QuittanceManuelle> items;
}

class QuittancesManuellesFailure extends QuittancesManuellesResult {
  const QuittancesManuellesFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}
