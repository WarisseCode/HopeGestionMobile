import '../../../core/network/api_exception.dart';
import '../models/dashboard_data.dart';

sealed class DashboardResult {
  const DashboardResult();
}

class DashboardLoadSuccess extends DashboardResult {
  const DashboardLoadSuccess(this.data);
  final DashboardData data;
}

class DashboardLoadFailure extends DashboardResult {
  const DashboardLoadFailure(this.message, this.type);
  final String message;
  final ApiExceptionType type;
}
