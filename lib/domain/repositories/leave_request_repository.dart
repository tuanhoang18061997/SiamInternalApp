import '../../domain/entities/leave_request.dart';

abstract class LeaveRequestRepository {
  Future<List<LeaveRequest>> getLeaveRequests();
  Future<LeaveRequest> getLeaveRequestById(String id);
  Future<LeaveRequest> createLeaveRequest({
    required String employeeId,
    required String employeeName,
    required String leaveType,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  });
  Future<LeaveRequest> approveLeaveRequest(String id, String approvedBy);
  Future<LeaveRequest> rejectLeaveRequest(String id, String rejectedBy, String reason);
}
