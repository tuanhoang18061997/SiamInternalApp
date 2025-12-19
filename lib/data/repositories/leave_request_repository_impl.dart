import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/repositories/leave_request_repository.dart';
import '../datasources/mock_api_datasource.dart';

class LeaveRequestRepositoryImpl implements LeaveRequestRepository {
  final MockApiDataSource _dataSource;

  LeaveRequestRepositoryImpl(this._dataSource);

  @override
  Future<List<LeaveRequest>> getLeaveRequests() async {
    final models = await _dataSource.getLeaveRequests();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<LeaveRequest> getLeaveRequestById(String id) async {
    final model = await _dataSource.getLeaveRequestById(id);
    return model.toEntity();
  }

  @override
  Future<LeaveRequest> createLeaveRequest({
    required String employeeId,
    required String employeeName,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final model = await _dataSource.createLeaveRequest(
      employeeId: employeeId,
      employeeName: employeeName,
      leaveType: leaveType,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
    );
    return model.toEntity();
  }

  @override
  Future<LeaveRequest> approveLeaveRequest(String id, String approvedBy) async {
    final model = await _dataSource.approveLeaveRequest(id, approvedBy);
    return model.toEntity();
  }

  @override
  Future<LeaveRequest> rejectLeaveRequest(
    String id,
    String rejectedBy,
    String reason,
  ) async {
    final model = await _dataSource.rejectLeaveRequest(id, rejectedBy, reason);
    return model.toEntity();
  }
}

final leaveRequestRepositoryProvider = Provider<LeaveRequestRepository>((ref) {
  return LeaveRequestRepositoryImpl(ref.watch(mockApiDataSourceProvider));
});
