import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/leave_request.dart';
import '../../data/repositories/leave_request_repository_impl.dart';

final leaveRequestsProvider = FutureProvider<List<LeaveRequest>>((ref) async {
  final repository = ref.watch(leaveRequestRepositoryProvider);
  return repository.getLeaveRequests();
});

final leaveRequestDetailProvider = FutureProvider.family<LeaveRequest, String>((ref, id) async {
  final repository = ref.watch(leaveRequestRepositoryProvider);
  return repository.getLeaveRequestById(id);
});

class LeaveRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final LeaveRequestRepositoryImpl _repository;

  LeaveRequestNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<void> createLeaveRequest({
    required String employeeId,
    required String employeeName,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createLeaveRequest(
        employeeId: employeeId,
        employeeName: employeeName,
        leaveType: leaveType,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> approveLeaveRequest(String id, String approvedBy) async {
    state = const AsyncValue.loading();
    try {
      await _repository.approveLeaveRequest(id, approvedBy);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> rejectLeaveRequest(String id, String rejectedBy, String reason) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectLeaveRequest(id, rejectedBy, reason);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final leaveRequestNotifierProvider = StateNotifierProvider<LeaveRequestNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(leaveRequestRepositoryProvider);
  return LeaveRequestNotifier(repository as LeaveRequestRepositoryImpl);
});
